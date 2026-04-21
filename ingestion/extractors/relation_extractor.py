"""
Relation extractor: builds (subject, predicate, object) triples from
co-occurring entity pairs within sentence boundaries.

spaCy is used for sentence segmentation only (ner and textcat disabled).
Relationship type is assigned from a predicate map keyed on
(subject_entity_type, object_entity_type), derived from OWL domain/range
axioms in ontology/ssa_domain.ttl.
"""

from __future__ import annotations

import functools

from layers.ingestion import (
    EntityType,
    ExtractionResult,
    ExtractedRelationship,
    RelationshipType,
)

# (subject_type, object_type) -> predicate
# Sourced from domain/range axioms added in Task 1.1.2 of ssa_domain.ttl.
_PREDICATE_MAP: dict[tuple[EntityType, EntityType], RelationshipType] = {
    (EntityType.MEDICAL_CONDITION, EntityType.FUNCTIONAL_LIMITATION): RelationshipType.RESULTS_IN_LIMITATION,
    (EntityType.MEDICAL_CONDITION, EntityType.LISTING):               RelationshipType.MAY_MEET_LISTING,
    (EntityType.FUNCTIONAL_LIMITATION, EntityType.RFC_COMPONENT):     RelationshipType.AFFECTS_RFC_COMPONENT,
    (EntityType.LISTING, EntityType.EVIDENCE_TYPE):                   RelationshipType.REQUIRES_EVIDENCE,
    (EntityType.EVALUATION_STEP, EntityType.EVIDENCE_TYPE):           RelationshipType.REQUIRES_EVIDENCE,
    (EntityType.EVALUATION_STEP, EntityType.EVALUATION_STEP):         RelationshipType.IF_YES_GO_TO,
    (EntityType.CLAIMANT, EntityType.STATUTE):                        RelationshipType.PROTECTED_BY,
    (EntityType.CLAIMANT, EntityType.REGULATION):                     RelationshipType.PROTECTED_BY,
    (EntityType.CASE, EntityType.LEGAL_CONCEPT):                      RelationshipType.ADDRESSES,
    (EntityType.CASE, EntityType.COURT):                              RelationshipType.DECIDED_BY,
}


class RelationExtractor:
    """
    Produces ExtractedRelationship triples from an ExtractionResult.

    Entity pairs that co-occur within a sentence and match a known
    (subject_type, object_type) pattern are assigned a predicate.
    Unrecognised pair types are silently skipped.
    """

    def extract_relations(self, result: ExtractionResult) -> list[ExtractedRelationship]:
        nlp = _get_nlp()
        doc = nlp(result.document.content)
        relationships: list[ExtractedRelationship] = []

        for sent in doc.sents:
            s_start, s_end = sent.start_char, sent.end_char
            in_sent = [
                e for e in result.entities
                if e.source_span and s_start <= e.source_span.start < s_end
            ]

            for i, subj in enumerate(in_sent):
                for obj in in_sent[i + 1:]:
                    predicate = _PREDICATE_MAP.get((subj.entity_type, obj.entity_type))
                    if predicate is None:
                        predicate = _PREDICATE_MAP.get((obj.entity_type, subj.entity_type))
                        if predicate is not None:
                            subj, obj = obj, subj
                    if predicate is None:
                        continue

                    subj_id = subj.properties.get("id")
                    obj_id = obj.properties.get("id")
                    if not subj_id or not obj_id:
                        continue

                    relationships.append(
                        ExtractedRelationship(
                            relationship_type=predicate,
                            source_ref=subj_id,
                            target_ref=obj_id,
                            confidence=min(subj.confidence, obj.confidence),
                        )
                    )

        return relationships


@functools.lru_cache(maxsize=1)
def _get_nlp():
    import spacy
    try:
        return spacy.load("en_core_web_sm", disable=["ner", "textcat"])
    except OSError:
        from spacy.cli import download as spacy_download
        spacy_download("en_core_web_sm")
        import spacy as _spacy
        return _spacy.load("en_core_web_sm", disable=["ner", "textcat"])
