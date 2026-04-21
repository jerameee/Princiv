"""
Ontology gate: validates (subject, predicate, object) triples against the
OWL 2.0 axioms in ontology/ssa_domain.ttl before Neo4j insertion.

Checks performed per triple:
  1. Predicate is a declared owl:ObjectProperty (or a known graph-schema edge).
  2. Subject entity type is a declared owl:Class.
  3. Object entity type is a declared owl:Class.
  4. Subject type satisfies the property's rdfs:domain (incl. subclasses/equivalents).
  5. Object type satisfies the property's rdfs:range  (incl. subclasses/equivalents).
"""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

from rdflib import OWL, RDF, RDFS, BNode, Graph, URIRef
from rdflib.collection import Collection

from layers.ingestion import ExtractionResult, ExtractedRelationship


@dataclass
class RejectedTriple:
    relationship: ExtractedRelationship
    reason: str


@dataclass
class ValidationMetrics:
    accepted_count: int = 0
    rejected_count: int = 0
    rejection_reasons: Counter = field(default_factory=Counter)


@dataclass
class ValidationResult:
    accepted: list[ExtractedRelationship]
    rejected: list[RejectedTriple]
    metrics: ValidationMetrics


# Graph-schema predicates that are not OWL object properties.
# The gate allows these through without domain/range checks.
_GRAPH_SCHEMA_PREDICATES: frozenset[str] = frozenset({
    "CITES",
    "ADDRESSES",
    "DECIDED_BY",
    "SUBCONCEPT_OF",
})

_SSA_NS = "http://ssa.gov/disability/ontology#"


def _enum_to_owl_local(predicate_value: str) -> str:
    """Convert SCREAMING_SNAKE_CASE enum value to camelCase OWL local name."""
    parts = predicate_value.lower().split("_")
    return parts[0] + "".join(p.capitalize() for p in parts[1:])


class OntologyGate:
    """
    Validates triples against the OWL ontology before Neo4j insertion.

    The graph is loaded once at init; per-triple cost is O(1) dict lookups.
    """

    def __init__(self, ontology_path: str | Path) -> None:
        self._g = Graph()
        self._g.parse(str(ontology_path), format="turtle")
        self._classes = self._load_classes()
        self._owl_properties = self._load_owl_properties()
        self._domains = self._load_axiom_map(RDFS.domain)
        self._ranges = self._load_axiom_map(RDFS.range)

    # ------------------------------------------------------------------
    # Index construction
    # ------------------------------------------------------------------

    def _load_classes(self) -> set[str]:
        return {
            _local_name(s)
            for s in self._g.subjects(RDF.type, OWL.Class)
            if isinstance(s, URIRef)
        }

    def _load_owl_properties(self) -> set[str]:
        return {
            _local_name(s)
            for s in self._g.subjects(RDF.type, OWL.ObjectProperty)
            if isinstance(s, URIRef)
        }

    def _load_axiom_map(self, predicate) -> dict[str, set[str]]:
        """Build property_local_name -> set[class_local_name] from domain or range axioms."""
        result: dict[str, set[str]] = {}
        for prop, _, value_node in self._g.triples((None, predicate, None)):
            if not isinstance(prop, URIRef):
                continue
            key = _local_name(prop)
            result.setdefault(key, set()).update(self._resolve_class_node(value_node))
        return result

    def _resolve_class_node(self, node) -> set[str]:
        """Resolve a named class URI or an owl:unionOf blank node to a set of local names."""
        if isinstance(node, URIRef):
            return {_local_name(node)}
        if isinstance(node, BNode):
            union_list = self._g.value(node, OWL.unionOf)
            if union_list is not None:
                result: set[str] = set()
                for member in Collection(self._g, union_list):
                    result.update(self._resolve_class_node(member))
                return result
        return set()

    # ------------------------------------------------------------------
    # Validation
    # ------------------------------------------------------------------

    def validate(self, result: ExtractionResult) -> ValidationResult:
        entity_type_map: dict[str, str] = {
            e.properties["id"]: e.entity_type.value
            for e in result.entities
            if "id" in e.properties
        }

        accepted: list[ExtractedRelationship] = []
        rejected: list[RejectedTriple] = []

        for rel in result.relationships:
            reason = self._check(rel, entity_type_map)
            if reason is None:
                accepted.append(rel)
            else:
                rejected.append(RejectedTriple(relationship=rel, reason=reason))

        metrics = ValidationMetrics(
            accepted_count=len(accepted),
            rejected_count=len(rejected),
            rejection_reasons=Counter(r.reason for r in rejected),
        )
        return ValidationResult(accepted=accepted, rejected=rejected, metrics=metrics)

    def _check(
        self,
        rel: ExtractedRelationship,
        entity_type_map: dict[str, str],
    ) -> str | None:
        pred_value = rel.relationship_type.value

        # Graph-schema predicates skip OWL checks
        if pred_value in _GRAPH_SCHEMA_PREDICATES:
            return None

        owl_pred = _enum_to_owl_local(pred_value)
        if owl_pred not in self._owl_properties:
            return f"undeclared_predicate:{pred_value}"

        subj_type = entity_type_map.get(rel.source_ref)
        obj_type = entity_type_map.get(rel.target_ref)

        if subj_type and subj_type not in self._classes:
            return f"invalid_subject_type:{subj_type}"
        if obj_type and obj_type not in self._classes:
            return f"invalid_object_type:{obj_type}"

        if owl_pred in self._domains and subj_type:
            expanded = {subj_type} | self._superclasses_and_equivalents(subj_type)
            if not self._domains[owl_pred].intersection(expanded):
                return f"domain_violation:{subj_type}_not_in_domain_of_{owl_pred}"

        if owl_pred in self._ranges and obj_type:
            expanded = {obj_type} | self._superclasses_and_equivalents(obj_type)
            if not self._ranges[owl_pred].intersection(expanded):
                return f"range_violation:{obj_type}_not_in_range_of_{owl_pred}"

        return None

    def _superclasses_and_equivalents(self, class_name: str) -> set[str]:
        """Return superclasses and equivalent classes for a named SSA ontology class."""
        uri = URIRef(f"{_SSA_NS}{class_name}")
        result: set[str] = set()
        for parent in self._g.objects(uri, RDFS.subClassOf):
            if isinstance(parent, URIRef):
                result.add(_local_name(parent))
        for eq in self._g.objects(uri, OWL.equivalentClass):
            if isinstance(eq, URIRef):
                result.add(_local_name(eq))
        for eq in self._g.subjects(OWL.equivalentClass, uri):
            if isinstance(eq, URIRef):
                result.add(_local_name(eq))
        return result


def _local_name(uri: URIRef) -> str:
    s = str(uri)
    return s.split("#")[-1] if "#" in s else s.split("/")[-1]
