"""
Tests for the Princiv ingestion pipeline (Task 1.7).

Acceptance criteria covered:
  - OntologyGate rejects 100% of triples with invalid types or predicates  [unit]
  - All nodes written to the store carry a valid EntityType label           [unit]
  - Gate-rejected triples never reach the store                            [unit]
  - Entity extraction recall > 90% on 20-document test set                 [integration]
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import pytest

REPO_ROOT = Path(__file__).parents[2]
ONTOLOGY_PATH = REPO_ROOT / "ontology" / "ssa_domain.ttl"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _gliner_available() -> bool:
    try:
        import gliner  # noqa: F401
        return True
    except Exception:
        return False


def _spacy_available() -> bool:
    try:
        import spacy  # noqa: F401
        return True
    except ImportError:
        return False


# ---------------------------------------------------------------------------
# 20-document test fixtures (ground truth for recall measurement)
# Each entry: (document_text, {label_string: [mention_strings]})
# label_string matches SSA NER prompt labels used by GLiNER.
# ---------------------------------------------------------------------------

_TEST_DOCUMENTS: list[tuple[str, dict[str, list[str]]]] = [
    (
        "The claimant alleges disability due to degenerative disc disease beginning March 2022.",
        {"Medical Condition": [
            "degenerative disc disease"], "Claimant": ["claimant"]},
    ),
    (
        "At Step 1, the ALJ found the claimant was not engaged in substantial gainful activity.",
        {"Evaluation Step": ["Step 1"], "Claimant": ["claimant"]},
    ),
    (
        "The impairment must be severe and meet the 12-month duration requirement under 20 C.F.R. \u00a7 404.1509.",
        {"Regulation": ["20 C.F.R."]},
    ),
    (
        "The claimant's RFC limits him to sedentary work due to chronic back pain and lumbar radiculopathy.",
        {"RFC Component": ["RFC"], "Claimant": ["claimant"],
            "Medical Condition": ["back pain"]},
    ),
    (
        "Listing 1.15 requires nerve root compression with documented motor loss and sensory deficits.",
        {"Listing of Impairments": ["Listing 1.15"],
            "Functional Limitation": ["motor loss"]},
    ),
    (
        "Grid Rule 201.06 directs a finding of disabled for a claimant of advanced age with limited education.",
        {"Grid Rule": ["Grid Rule 201.06"], "Claimant": ["claimant"]},
    ),
    (
        "SSR 96-8p governs the assessment of residual functional capacity in administrative hearings.",
        {"Social Security Ruling": ["SSR 96-8p"]},
    ),
    (
        "At Step 4, the ALJ determined the claimant cannot return to past relevant work as a truck driver.",
        {"Evaluation Step": ["Step 4"], "Claimant": [
            "claimant"], "Occupation": ["truck driver"]},
    ),
    (
        "The vocational expert testified that sedentary jobs exist in significant numbers in the national economy.",
        {"Occupation": ["sedentary jobs"]},
    ),
    (
        "The claimant's lifting limitation prevents her from performing medium or light exertional work.",
        {"Functional Limitation": [
            "lifting limitation"], "Claimant": ["claimant"]},
    ),
    (
        "The treating physician's opinion was given little weight as it was inconsistent with objective findings.",
        {},
    ),
    (
        "The claimant meets Listing 12.04 for depressive disorder based on marked limitations in concentration.",
        {"Listing of Impairments": ["Listing 12.04"], "Claimant": [
            "claimant"], "Medical Condition": ["depressive disorder"]},
    ),
    (
        "Under 42 U.S.C. \u00a7 423(d), a claimant must be unable to engage in any substantial gainful activity.",
        {"Statute": ["42 U.S.C."], "Claimant": ["claimant"]},
    ),
    (
        "The RFC assessment restricts the claimant to occasional overhead reaching due to rotator cuff tear.",
        {"RFC Component": ["RFC"], "Claimant": ["claimant"],
            "Medical Condition": ["rotator cuff tear"]},
    ),
    (
        "At Step 5, the burden shifts to the Commissioner to show that other work exists in significant numbers.",
        {"Evaluation Step": ["Step 5"]},
    ),
    (
        "The ALJ failed to evaluate the claimant's fibromyalgia under SSR 12-2p.",
        {"Medical Condition": ["fibromyalgia"],
            "Social Security Ruling": ["SSR 12-2p"]},
    ),
    (
        "The claimant's date last insured was December 31, 2020; onset was alleged prior to that date.",
        {"Claimant": ["claimant"]},
    ),
    (
        "Bowman v. Social Security Administration held that the ALJ must articulate how the evidence was weighed.",
        {"Court Case": ["Bowman v. Social Security Administration"]},
    ),
    (
        "The Grid rules at 20 C.F.R. Part 404, Subpart P, Appendix 2 provide for a finding of disabled.",
        {"Grid Rule": ["Grid rules"], "Regulation": ["20 C.F.R."]},
    ),
    (
        "A severe impairment at Step 2 requires more than a minimal effect on the claimant's ability to work.",
        {"Evaluation Step": ["Step 2"], "Claimant": ["claimant"]},
    ),
]


# ---------------------------------------------------------------------------
# Ontology gate unit tests (no external dependencies)
# ---------------------------------------------------------------------------

class TestOntologyGate:

    @pytest.fixture(scope="class")
    def gate(self):
        from ingestion.validators.ontology_gate import OntologyGate
        return OntologyGate(ONTOLOGY_PATH)

    def test_loads_ssa_classes(self, gate):
        for cls in ("MedicalCondition", "Listing", "GridRule", "EvaluationStep",
                    "Claimant", "FunctionalLimitation", "RFCComponent", "SSR"):
            assert cls in gate._classes, f"Expected OWL class not found: {cls}"

    def test_loads_owl_properties(self, gate):
        for prop in ("resultsInLimitation", "mayMeetListing", "affectsRFCComponent",
                     "ifYesGoTo", "protectedBy", "requiresEvidence"):
            assert prop in gate._owl_properties, f"Expected OWL property not found: {prop}"

    def test_valid_triple_accepted(self, gate):
        from layers.ingestion import (
            Document, EntityType, ExtractionResult,
            ExtractedEntity, ExtractedRelationship, RelationshipType,
        )
        doc = Document(content="test", source_type="test")
        entities = [
            ExtractedEntity(entity_type=EntityType.MEDICAL_CONDITION,
                            properties={"id": "mc_ddd"}),
            ExtractedEntity(entity_type=EntityType.FUNCTIONAL_LIMITATION,
                            properties={"id": "fl_back"}),
        ]
        rel = ExtractedRelationship(
            relationship_type=RelationshipType.RESULTS_IN_LIMITATION,
            source_ref="mc_ddd", target_ref="fl_back",
        )
        extraction = ExtractionResult(
            extractor_id="test", document=doc, entities=entities, relationships=[rel]
        )
        result = gate.validate(extraction)
        assert result.metrics.accepted_count == 1
        assert result.metrics.rejected_count == 0

    def test_graph_schema_predicate_passes_without_owl_check(self, gate):
        from layers.ingestion import (
            Document, EntityType, ExtractionResult,
            ExtractedEntity, ExtractedRelationship, RelationshipType,
        )
        doc = Document(content="test", source_type="test")
        entities = [
            ExtractedEntity(entity_type=EntityType.CASE,
                            properties={"id": "case_1"}),
            ExtractedEntity(entity_type=EntityType.LEGAL_CONCEPT,
                            properties={"id": "lc_1"}),
        ]
        rel = ExtractedRelationship(
            relationship_type=RelationshipType.ADDRESSES,
            source_ref="case_1", target_ref="lc_1",
        )
        extraction = ExtractionResult(
            extractor_id="test", document=doc, entities=entities, relationships=[rel]
        )
        result = gate.validate(extraction)
        assert result.metrics.accepted_count == 1
        assert result.metrics.rejected_count == 0

    def test_undeclared_predicate_rejected(self, gate):
        from layers.ingestion import Document, EntityType, ExtractionResult, ExtractedEntity
        doc = Document(content="test", source_type="test")
        entities = [
            ExtractedEntity(entity_type=EntityType.MEDICAL_CONDITION,
                            properties={"id": "mc_1"}),
            ExtractedEntity(entity_type=EntityType.LISTING,
                            properties={"id": "l_1"}),
        ]
        bad_rel = MagicMock()
        bad_rel.relationship_type.value = "COMPLETELY_INVENTED_PREDICATE"
        bad_rel.source_ref = "mc_1"
        bad_rel.target_ref = "l_1"
        extraction = ExtractionResult(
            extractor_id="test", document=doc, entities=entities, relationships=[bad_rel]
        )
        result = gate.validate(extraction)
        assert result.metrics.rejected_count == 1
        assert any(
            "undeclared_predicate" in r for r in result.metrics.rejection_reasons)

    def test_invalid_subject_type_rejected(self, gate):
        from layers.ingestion import Document, EntityType, ExtractionResult, ExtractedEntity
        doc = Document(content="test", source_type="test")
        bad_entity = MagicMock()
        bad_entity.properties = {"id": "bad_1"}
        bad_entity.entity_type.value = "TotallyFakeClass"
        good_entity = ExtractedEntity(
            entity_type=EntityType.FUNCTIONAL_LIMITATION, properties={
                "id": "fl_1"}
        )
        bad_rel = MagicMock()
        bad_rel.relationship_type.value = "RESULTS_IN_LIMITATION"
        bad_rel.source_ref = "bad_1"
        bad_rel.target_ref = "fl_1"
        extraction = ExtractionResult(
            extractor_id="test", document=doc,
            entities=[bad_entity, good_entity], relationships=[bad_rel]
        )
        result = gate.validate(extraction)
        assert result.metrics.rejected_count == 1
        assert any(
            "invalid_subject_type" in r for r in result.metrics.rejection_reasons)

    def test_domain_violation_rejected(self, gate):
        from layers.ingestion import (
            Document, EntityType, ExtractionResult, ExtractedEntity,
        )
        doc = Document(content="test", source_type="test")
        # resultsInLimitation domain is Impairment; Claimant is not in that hierarchy
        entities = [
            ExtractedEntity(entity_type=EntityType.CLAIMANT,
                            properties={"id": "cl_1"}),
            ExtractedEntity(
                entity_type=EntityType.FUNCTIONAL_LIMITATION, properties={"id": "fl_1"}),
        ]
        bad_rel = MagicMock()
        bad_rel.relationship_type.value = "RESULTS_IN_LIMITATION"
        bad_rel.source_ref = "cl_1"
        bad_rel.target_ref = "fl_1"
        extraction = ExtractionResult(
            extractor_id="test", document=doc, entities=entities, relationships=[bad_rel]
        )
        result = gate.validate(extraction)
        assert result.metrics.rejected_count == 1
        assert any(
            "domain_violation" in r for r in result.metrics.rejection_reasons)

    def test_range_violation_rejected(self, gate):
        from layers.ingestion import (
            Document, EntityType, ExtractionResult, ExtractedEntity,
        )
        doc = Document(content="test", source_type="test")
        # resultsInLimitation range is FunctionalLimitation; Listing is not in that hierarchy
        entities = [
            ExtractedEntity(
                entity_type=EntityType.MEDICAL_CONDITION, properties={"id": "mc_1"}),
            ExtractedEntity(entity_type=EntityType.LISTING,
                            properties={"id": "l_1"}),
        ]
        bad_rel = MagicMock()
        bad_rel.relationship_type.value = "RESULTS_IN_LIMITATION"
        bad_rel.source_ref = "mc_1"
        bad_rel.target_ref = "l_1"
        extraction = ExtractionResult(
            extractor_id="test", document=doc, entities=entities, relationships=[bad_rel]
        )
        result = gate.validate(extraction)
        assert result.metrics.rejected_count == 1
        assert any(
            "range_violation" in r for r in result.metrics.rejection_reasons)

    def test_100_percent_rejection_of_invalid_predicates(self, gate):
        """Gate must reject 100% of triples with undeclared predicates."""
        from layers.ingestion import Document, EntityType, ExtractionResult, ExtractedEntity
        doc = Document(content="test", source_type="test")
        bad_predicates = [
            "FAKE_PREDICATE_A", "DOES_NOT_EXIST",
            "INVENTED_RELATIONSHIP", "BAD_EDGE_TYPE", "NONSENSE_LINK",
        ]
        entities = [
            ExtractedEntity(
                entity_type=EntityType.MEDICAL_CONDITION,
                properties={"id": f"mc_{i}"}
            )
            for i in range(len(bad_predicates) * 2)
        ]
        relationships = []
        for i, pred in enumerate(bad_predicates):
            rel = MagicMock()
            rel.relationship_type.value = pred
            rel.source_ref = f"mc_{i * 2}"
            rel.target_ref = f"mc_{i * 2 + 1}"
            relationships.append(rel)
        extraction = ExtractionResult(
            extractor_id="test", document=doc,
            entities=entities, relationships=relationships
        )
        result = gate.validate(extraction)
        assert result.metrics.rejected_count == len(bad_predicates), (
            f"Expected all {len(bad_predicates)} invalid triples rejected, "
            f"got {result.metrics.rejected_count}"
        )
        assert result.metrics.accepted_count == 0


# ---------------------------------------------------------------------------
# Pipeline wiring unit tests (no external dependencies)
# ---------------------------------------------------------------------------

class TestPipelineWiring:

    def test_all_nodes_have_valid_entity_type_label(self):
        """_entities_to_nodes must never produce an untyped node."""
        from ingestion.pipeline import _entities_to_nodes
        from layers.ingestion import Document, EntityType, ExtractionResult, ExtractedEntity

        doc = Document(content="test", source_type="test")
        entities = [
            ExtractedEntity(
                entity_type=et,
                properties={"id": f"{et.value.lower()}_1", "text": et.value},
            )
            for et in EntityType
        ]
        extraction = ExtractionResult(
            extractor_id="test", document=doc, entities=entities)
        nodes = _entities_to_nodes(extraction)

        valid_labels = {et.value for et in EntityType}
        untyped = [n for n in nodes if n.label not in valid_labels]
        assert not untyped, f"Untyped nodes found: {untyped}"
        assert len(nodes) == len(EntityType)

    def test_rejected_triples_excluded_from_graph_relationships(self):
        """When the accepted list is empty, no GraphRelationships are produced."""
        from ingestion.pipeline import _relationships_to_graph_rels
        from layers.ingestion import (
            Document, EntityType, ExtractionResult,
            ExtractedEntity, ExtractedRelationship, RelationshipType,
        )
        doc = Document(content="test", source_type="test")
        entities = [
            ExtractedEntity(
                entity_type=EntityType.MEDICAL_CONDITION, properties={"id": "mc_1"}),
            ExtractedEntity(
                entity_type=EntityType.FUNCTIONAL_LIMITATION, properties={"id": "fl_1"}),
        ]
        extraction = ExtractionResult(
            extractor_id="test", document=doc, entities=entities,
            relationships=[
                ExtractedRelationship(
                    relationship_type=RelationshipType.RESULTS_IN_LIMITATION,
                    source_ref="mc_1", target_ref="fl_1",
                )
            ],
        )
        graph_rels = _relationships_to_graph_rels(extraction, accepted=[])
        assert graph_rels == [], "Gate-rejected triples must not reach the store"

    def test_duplicate_entity_ids_deduplicated(self):
        """_entities_to_nodes deduplicates on id, keeping the first occurrence."""
        from ingestion.pipeline import _entities_to_nodes
        from layers.ingestion import Document, EntityType, ExtractionResult, ExtractedEntity

        doc = Document(content="test", source_type="test")
        entities = [
            ExtractedEntity(entity_type=EntityType.MEDICAL_CONDITION,
                            properties={"id": "mc_ddd", "text": "first"}),
            ExtractedEntity(entity_type=EntityType.MEDICAL_CONDITION,
                            properties={"id": "mc_ddd", "text": "duplicate"}),
        ]
        extraction = ExtractionResult(
            extractor_id="test", document=doc, entities=entities)
        nodes = _entities_to_nodes(extraction)
        assert len(nodes) == 1
        assert nodes[0].properties["text"] == "first"


# ---------------------------------------------------------------------------
# Extraction recall integration tests (require GLiNER + spaCy)
# ---------------------------------------------------------------------------

@pytest.mark.skipif(
    not (_gliner_available() and _spacy_available()),
    reason="GLiNER and spaCy must be installed: pip install gliner spacy && python -m spacy download en_core_web_sm",
)
class TestExtractionRecall:

    @pytest.fixture(scope="class")
    def extractor(self):
        from ingestion.extractors.ssa_gliner_extractor import SSAGLiNERExtractor
        # Lower threshold to maximise recall for evaluation
        return SSAGLiNERExtractor(threshold=0.3)

    def test_recall_above_90_percent(self, extractor):
        """
        Entity extraction recall must exceed 90% on the 20-document test set.
        Recall = correctly identified mentions / total expected mentions.
        A mention is considered found if any extracted entity text contains it
        as a case-insensitive substring.
        """
        from layers.ingestion import Document

        total_expected = 0
        total_found = 0

        for text, expected in _TEST_DOCUMENTS:
            if not expected:
                continue
            doc = Document(content=text, source_type="test")
            result = extractor.extract(doc)
            extracted_texts = {e.properties.get(
                "text", "").lower() for e in result.entities}

            for _label, mentions in expected.items():
                for mention in mentions:
                    total_expected += 1
                    if any(mention.lower() in et for et in extracted_texts):
                        total_found += 1

        recall = total_found / total_expected if total_expected > 0 else 0.0
        assert recall >= 0.90, (
            f"Recall {recall:.1%} below 90% threshold "
            f"({total_found}/{total_expected} entities found)"
        )
