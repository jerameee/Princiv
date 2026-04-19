"""
SSA entity extractor using GLiNER zero-shot NER.

GLiNER runs a single model pass with SSA OWL class rdfs:labels as prompts,
returning typed spans with confidence scores. The default model works out
of the box; pass a fine-tuned checkpoint via model_name to improve recall.
"""

from __future__ import annotations

import re
from functools import cached_property

from layers.ingestion import (
    Document,
    EntityType,
    ExtractionResult,
    ExtractedEntity,
    SourceSpan,
)
from layers.ingestion.base import EntityExtractor

# NER prompt strings — match rdfs:label values from ssa_domain.ttl.
_SSA_NER_LABELS = [
    "Medical Condition",
    "Listing of Impairments",
    "Grid Rule",
    "Social Security Ruling",
    "RFC Component",
    "Occupation",
    "Evaluation Step",
    "Functional Limitation",
    "Claimant",
    "Court Case",
    "Evidence Type",
    "DOT Occupation",
    "Statute",
    "Regulation",
    "Court",
    "Jurisdiction",
    "Legal Concept",
]

# Map lowercase label → EntityType; covers alternate surface forms.
_LABEL_TO_ENTITY_TYPE: dict[str, EntityType] = {
    "medical condition": EntityType.MEDICAL_CONDITION,
    "listing of impairments": EntityType.LISTING,
    "listing": EntityType.LISTING,
    "grid rule": EntityType.GRID_RULE,
    "social security ruling": EntityType.SSR,
    "ssr": EntityType.SSR,
    "rfc component": EntityType.RFC_COMPONENT,
    "rfc": EntityType.RFC_COMPONENT,
    "occupation": EntityType.OCCUPATION,
    "dot occupation": EntityType.OCCUPATION,
    "evaluation step": EntityType.EVALUATION_STEP,
    "functional limitation": EntityType.FUNCTIONAL_LIMITATION,
    "claimant": EntityType.CLAIMANT,
    "court case": EntityType.COURT_CASE,
    "evidence type": EntityType.EVIDENCE_TYPE,
    "statute": EntityType.STATUTE,
    "regulation": EntityType.REGULATION,
    "court": EntityType.COURT,
    "jurisdiction": EntityType.JURISDICTION,
    "legal concept": EntityType.LEGAL_CONCEPT,
}

_ID_UNSAFE = re.compile(r"[^a-z0-9]+")


def _normalize_id(text: str, entity_type: EntityType) -> str:
    slug = _ID_UNSAFE.sub("_", text.lower().strip()).strip("_")
    return f"{entity_type.value.lower()}_{slug}"


class SSAGLiNERExtractor(EntityExtractor):
    """
    Entity extractor for SSA disability documents using GLiNER zero-shot NER.

    Parameters
    ----------
    model_name:
        GLiNER model checkpoint. Defaults to the medium multilingual model.
        Swap in a fine-tuned checkpoint for higher recall on SSA text.
    threshold:
        Confidence threshold for span acceptance (0.0-1.0).
    """

    def __init__(
        self,
        model_name: str = "urchade/gliner_medium-v2.1",
        threshold: float = 0.5,
    ) -> None:
        self._model_name = model_name
        self._threshold = threshold

    @property
    def extractor_id(self) -> str:
        return "ssa-gliner-v1"

    @property
    def supported_entity_types(self) -> frozenset[EntityType]:
        return frozenset(EntityType)

    @cached_property
    def _model(self):
        from gliner import GLiNER  # lazy — model download happens here
        return GLiNER.from_pretrained(self._model_name)

    def extract(self, document: Document) -> ExtractionResult:
        spans = self._model.predict_entities(
            document.content,
            _SSA_NER_LABELS,
            threshold=self._threshold,
        )

        entities: list[ExtractedEntity] = []
        seen_ids: set[str] = set()

        for span in spans:
            label_key = span["label"].lower()
            entity_type = _LABEL_TO_ENTITY_TYPE.get(label_key)
            if entity_type is None:
                continue

            node_id = _normalize_id(span["text"], entity_type)
            if node_id in seen_ids:
                continue
            seen_ids.add(node_id)

            entities.append(
                ExtractedEntity(
                    entity_type=entity_type,
                    properties={"id": node_id, "text": span["text"]},
                    confidence=float(span["score"]),
                    source_span=SourceSpan(start=span["start"], end=span["end"]),
                )
            )

        return ExtractionResult(
            extractor_id=self.extractor_id,
            document=document,
            entities=entities,
        )
