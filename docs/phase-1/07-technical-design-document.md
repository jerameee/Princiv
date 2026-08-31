# Technical Design Document

**Project:** Princiv — Legal Context Engine for Regulated AI Agents
**Platform component:** Veridian Core
**Document status:** Phase 1, Set C
**Companion documents:** [`06-system-architecture-document.md`](06-system-architecture-document.md) · [`05-software-requirements-spec.md`](05-software-requirements-spec.md)

---

## 1. Purpose and scope

The System Architecture Document describes the layers and why they exist. This document describes **how each component is built**: interfaces, algorithms, data structures, error handling, and the migration from current to target state.

> **Design status.** Sections marked **[DESIGN]** specify work not yet implemented — principally the domain-pack subsystem, which is the whole of `FR-PACK` and the centre of milestone M2. Sections marked **[AS BUILT]** document existing code. Code shown in **[DESIGN]** sections is illustrative of the intended shape, not a committed API.

---

## 2. Domain pack subsystem **[DESIGN]**

The MVP's principal new component. `FR-PACK-01` through `FR-PACK-08`.

### 2.1 Pack layout

A pack is a directory. Nothing about it is registered globally; it is located by path.

```
packs/ssa-disability/
├── pack.yaml               manifest — the source of truth
├── ontology/
│   └── ssa_domain.ttl      OWL 2.0 domain model
├── schema/
│   └── schema.cypher       constraints and indexes
└── seed/                   optional — domain content
    ├── load_evaluation_steps.cypher
    ├── load_grid_rules_and_occupations.cypher
    └── load_mvp_regulatory_content.cypher

packs/title-ix/
├── pack.yaml
├── ontology/
│   └── title_ix.ttl        skeleton — classes and properties only
└── schema/
    └── schema.cypher       constraints only, no seed data
```

The Title IX pack deliberately has no `seed/`. Its purpose is to prove that a pack loads and validates without engine changes (`S7`), not to serve an application.

### 2.2 Manifest format

The manifest is the single declaration of a domain's vocabulary. Everything else is checked against it.

```yaml
pack:
  id: ssa-disability
  version: 0.1.0
  namespace: "http://ssa.gov/disability/ontology#"

artifacts:
  ontology: ontology/ssa_domain.ttl
  schema:   schema/schema.cypher

entities:
  - name: MedicalCondition
    ontology_class: MedicalCondition
    ner_labels: ["Medical Condition"]
  - name: FunctionalLimitation
    ontology_class: FunctionalLimitation
    ner_labels: ["Functional Limitation"]
  - name: RFCComponent
    ontology_class: RFCComponent
    ner_labels: ["RFC Component", "RFC"]
  - name: DOTOccupation
    ontology_class: DOTOccupation
    ner_labels: ["DOT Occupation", "Occupation"]
  - name: WorkLevel
    ontology_class: ExertionalLevel
    ner_labels: ["Work Level"]

relationships:
  - name: AFFECTS_RFC_COMPONENT
    ontology_property: affectsRFCComponent      # explicit — never derived
    subject: FunctionalLimitation
    object:  RFCComponent

  - name: CAUSES_LIMITATION
    ontology_property: resultsInLimitation
    subject: MedicalCondition
    object:  FunctionalLimitation

  - name: CITES
    ontology_property: null                     # graph-schema only
    allowlist: true
    subject: Case
    object:  Case
```

**Three design decisions are embedded here, each closing a known defect.**

**`ontology_property` is declared, never derived (`IR-09`).** The current system computes ontology property names from vocabulary names by lowercasing and re-capitalising. `AFFECTS_RFC_COMPONENT` becomes `affectsRfcComponent`; the ontology declares `affectsRFCComponent`; every such triple is rejected (D1). Declaring the mapping removes the category of defect rather than patching the transformation.

**`ner_labels` is a list, and lives beside the entity it produces.** Today the prompt map is a separate 19-key dictionary in the extractor. Attaching labels to their entity makes the association checkable and prevents two prompts silently collapsing to one type — the `Occupation` / `DOTOccupation` failure (D3).

**`allowlist: true` marks predicates that exist in the graph but not the ontology.** Today this set is hardcoded in Princiv's gate as a duplicate of a block in Veridian Core's enum (D6-adjacent). Declaring it in the pack makes it visible and checkable.

### 2.3 Loaded representation

```python
@dataclass(frozen=True)
class EntitySpec:
    name: str
    ontology_class: str
    ner_labels: tuple[str, ...]

@dataclass(frozen=True)
class RelationshipSpec:
    name: str
    ontology_property: str | None
    subject: str
    object: str
    allowlist: bool = False

@dataclass(frozen=True)
class DomainPack:
    id: str
    version: str
    namespace: str
    ontology_path: Path
    schema_path: Path
    entities: Mapping[str, EntitySpec]
    relationships: Mapping[str, RelationshipSpec]

    def entity_names(self) -> frozenset[str]: ...
    def relationship_names(self) -> frozenset[str]: ...
    def ner_label_map(self) -> Mapping[str, str]:
        """NER prompt string -> entity name."""
    def is_allowlisted(self, rel: str) -> bool: ...
```

Frozen dataclasses: a pack is immutable once loaded. Mutating vocabulary mid-run is not a use case, and immutability removes a class of bug.

### 2.4 Replacing the enums

`EntityType` and `RelationshipType` are deleted from Veridian Core (`FR-PACK-03`, `S4`). Every current use becomes a pack lookup.

| Current | Replacement |
|---|---|
| `EntityType.MEDICAL_CONDITION` | `pack.entities["MedicalCondition"]` |
| `frozenset(EntityType)` | `pack.entity_names()` |
| `entity.entity_type.value` | `entity.entity_type` — a plain `str` validated against the pack |
| `_VALID_LABELS` in the loader | `pack.entity_names()` |
| `_GRAPH_SCHEMA_PREDICATES` in the gate | `pack.is_allowlisted(name)` |
| `_LABEL_TO_ENTITY_TYPE` in the extractor | `pack.ner_label_map()` |
| `_PREDICATE_MAP` in the relation extractor | derived from `pack.relationships` subject/object pairs |

`ExtractedEntity.entity_type` changes from `EntityType` to `str`. This trades compile-time enum safety for runtime pack validation — the necessary trade, since the type set is no longer known at authoring time. The conformance check plus the gate provide stronger guarantees than the enum did, because the enum never verified that its members matched the schema or the ontology.

### 2.5 Migration sequence

Order matters — this is the riskiest change in the MVP and should not be attempted in one step.

1. Add `DomainPack` and the loader alongside the existing enums. Nothing consumes it yet.
2. Author `packs/ssa-disability/pack.yaml` to reproduce today's vocabulary exactly, including current defects.
3. Write the conformance check. **Run it — it should fail**, reporting the known drifts. A conformance check that passes on first run against known-broken input is not working.
4. Correct the manifest until conformance passes. This is where D3, D4, D5, D7 are resolved.
5. Migrate consumers one module at a time, tests green after each.
6. Delete the enums. `S4` now holds.

Step 3 is the checkpoint. If the conformance check does not independently rediscover the drifts the briefing catalogued, it is not checking what it claims to.

---

## 3. Conformance check **[DESIGN]**

`FR-PACK-04` through `FR-PACK-06`. The mechanism that makes drift impossible rather than merely fixed.

> **Diagram:** [`03-conformance-check`](../diagrams/03-conformance-check.excalidraw.json) — the three-way agreement that closes D1 through D8.

### 3.1 The three checks

**Check 1 — manifest against graph schema.** Parse `schema.cypher` for constraint and index declarations. Verify: every manifest entity has a uniqueness constraint on its identifier; every constrained label appears in the manifest. Bidirectional, so both missing constraints and orphaned ones are caught.

**Check 2 — manifest against ontology.** Load the ontology with rdflib. Verify: every `ontology_class` is a declared `owl:Class`; every non-allowlisted `ontology_property` is a declared `owl:ObjectProperty`.

**Check 3 — declared pairings against axioms.** For each relationship, verify its declared `subject` satisfies the property's `rdfs:domain` and its `object` satisfies `rdfs:range`, resolving `rdfs:subClassOf` and `owl:equivalentClass`.

### 3.2 Reporting

```python
@dataclass(frozen=True)
class ConformanceViolation:
    check: str          # "schema" | "ontology" | "axioms"
    subject: str        # the manifest entry at fault
    detail: str

@dataclass(frozen=True)
class ConformanceReport:
    pack_id: str
    violations: tuple[ConformanceViolation, ...]

    @property
    def passed(self) -> bool:
        return not self.violations
```

All three checks always run (`FR-PACK-06`) — the check does not short-circuit. Fixing drift one error per CI run at ~5 hrs/week would be intolerable.

### 3.3 Execution

Runs as a pytest test in both repositories and in CI. A violation fails the test, which fails the build (`FR-PACK-05`).

An explicit negative test is required: introduce a known drift, assert the check catches it. This is `S5`, and it is the only evidence that the check works. A conformance check with no negative test is indistinguishable from a function that returns `True`.

---

## 4. Ontology gate **[AS BUILT, with fixes]**

`ingestion/validators/ontology_gate.py`. `FR-VAL-01` through `FR-VAL-12`.

> **Diagram:** [`04-validation-algorithm`](../diagrams/04-validation-algorithm.excalidraw.json) — five checks, each with its rejection reason.

### 4.1 Construction

The ontology is parsed once and reduced to four in-memory indexes (`NFR-10`):

| Index | Contents |
|---|---|
| `_classes` | Local names of every `owl:Class` |
| `_owl_properties` | Local names of every `owl:ObjectProperty` |
| `_domains` | property → set of permitted subject classes |
| `_ranges` | property → set of permitted object classes |

`_resolve_class_node` handles both named class URIs and `owl:unionOf` blank nodes, walking the RDF collection to expand union members. The ontology uses unions for several properties — `causesSymptom` permits both `MedicalCondition` and `Impairment` as subject.

Per-triple validation is then dictionary lookups only (`NFR-11`).

### 4.2 Per-triple algorithm

Five checks in fixed order, first failure returning a reason string. Order is chosen so that cheap checks precede expensive ones and so that the most specific diagnosis is produced.

| # | Check | Rejection reason |
|---|---|---|
| 0 | Allowlisted predicate? | — accept immediately |
| 1 | Declared object property? | `undeclared_predicate:<name>` |
| 2 | Subject type a declared class? | `invalid_subject_type:<type>` |
| 3 | Object type a declared class? | `invalid_object_type:<type>` |
| 4 | Subject satisfies domain? | `domain_violation:<type>_not_in_domain_of_<prop>` |
| 5 | Object satisfies range? | `range_violation:<type>_not_in_range_of_<prop>` |

### 4.3 Subclass and equivalence resolution

Checks 4 and 5 do not compare class names directly. Each type is expanded to itself plus its superclasses (`rdfs:subClassOf`) and equivalents (`owl:equivalentClass`, in both directions), and the check passes if the expansion intersects the permitted set.

This is why `MedicalCondition` satisfies a domain declared as `Impairment` — the ontology declares them equivalent. Without expansion, a large fraction of legitimate triples would be rejected.

### 4.4 Two fixes required

**Fix 1 — allowlist bypass ordering (D8, `FR-VAL-03`).** The allowlist check at step 0 returns before the class checks at steps 2 and 3. Four entity types (`Case`, `Court`, `Jurisdiction`, `LegalConcept`) are not declared `owl:Class`, and currently pass only because their predicates happen to be allowlisted. Any future non-allowlisted predicate touching them would be silently rejected.

The fix: allowlisting exempts a triple from the *property* check, not the *class* checks. Reorder so class validation runs first, then the allowlist decides whether property and axiom checks apply.

**Fix 2 — name derivation (D1, `FR-VAL-07`, `IR-09`).** `_enum_to_owl_local` is deleted. The gate reads `pack.relationships[name].ontology_property` directly. No transformation, no acronym problem, and one fewer implicit convention.

---

## 5. Extraction pipeline **[AS BUILT]**

### 5.1 `SSAGLiNERExtractor`

Implements `EntityExtractor`. `FR-ING-01` through `FR-ING-06`.

| Concern | Design |
|---|---|
| Model loading | `@cached_property` — importing the module does not download a model (`NFR-13`) |
| Prompts | **[DESIGN]** From `pack.ner_label_map()` rather than a module constant |
| Threshold | Constructor argument, default 0.5 |
| Checkpoint | Constructor argument — a fine-tuned model substitutes without code change |
| Identifiers | `_normalize_id`: lowercase, non-alphanumerics collapsed, entity-type prefix |
| Deduplication | Set of seen ids within a document; first occurrence wins |
| Unknown labels | Skipped silently — the model may return a prompt the pack does not map |

The extractor inherits the default `extract_async`, which runs the synchronous path in a thread-pool executor. GLiNER inference is CPU-bound, so this keeps the event loop free without requiring an async-native model API.

### 5.2 `RelationExtractor`

`FR-ING-07` through `FR-ING-09`.

spaCy provides sentence segmentation only — `en_core_web_sm` with `ner` and `textcat` disabled, cached via `functools.lru_cache(maxsize=1)`.

For each sentence: collect entities whose start offset falls within it, form ordered pairs, look up `(subject_type, object_type)` in the predicate map, and emit a triple with confidence `min(subject, object)`. If a pair matches in reverse, subject and object are swapped. Unmatched pairs are skipped.

**[DESIGN]** The predicate map is derived from `pack.relationships` rather than hardcoded. Two consequences: the map cannot drift from the ontology, and a pack declaring two relationships over the same type pair becomes a conformance error rather than a silent last-write-wins.

**Known limitations, accepted.** No cross-sentence relations (`FR-ING-12`, Future). At most one predicate per ordered type pair. Both are acceptable because the gate rejects structural errors downstream, so precision matters more than recall here.

### 5.3 `Pipeline`

Sequential per document: extract → relate → validate → convert → batch write. Aggregates a `PipelineResult` across documents.

Two conversion helpers:

- `_entities_to_nodes` — deduplicates by id, strips `id` from the properties dict (MERGE sets it from the match pattern), produces `GraphNode`
- `_relationships_to_graph_rels` — resolves entity references to their labels; **skips any relationship whose endpoints are not both present**

That skip is worth noting: it is a silent drop, and the only place in the pipeline where data disappears without being counted. It should emit a warning and a counter. Recorded here as a design gap; assigned to M4.

---

## 6. Persistence **[AS BUILT, with fixes]**

`ingestion/loaders/neo4j_loader.py`. `FR-STORE-01` through `FR-STORE-09`.

### 6.1 Merge semantics

```cypher
MERGE (n:{label} {id: $id})
ON CREATE SET n += $props
ON MATCH  SET n += $props
```

Labels cannot be parameterised in Cypher, so they are interpolated — which makes validation mandatory rather than defensive.

`upsert_node` prefixes an `OPTIONAL MATCH` to determine whether the node existed before the merge, so `WriteResult.created` is accurate. The batch path omits this to avoid a second index lookup per node.

### 6.2 Batch transactions

`upsert_batch` opens an explicit transaction, writes all nodes, then all relationships, commits, and rolls back on any exception (`FR-STORE-02`, `FR-STORE-03`). Node-before-relationship ordering guarantees endpoints exist.

### 6.3 Three fixes required

**Fix 1 — silent no-op on missing endpoint (D9, `FR-STORE-04`).** `MATCH … MATCH … MERGE` yields zero rows when an endpoint is absent; `single()` returns `None`; the code returns `WriteResult(created=False)`. The documented contract says it raises. The fix: detect the empty result and raise `MissingEndpointError` naming both endpoints.

**Fix 2 — meaningless created/merged counts (D9, `FR-STORE-05`).** `_UPSERT_REL` hardcodes `RETURN true AS created`, and the batch path tallies everything as merged. The fix: return `count` from the merge and derive the distinction; if a second lookup proves too costly at batch scale, remove the four-counter breakdown from the interface rather than reporting numbers that are not true.

**Fix 3 — bypassable label guard (D10, `FR-STORE-06`).**

```python
# current — the allowlist is defeated by the disjunction
if label not in _VALID_LABELS and not _SAFE_LABEL_RE.match(label):
    raise ValueError(...)
```

`_SAFE_LABEL_RE` matches nearly any identifier, so the allowlist is effectively unreachable. The fix is a conjunction against the pack: the label must be in `pack.entity_names()`, full stop. **Relationship types must be validated the same way** — they are currently interpolated into Cypher with no validation at all.

### 6.4 Audit logging

Every write emits JSON through stdlib logging (`FR-STORE-07`):

```json
{"action": "batch_node", "label": "MedicalCondition",
 "entity_id": "medicalcondition_degenerative_disc_disease",
 "created": true, "ts": "2026-08-31T14:22:03.117Z"}
```

Stdlib logging means no new dependency and no new infrastructure — redirecting the logger redirects the audit trail.

---

## 7. Query layer **[AS BUILT]**

### 7.1 Templates

Parameterised Cypher in `graph/cypher_templates.py`. `GRID_RULE_LOOKUP` is the important one: a four-property exact match resolving through the composite index in a single seek.

**[DESIGN]** `MEDEVOC_CHAIN` traverses five hops whose edge names must match what ingestion writes. Today they do not (D2) — ingestion emits `RESULTS_IN_LIMITATION` where the chain expects `CAUSES_LIMITATION`, and `AFFECTS_RFC_COMPONENT` where it expects `MAPS_TO_RFC`. Reconciliation is M4 work and must pick **one** name per edge, updating manifest, seed data, and template together. The conformance check then prevents recurrence.

### 7.2 Step router

`build_step_router(driver)` returns a closure usable as a LangGraph node. Given `active_step` and `answer`, it selects `IF_YES_GO_TO` or `IF_NO_GO_TO`, traverses one hop, and returns **only changed state** — matching LangGraph merge semantics (`FR-QRY-06`).

Termination is detected by the target carrying the `EvaluationOutcome` label. Errors are explicit: `ValueError` for missing or invalid state, `LookupError` for a missing edge with a message naming the likely cause.

The procedure is read from the graph on every call. Nothing about the five steps is compiled into Python.

---

## 8. Error handling

| Condition | Response | Rationale |
|---|---|---|
| Triple fails validation | Count, log reason, continue | Expected in normal operation |
| Endpoint missing on relationship write | **[DESIGN]** Raise `MissingEndpointError` | Caller's model is wrong; continuing corrupts silently |
| Batch write fails | Roll back entire transaction | Partial graphs are worse than none |
| Label or relationship not in pack | **[DESIGN]** Raise `ValueError` | Programming error, not data error |
| Conformance violation | **[DESIGN]** Fail the build | The mechanism has no value if bypassable |
| Step router: no branch edge | `LookupError` with diagnostic | Evaluation graph not loaded |
| Step router: invalid answer | `ValueError` | Caller error |
| Model or spaCy model unavailable | Raise at first use, not import | Import must stay cheap |

**The rule: data problems are counted; structural problems raise.** A malformed triple is expected. A missing node when writing a relationship means the caller's assumptions are wrong.

---

## 9. Testing design

| Layer | Approach | Requirement |
|---|---|---|
| Engine contracts | Contract tests against a fake implementation of each ABC | `NFR-23`, `IR-11` |
| Conformance | Positive on real packs; **negative test introducing known drift** | `FR-PACK-04`, `S5` |
| Gate | Table-driven — one case per rejection reason, plus subclass/equivalence acceptance | `FR-VAL-*` |
| Extraction recall | 20-document reference set, recall computed and asserted > 90% | `NFR-01` |
| Store | Against a live Neo4j in CI; **not** auto-skipped there | `NFR-25` |
| Pipeline end-to-end | Document → `MEDEVOC_CHAIN` result | `S8` |

**The auto-skip pattern is correct locally and wrong in CI.** Three of four Princiv test files skip when Neo4j is unreachable, which is right for a developer without a database. In CI it means a green build proves almost nothing, so CI runs Neo4j in a service container and the skip must not trigger.

**[DESIGN]** An in-memory `GraphStore` (`FR-STORE-10`, P2) would let pipeline tests run without a database at all. Deferred — worth building only if the Neo4j service container proves slow or unreliable.

---

## 10. Module map

Target state after M2. Bold entries are new.

```
veridian-core/layers/
├── ingestion/
│   ├── base.py             EntityExtractor ABC
│   ├── document_loader.py  DocumentLoader ABC
│   ├── registry.py         ExtractorRegistry
│   └── types.py            interchange types — enums REMOVED
├── storage/
│   ├── base.py             GraphStore ABC
│   └── types.py            GraphNode, GraphRelationship, results
└── packs/                                                    ** NEW **
    ├── types.py            DomainPack, EntitySpec, RelationshipSpec
    ├── loader.py           manifest parsing and validation
    └── conformance.py      three-way check

Princiv/
├── packs/                                                    ** NEW **
│   ├── ssa-disability/
│   └── title-ix/
├── ingestion/
│   ├── pipeline.py
│   ├── extractors/         labels from pack
│   ├── validators/         ontology_gate.py — derivation REMOVED
│   └── loaders/            neo4j_loader.py — guard tightened
└── graph/
    ├── cypher_templates.py
    ├── step_router.py
    └── tests/
```

`ExtractorRegistry` and `DocumentLoader` are currently dead code (D14). M4 decides each: implement or remove. Retaining an unused abstraction has a real cost — it implies a capability that does not exist.

---

## 11. Design decisions

| # | Decision | Rationale | Alternative rejected |
|---|---|---|---|
| **TD-1** | Manifest declares ontology property names | Derivation cannot round-trip acronyms (D1) | Improving the transformation — patches a symptom |
| **TD-2** | `DomainPack` frozen | Vocabulary never changes mid-run | Mutable pack — enables a bug class for no benefit |
| **TD-3** | `entity_type` becomes `str` | Type set unknown at authoring time | Dynamic enum generation — obscure, poor tooling support |
| **TD-4** | Conformance reports all violations | Fixing one per CI run is intolerable at 5 hrs/week | Fail-fast |
| **TD-5** | Conformance as a pytest test | No new tooling; runs locally and in CI identically | Standalone CLI |
| **TD-6** | Allowlist exempts property checks only, not class checks | Current ordering hides D8 | Status quo |
| **TD-7** | Migration adds the pack before removing enums | Both paths work during migration; tests stay green | Big-bang replacement |
| **TD-8** | Conformance must fail on first run | Proves it checks something real | Authoring the manifest correct-first |

---

## 12. Approval

| Role | Name | Date | Status |
|---|---|---|---|
| Project sponsor | Jeremy Jones | | Pending |

---

*Next: [`08-uiux-wireframes.md`](08-uiux-wireframes.md)*
