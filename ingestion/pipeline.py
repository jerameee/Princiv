"""
Pipeline: orchestrates document loading -> entity extraction -> ontology
validation -> Neo4j batch insertion.

Usage::

    import neo4j
    from ingestion.loaders.neo4j_loader import Neo4jGraphStore
    from ingestion.pipeline import Pipeline
    from layers.ingestion import Document

    driver = neo4j.AsyncGraphDatabase.driver(uri, auth=(user, password))
    store  = Neo4jGraphStore(driver)
    pipeline = Pipeline(store=store, ontology_path="ontology/ssa_domain.ttl")

    result = asyncio.run(pipeline.run(documents))
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from pathlib import Path

from layers.ingestion import Document
from layers.storage import GraphNode, GraphRelationship

from .extractors.relation_extractor import RelationExtractor
from .extractors.ssa_gliner_extractor import SSAGLiNERExtractor
from .loaders.neo4j_loader import Neo4jGraphStore
from .validators.ontology_gate import OntologyGate, ValidationMetrics

logger = logging.getLogger(__name__)


@dataclass
class PipelineResult:
    documents_processed: int = 0
    entities_extracted: int = 0
    relationships_extracted: int = 0
    validation: ValidationMetrics = field(default_factory=ValidationMetrics)
    nodes_written: int = 0
    relationships_written: int = 0


class Pipeline:
    """
    End-to-end SSA ingestion pipeline.

    Parameters
    ----------
    store:
        Open Neo4jGraphStore instance.
    ontology_path:
        Path to ontology/ssa_domain.ttl used by the OntologyGate.
    gliner_model:
        GLiNER checkpoint name or path.
    gliner_threshold:
        Confidence threshold for NER span acceptance (0.0-1.0).
    """

    def __init__(
        self,
        store: Neo4jGraphStore,
        ontology_path: str | Path,
        gliner_model: str = "urchade/gliner_medium-v2.1",
        gliner_threshold: float = 0.5,
    ) -> None:
        self._extractor = SSAGLiNERExtractor(
            model_name=gliner_model, threshold=gliner_threshold
        )
        self._relation_extractor = RelationExtractor()
        self._gate = OntologyGate(ontology_path)
        self._store = store

    async def run(self, documents: list[Document]) -> PipelineResult:
        aggregate = PipelineResult(documents_processed=len(documents))

        for doc in documents:
            extraction = await self._extractor.extract_async(doc)
            relations = self._relation_extractor.extract_relations(extraction)
            extraction.relationships = relations

            aggregate.entities_extracted += len(extraction.entities)
            aggregate.relationships_extracted += len(extraction.relationships)

            validation = self._gate.validate(extraction)
            aggregate.validation.accepted_count += validation.metrics.accepted_count
            aggregate.validation.rejected_count += validation.metrics.rejected_count
            aggregate.validation.rejection_reasons.update(
                validation.metrics.rejection_reasons
            )

            if validation.rejected:
                logger.warning(
                    "Gate rejected %d triples from '%s': %s",
                    len(validation.rejected),
                    doc.metadata.get("source", "unknown"),
                    dict(validation.metrics.rejection_reasons),
                )

            nodes = _entities_to_nodes(extraction)
            rels = _relationships_to_graph_rels(extraction, validation.accepted)

            batch = await self._store.upsert_batch(nodes, rels)
            aggregate.nodes_written += batch.nodes_created + batch.nodes_merged
            aggregate.relationships_written += (
                batch.relationships_created + batch.relationships_merged
            )

        return aggregate


def _entities_to_nodes(extraction) -> list[GraphNode]:
    seen: set[str] = set()
    nodes: list[GraphNode] = []
    for entity in extraction.entities:
        node_id = entity.properties.get("id", "")
        if not node_id or node_id in seen:
            continue
        seen.add(node_id)
        props = {k: v for k, v in entity.properties.items() if k != "id"}
        nodes.append(GraphNode(label=entity.entity_type.value, id=node_id, properties=props))
    return nodes


def _relationships_to_graph_rels(extraction, accepted) -> list[GraphRelationship]:
    entity_map = {
        e.properties["id"]: e
        for e in extraction.entities
        if "id" in e.properties
    }
    rels: list[GraphRelationship] = []
    for rel in accepted:
        src = entity_map.get(rel.source_ref)
        tgt = entity_map.get(rel.target_ref)
        if src is None or tgt is None:
            continue
        rels.append(
            GraphRelationship(
                relationship_type=rel.relationship_type.value,
                source_id=rel.source_ref,
                source_label=src.entity_type.value,
                target_id=rel.target_ref,
                target_label=tgt.entity_type.value,
                properties=rel.properties,
            )
        )
    return rels
