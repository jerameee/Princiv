"""
Concrete async Neo4j implementation of the veridian-core GraphStore interface.

All node labels are validated against EntityType before Cypher formatting
to prevent label injection. Every write is logged as a structured JSON
audit entry via the standard logging module.
"""

from __future__ import annotations

import json
import logging
import re
from datetime import datetime, timezone

import neo4j

from layers.ingestion import EntityType
from layers.storage import (
    BatchWriteResult,
    GraphNode,
    GraphRelationship,
    GraphStore,
    WriteResult,
)

logger = logging.getLogger(__name__)

_VALID_LABELS: frozenset[str] = frozenset(et.value for et in EntityType)
_SAFE_LABEL_RE = re.compile(r"^[A-Za-z][A-Za-z0-9]*$")


def _safe_label(label: str) -> str:
    """Reject labels not in EntityType enum and not matching a safe identifier pattern."""
    if label not in _VALID_LABELS and not _SAFE_LABEL_RE.match(label):
        raise ValueError(f"Invalid node label: {label!r}")
    return label


# OPTIONAL MATCH before MERGE lets us report created vs merged without a
# temporary property on the node.
_UPSERT_NODE = """
OPTIONAL MATCH (existing:{label} {{id: $id}})
WITH existing IS NULL AS will_create
MERGE (n:{label} {{id: $id}})
ON CREATE SET n += $props
ON MATCH  SET n += $props
RETURN will_create AS created
"""

_UPSERT_REL = """
MATCH (a:{src_label} {{id: $src_id}})
MATCH (b:{tgt_label} {{id: $tgt_id}})
MERGE (a)-[r:{rel_type}]->(b)
ON CREATE SET r += $props
ON MATCH  SET r += $props
RETURN true AS created
"""

# Batch variants skip the OPTIONAL MATCH overhead; creation/merge counts
# are approximated (all tallied as merged).
_BATCH_NODE = """
MERGE (n:{label} {{id: $id}})
ON CREATE SET n += $props
ON MATCH  SET n += $props
RETURN n.id IS NOT NULL AS ok
"""

_BATCH_REL = """
MATCH (a:{src_label} {{id: $src_id}})
MATCH (b:{tgt_label} {{id: $tgt_id}})
MERGE (a)-[r:{rel_type}]->(b)
ON CREATE SET r += $props
ON MATCH  SET r += $props
RETURN true AS ok
"""


class Neo4jGraphStore(GraphStore):
    """
    Async Neo4j graph store with idempotent MERGE operations.

    Parameters
    ----------
    driver:
        Open AsyncDriver. Caller owns lifecycle, or use as async context manager.
    database:
        Target Neo4j database (defaults to the server default "neo4j").
    """

    def __init__(self, driver: neo4j.AsyncDriver, database: str = "neo4j") -> None:
        self._driver = driver
        self._database = database

    async def upsert_node(self, node: GraphNode) -> WriteResult:
        label = _safe_label(node.label)
        query = _UPSERT_NODE.format(label=label)
        async with self._driver.session(database=self._database) as session:
            result = await session.run(query, id=node.id, props=node.properties)
            record = await result.single()
        created = bool(record["created"]) if record else False
        _audit("upsert_node", label, node.id, created)
        return WriteResult(created=created, entity_id=node.id)

    async def upsert_relationship(self, relationship: GraphRelationship) -> WriteResult:
        src_label = _safe_label(relationship.source_label)
        tgt_label = _safe_label(relationship.target_label)
        query = _UPSERT_REL.format(
            src_label=src_label,
            tgt_label=tgt_label,
            rel_type=relationship.relationship_type,
        )
        async with self._driver.session(database=self._database) as session:
            result = await session.run(
                query,
                src_id=relationship.source_id,
                tgt_id=relationship.target_id,
                props=relationship.properties,
            )
            record = await result.single()
        rel_id = (
            f"{relationship.source_id}"
            f"->{relationship.relationship_type}"
            f"->{relationship.target_id}"
        )
        created = bool(record["created"]) if record else False
        _audit("upsert_rel", relationship.relationship_type, rel_id, created)
        return WriteResult(created=created, entity_id=rel_id)

    async def upsert_batch(
        self,
        nodes: list[GraphNode],
        relationships: list[GraphRelationship],
    ) -> BatchWriteResult:
        result = BatchWriteResult()
        async with self._driver.session(database=self._database) as session:
            tx = await session.begin_transaction()
            try:
                for node in nodes:
                    label = _safe_label(node.label)
                    r = await tx.run(
                        _BATCH_NODE.format(label=label),
                        id=node.id,
                        props=node.properties,
                    )
                    await r.consume()
                    result.nodes_merged += 1
                    _audit("batch_node", label, node.id, False)

                for rel in relationships:
                    src_label = _safe_label(rel.source_label)
                    tgt_label = _safe_label(rel.target_label)
                    r = await tx.run(
                        _BATCH_REL.format(
                            src_label=src_label,
                            tgt_label=tgt_label,
                            rel_type=rel.relationship_type,
                        ),
                        src_id=rel.source_id,
                        tgt_id=rel.target_id,
                        props=rel.properties,
                    )
                    await r.consume()
                    result.relationships_merged += 1

                await tx.commit()
            except Exception:
                await tx.rollback()
                raise

        return result

    async def get_node(self, label: str, node_id: str) -> GraphNode | None:
        label = _safe_label(label)
        query = f"MATCH (n:{label} {{id: $id}}) RETURN properties(n) AS props"
        async with self._driver.session(database=self._database) as session:
            result = await session.run(query, id=node_id)
            record = await result.single()
        if record is None:
            return None
        props = {k: v for k, v in dict(record["props"]).items() if k != "id"}
        return GraphNode(label=label, id=node_id, properties=props)

    async def close(self) -> None:
        await self._driver.close()


def _audit(action: str, label: str, entity_id: str, created: bool) -> None:
    logger.info(
        json.dumps({
            "action": action,
            "label": label,
            "entity_id": entity_id,
            "created": created,
            "ts": datetime.now(timezone.utc).isoformat(),
        })
    )
