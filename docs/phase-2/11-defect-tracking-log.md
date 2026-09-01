# Defect Tracking Log

**Project:** Princiv — Legal Context Engine for Regulated AI Agents
**Document status:** Phase 2 · **Living document** — updated continuously, not a snapshot
**Companion documents:** [`09-test-plan.md`](09-test-plan.md) · [`../00-technical-briefing.md`](../00-technical-briefing.md) · [`../phase-1/03-project-management-plan.md`](../phase-1/03-project-management-plan.md)

---

## 1. Purpose and status

This is the authoritative register of known defects. It supersedes Part VIII of the technical briefing, which remains readable as a point-in-time analysis but is **no longer the place to record new findings** — they go here.

**This document is live.** Unlike the Phase 1 set, it is expected to change constantly: every defect found, fixed, or verified updates it. A stale defect log is worse than none, because it implies a state of knowledge that does not hold.

### 1.1 On the identifiers

Defects retain the `D1`–`D16` identifiers assigned in the briefing rather than being renumbered into a new scheme.

Those identifiers are already referenced roughly forty times across the Project Charter, Project Management Plan, System Architecture Document, and Technical Design Document. Renumbering would break every one of those references for no gain. New defects continue the sequence from `D17`.

---

## 2. Dashboard

*Last updated: at Phase 2 authoring. No remediation work has begun.*

### By severity

| Severity | Count | Open | In Progress | Fixed | Verified |
|---|---|---|---|---|---|
| **S1 — Silently wrong** | 3 | 3 | 0 | 0 | 0 |
| **S2 — Structural** | 7 | 7 | 0 | 0 | 0 |
| **S3 — Hygiene** | 7 | 7 | 0 | 0 | 0 |
| **Total** | **17** | **17** | **0** | **0** | **0** |

### By milestone

| Milestone | Defects | IDs |
|---|---|---|
| **M1** Foundation & Hygiene | 5 | D1, D11, D13, D15, D16 |
| **M2** Domain-Pack Refactor | 5 | D4, D6, D7, D8, D12 |
| **M3** Title IX Validation | 0 | — |
| **M4** Working Vertical Slice | 7 | D2, D3, D5, D9, D10, D14, D17 |

Every known defect is assigned to a milestone. None is unassigned or deferred past the MVP.

---

## 3. Severity definitions

| Severity | Definition | Response |
|---|---|---|
| **S1** | Produces incorrect behaviour with no visible signal. Data is lost, discarded, or wrong, and nothing indicates it | Fix in the earliest milestone that can accommodate it. Never defer past the MVP |
| **S2** | Structural inconsistency that blocks a specified capability or makes a component unable to fulfil its contract. Visible if looked for | Fix within the MVP, in the milestone that owns the affected subsystem |
| **S3** | Correctness is unaffected, but the defect impedes development, misleads a reader, or removes a safety net | Fix within the MVP where cheap; may be deferred through change control |

The distinguishing question for S1 is not severity of consequence but **detectability**. A defect that fails loudly is easier to live with than one that quietly discards a whole relationship type.

---

## 4. Status workflow

```
Open  ->  In Progress  ->  Fixed  ->  Verified
  |                          |
  +-------> Won't Fix        +-------> Reopened
```

| Status | Meaning |
|---|---|
| **Open** | Recorded, not yet being worked |
| **In Progress** | Being worked in the current milestone |
| **Fixed** | Change committed; verification not yet performed |
| **Verified** | Verification step executed and passed. **Requires a passing test, not an inspection** |
| **Reopened** | Verification failed, or the defect recurred |
| **Won't Fix** | Deliberately accepted. Requires a change-log entry in the PM Plan §6.3 |

**Fixed is not Verified.** With a single contributor and no independent reviewer, the gap between "I changed it" and "a test proves it" is the only real check available. Every defect below carries a verification step that is executable, not a judgement call.

---

## 5. Defect records

### S1 — Silently wrong

---

#### D1 · Acronym conversion rejects a whole relationship type

| Field | Value |
|---|---|
| **Severity** | S1 |
| **Status** | Open |
| **Component** | Princiv · ontology gate |
| **Location** | `ingestion/validators/ontology_gate.py:57-60` |
| **Violates** | `FR-VAL-07`, `IR-09` |
| **Milestone** | M1 |

**Description.** `_enum_to_owl_local` derives an ontology property name by lowercasing the vocabulary name and re-capitalising each segment. `AFFECTS_RFC_COMPONENT` becomes `affectsRfcComponent`. The ontology declares `affectsRFCComponent`. The lookup fails and the triple is rejected as `undeclared_predicate`.

**Impact.** 100% of `AFFECTS_RFC_COMPONENT` triples are discarded. The relation extractor actively produces them (`ingestion/extractors/relation_extractor.py:27`), so the pipeline generates triples guaranteed never to be stored. The only signal is a rejection counter nobody is reading. All fourteen other relationship types round-trip correctly, which is why this went unnoticed.

**Detection.** Static analysis during the Phase 1 repository review.

**Resolution plan.** Two parts. Immediate: correct the transformation so acronyms survive. Structural: `IR-09` removes derivation entirely — the manifest declares `ontology_property` explicitly (TDD §2.2).

**Verification.** A test asserts that every relationship name in the pack manifest resolves to a property declared in the ontology, with `AFFECTS_RFC_COMPONENT → affectsRFCComponent` as an explicit case. See `TC-VAL-07`.

---

#### D2 · Medical-vocational chain unreachable from ingested data

| Field | Value |
|---|---|
| **Severity** | S1 |
| **Status** | Open |
| **Component** | Princiv · query templates + relation extractor |
| **Location** | `graph/cypher_templates.py:94-110`; `ingestion/extractors/relation_extractor.py:25,27` |
| **Violates** | `FR-QRY-04` |
| **Milestone** | M4 |

**Description.** `MEDEVOC_CHAIN` traverses five hops: `CAUSES_LIMITATION → MAPS_TO_RFC → DETERMINES_WORK_LEVEL → GOVERNS → RESULTS_IN_DECISION`. Only the last exists in the extraction vocabulary. Two of the missing hops have near-synonyms that the extractor emits instead:

| Chain expects | Extractor emits | Same node pair |
|---|---|---|
| `CAUSES_LIMITATION` | `RESULTS_IN_LIMITATION` | MedicalCondition → FunctionalLimitation |
| `MAPS_TO_RFC` | `AFFECTS_RFC_COMPONENT` | FunctionalLimitation → RFCComponent |

**Impact.** The flagship Steps 3–5 query returns nothing for anything the pipeline ingested. Seeded data traverses correctly, so the query appears to work — which is precisely what makes this an S1. Ingested and seeded knowledge occupy the same graph under different edge names.

**Detection.** Cross-referencing the query templates against the extraction vocabulary during Phase 1.

**Resolution plan.** Choose one canonical name per edge and align manifest, seed data, and template together. The conformance check (`FR-PACK-04`) then prevents recurrence.

**Verification.** Ingest a document through the full pipeline and assert `MEDEVOC_CHAIN` returns a non-empty result. See `TC-E2E-01`.

---

#### D3 · Occupation naming split three ways

| Field | Value |
|---|---|
| **Severity** | S1 |
| **Status** | Open |
| **Component** | Cross-cutting — vocabulary, schema, seed data, extractor |
| **Location** | `graph/schema.cypher:106,142`; `graph/cypher_templates.py:56,76`; `ingestion/extractors/ssa_gliner_extractor.py:55` |
| **Violates** | `FR-GRAPH-01`, `FR-ING-03` |
| **Milestone** | M4 |

**Description.** Three sources disagree:

| Source | Uses |
|---|---|
| Vocabulary enum | `Occupation` |
| `schema.cypher` | `Occupation` |
| Seed data (35 occurrences) | `DOTOccupation` |
| Both Step 5 templates | `DOTOccupation` |
| Ontology | Declares **both** |

The extractor maps the NER prompt `"dot occupation"` to `Occupation`, so an extracted DOT occupation is written under a label no Step 5 query reads.

**Impact.** Extracted occupations are invisible to Step 5 analysis. Writes succeed, constraints are satisfied, nothing errors — the data simply does not participate in the queries it exists for.

**Detection.** Label census across schema, seed data, and templates.

**Resolution plan.** Standardise on `DOTOccupation` — the name all real data and all queries already use. Update vocabulary, schema constraint, and the extractor's label map.

**Verification.** Conformance check confirms the vocabulary entity, schema constraint, and ontology class agree; a pipeline test asserts an extracted occupation is returned by `STEP5_OTHER_WORK`. See `TC-PACK-02`, `TC-QRY-02`.

---

### S2 — Structural

---

#### D4 · Load-bearing labels absent from the vocabulary

| Field | Value |
|---|---|
| **Severity** | S2 · **Status** Open · **Component** Veridian Core vocabulary |
| **Location** | `veridian-core/layers/ingestion/types.py:15-37` |
| **Violates** | `FR-GRAPH-01`, `FR-GRAPH-07` · **Milestone** M2 |

**Description.** Three labels carry real data but have no vocabulary entry:

| Label | Usage | Consequence |
|---|---|---|
| `WorkLevel` | 26 occurrences in seed data; hinge of both Step 5 templates | Un-ingestible |
| `EvaluationOutcome` | 22 occurrences; target of `RESULTS_IN_DECISION` | Un-ingestible |
| `LegalSource` | Umbrella label carrying three existence constraints | Unreachable — `_entities_to_nodes` emits one label per node, so multi-label `:Case:LegalSource` cannot be produced |

**Impact.** The extraction path structurally cannot produce node types the query path depends on. `LegalSource`'s existence constraints can never fire on ingested nodes.

**Resolution plan.** Add `WorkLevel` and `EvaluationOutcome` to the SSA pack manifest. `LegalSource` needs a separate decision: either support multi-label nodes or drop the umbrella label. Recommend dropping — it is a modelling convenience the graph does not need.

**Verification.** Conformance check reports no schema label absent from the manifest. See `TC-PACK-01`.

---

#### D5 · Nine relationship types in data with no vocabulary entry

| Field | Value |
|---|---|
| **Severity** | S2 · **Status** Open · **Component** Cross-cutting |
| **Location** | `graph/seed_data/*.cypher`; `graph/cypher_templates.py` |
| **Violates** | `FR-ING-09`, `FR-QRY-04` · **Milestone** M4 |

**Description.** `CAUSES_LIMITATION`, `DETERMINES_WORK_LEVEL`, `MAPS_TO_RFC`, `GOVERNS`, `RESULTS_IN`, `INTERPRETS`, `SUPERSEDES`, `OVERRULES`, `DISTINGUISHES` are created by seed loaders but cannot be produced by the pipeline.

**Impact.** The seeded graph is richer than any graph the pipeline can build. Directly compounds D2.

**Resolution plan.** Resolved together with D2. Each type is either added to the manifest with declared subject/object types, or renamed to an existing entry.

**Verification.** Conformance check plus `TC-E2E-01`.

---

#### D6 · Vocabulary entries with no usage anywhere

| Field | Value |
|---|---|
| **Severity** | S2 · **Status** Open · **Component** Veridian Core vocabulary |
| **Location** | `veridian-core/layers/ingestion/types.py:49,54` |
| **Violates** | `FR-PACK-04` · **Milestone** M2 |

**Description.** `CAUSES_SYMPTOM` and `RESTRICTS_TO_WORK_LEVEL` appear in no seed data, no template, and no predicate map. Separately, `PROTECTED_BY`, `RESULTS_IN_LIMITATION`, and `AFFECTS_RFC_COMPONENT` are emitted by the extractor but read by nothing — write-only edges.

**Impact.** Vocabulary that implies capability the system does not have. Misleads any reader inferring the data model from the enum.

**Resolution plan.** Remove the two dead entries. The three write-only edges resolve via D2.

**Verification.** Conformance check flags manifest entries with no schema or ontology counterpart. See `TC-PACK-03`.

---

#### D7 · `Case` and `CourtCase` are mirror-image dead ends

| Field | Value |
|---|---|
| **Severity** | S2 · **Status** Open · **Component** Ontology + vocabulary |
| **Location** | `ontology/ssa_domain.ttl:1802`; `graph/schema.cypher`; seed data |
| **Violates** | `FR-ONT-07` · **Milestone** M2 |

**Description.** Both are vocabulary entries with uniqueness constraints. Seed data uses `Case` (67 occurrences); `CourtCase` has zero. The ontology declares `:CourtCase` and has **no `:Case` class**. So `Case` fails the gate's class check while `CourtCase` matches no real data.

**Impact.** Neither name works end to end. Any triple involving `Case` would be rejected on class grounds were it not for the allowlist bypass described in D8.

**Resolution plan.** Choose one. Recommend `CourtCase`, matching the ontology, and rename in schema and seed data.

**Verification.** Conformance check confirms every manifest entity resolves to a declared `owl:Class`. See `TC-PACK-02`.

---

#### D8 · Four entity types are not declared OWL classes

| Field | Value |
|---|---|
| **Severity** | S2 · **Status** Open · **Component** Ontology + gate |
| **Location** | `ontology/ssa_domain.ttl`; `ingestion/validators/ontology_gate.py:155,165` |
| **Violates** | `FR-ONT-07`, `FR-VAL-03` · **Milestone** M2 |

**Description.** `Case`, `Court`, `Jurisdiction`, and `LegalConcept` are vocabulary entries with no corresponding `owl:Class`. Triples involving them should fail the gate's class check.

They currently pass — but by accident. Their predicates (`ADDRESSES`, `DECIDED_BY`) are in the allowlist, which returns at `:155` **before** the class check at `:165`.

**Impact.** A latent failure. The moment a non-allowlisted predicate touches any of these four types, the triple is silently rejected with no obvious cause. The allowlist is masking a modelling gap.

**Resolution plan.** Two parts. Declare the four classes in the ontology. Reorder the gate so allowlisting exempts a triple from the *property* check only, never the *class* checks (TDD §4.4).

**Verification.** A test constructs a non-allowlisted triple over an undeclared class and asserts rejection with `invalid_subject_type`. See `TC-VAL-03`.

---

#### D9 · Store implementation violates its own interface contract

| Field | Value |
|---|---|
| **Severity** | S2 · **Status** Open · **Component** Princiv · Neo4j store |
| **Location** | `ingestion/loaders/neo4j_loader.py:57,147,164` |
| **Violates** | `FR-STORE-04`, `FR-STORE-05` · **Milestone** M4 |

**Description.** Three departures from the documented `GraphStore` contract:

| Contract (`veridian-core/layers/storage/base.py:40-41`) | Actual |
|---|---|
| "Raises if either node is absent" | `MATCH…MATCH…MERGE` yields zero rows; returns `WriteResult(created=False)`. Silent no-op |
| `WriteResult.created` indicates creation | `:57` hardcodes `RETURN true AS created` — always `True` for relationships |
| `BatchWriteResult` distinguishes created from merged | `:147`, `:164` increment only the merged counters |

**Impact.** Writing a relationship whose endpoint is missing appears to succeed. Every reported metric about creation is untrue.

**Resolution plan.** Raise `MissingEndpointError` on an empty result. Return `count` from the merge to derive creation accurately — or, if the extra lookup proves too costly at batch scale, remove the four-counter breakdown from the interface rather than reporting numbers that are false.

**Verification.** Tests assert the raise on a missing endpoint and correct counter values across a create-then-merge sequence. See `TC-STORE-04`, `TC-STORE-05`.

---

#### D10 · Label guard is bypassable; relationship types unguarded

| Field | Value |
|---|---|
| **Severity** | S2 · **Status** Open · **Component** Princiv · Neo4j store |
| **Location** | `ingestion/loaders/neo4j_loader.py:29-30,35,111,157` |
| **Violates** | `FR-STORE-06` · **Milestone** M4 |

**Description.**

```python
if label not in _VALID_LABELS and not _SAFE_LABEL_RE.match(label):
    raise ValueError(...)
```

`_SAFE_LABEL_RE` is `^[A-Za-z][A-Za-z0-9]*$`, which matches nearly any identifier. Because the conditions are conjoined, the allowlist is effectively unreachable — a label absent from the vocabulary passes as long as it looks like an identifier. Separately, `relationship_type` is interpolated into Cypher at `:111` and `:157` with **no validation at all**.

**Impact.** Labels can be written that no query reads and no constraint governs. Cypher identifiers reach query text unvalidated — currently reachable only from internal callers, but the guard exists precisely so that stays true.

**Resolution plan.** Replace the disjunction with a strict membership test against `pack.entity_names()`. Apply equivalent validation to relationship types against `pack.relationship_names()`.

**Verification.** Tests assert that an out-of-vocabulary label and an out-of-vocabulary relationship type both raise. See `TC-STORE-06`.

---

### S3 — Hygiene and legacy

---

#### D11 · Contract-law legacy data and queries

| Field | Value |
|---|---|
| **Severity** | S3 · **Status** Open · **Component** Seed data, validation queries, `CLAUDE.md` |
| **Location** | `graph/seed_data/load_seed_data.cypher` (597 lines); `graph/validation_queries.cypher` queries 1–30; `CLAUDE.md:96,117` |
| **Violates** | `FR-GRAPH-08` · **Milestone** M1 |

**Description.** The foundational seed loader is entirely California contract law — Donovan v. RRL, Armendariz, AT&T Mobility v. Concepcion. Thirty of thirty-seven validation queries test that domain. `CLAUDE.md:96` documents the contract-law state as the expected post-seed baseline; `:117` acknowledges the migration as outstanding. `schema.cypher` also declares `Matter` and `User` constraints with no ontology class, no seed data, and no vocabulary entry.

**Impact.** The file described as "the de facto test suite" mostly tests an abandoned domain. A new contributor following `CLAUDE.md` arrives at a graph full of contract cases.

**Resolution plan.** Delete the seed loader and queries 1–30. Retain the `Case`/`Court`/`Jurisdiction`/`LegalConcept` constraints — SSA circuit-court content will need them. Correct `CLAUDE.md`. Git history preserves everything.

**Verification.** No contract-law identifier remains outside `.git`; the validation suite runs clean against a freshly seeded graph. See `TC-DATA-01`.

---

#### D12 · Veridian Core has no tests

| Field | Value |
|---|---|
| **Severity** | S3 · **Status** Open · **Component** Veridian Core |
| **Location** | `veridian-core/pyproject.toml:15` |
| **Violates** | `NFR-23`, `IR-11` · **Milestone** M2 |

**Description.** `testpaths = ["tests"]` points at a directory that does not exist. There are zero tests on any branch. Every documented contract — merge idempotency, atomic batch transactions, the "raises if absent" guarantee, duplicate-id `ValueError`, the `extract_async` fallback — is unverified upstream. The `dev` extra installs pytest and pytest-asyncio for nothing.

**Impact.** The engine's interfaces are the platform's product. They are entirely unverified, and D9 is the direct consequence — a contract nothing checks is a contract nothing honours.

**Resolution plan.** Create `veridian-core/tests/` with contract tests exercising each ABC against a fake implementation.

**Verification.** `pytest` collects and passes a non-empty suite in the engine repository. See `TC-ENG-01`.

---

#### D13 · Engine not declared as a dependency

| Field | Value |
|---|---|
| **Severity** | S3 · **Status** Open · **Component** Princiv packaging |
| **Location** | `requirements.txt:10-14` |
| **Violates** | `NFR-22` · **Milestone** M1 |

**Description.** The veridian-core dependency lines are commented out. `pip install -r requirements.txt` produces an environment where `import layers` fails and every module under `ingestion/` is unimportable. The commented install hint pins to a merged feature branch rather than a tag or SHA. Resolution currently depends on `conftest.py` manipulating `sys.path` and on ambient environment state.

**Impact.** A clean checkout does not produce a working environment. Already cost real debugging time during setup.

**Resolution plan.** Declare the dependency properly, pinned to a tag or commit SHA. Verify from a clean virtualenv.

**Verification.** In a fresh virtualenv, `pip install -r requirements.txt` then `pytest` collects without `PYTHONPATH` intervention. See `TC-ENV-01`.

---

#### D14 · Dead abstractions

| Field | Value |
|---|---|
| **Severity** | S3 · **Status** Open · **Component** Veridian Core |
| **Location** | `veridian-core/layers/ingestion/document_loader.py`; `registry.py` |
| **Violates** | `FR-ING-10`, `FR-ING-11` · **Milestone** M4 |

**Description.** `DocumentLoader` has no subclasses, no imports, and no callers anywhere in either repository. `ExtractorRegistry` is never instantiated — `Pipeline.__init__` hardcodes exactly one extractor.

**Impact.** Both imply capability that does not exist. `DocumentLoader` is the first stage of the documented pipeline flow and has no implementation, so the flow diagram overstates what is built.

**Resolution plan.** Decide per abstraction: implement or remove. A file-based `DocumentLoader` is genuinely useful and cheap. `ExtractorRegistry` has no current use case and should probably go.

**Verification.** No abstraction remains without either an implementation or a removal commit. See `TC-ENG-02`.

---

#### D15 · No continuous integration

| Field | Value |
|---|---|
| **Severity** | S3 · **Status** Open · **Component** Both repositories |
| **Location** | `.github/` absent from both |
| **Violates** | `NFR-21`, `NFR-25` · **Milestone** M1 |

**Description.** Neither repository runs automated checks. Nothing would have caught the broken `testpaths`, the vocabulary drift, or D1.

**Impact.** With one contributor and no reviewer, CI is the only mechanical check available. Its absence is why sixteen defects accumulated undetected.

**Resolution plan.** GitHub Actions in both repositories: lint, tests, import check, conformance. **Princiv's workflow must run Neo4j as a service container** — three of four test files auto-skip without it, so CI without a database would report green while exercising almost nothing.

**Verification.** A deliberately broken commit fails CI in both repositories. See `TC-CI-01`.

---

#### D16 · Documentation defects

| Field | Value |
|---|---|
| **Severity** | S3 · **Status** Open · **Component** Documentation |
| **Location** | `veridian-core/README.md`; `Princiv/CLAUDE.md`; `ontology/ssa_domain.ttl:255,337` |
| **Violates** | `NFR-26` · **Milestone** M1 |

**Description.**

| Defect | Detail |
|---|---|
| Entity count wrong | README claims 13; actual is 17 |
| Relationship count wrong | README claims 16; actual is 15 |
| Usage example does not run | Overrides only `extract_async`; would raise `TypeError: Can't instantiate abstract class` |
| Diagram not committed | `user-attachments` URL — will not render in a clone or fork |
| Licence claimed, absent | README says MIT; no `LICENSE` file, no `license` field |
| Integration undocumented | `CLAUDE.md` never mentions veridian-core, `layers.*`, or `ingestion/` |
| Ontology typo | `:ConclussivePresumption` (double-s) at `:255`, inherited by `:Listing` at `:337` |

**Impact.** The engine's README is its front door and its headline example raises on execution. `CLAUDE.md` omits the entire integration, so an agent reading it has no idea the ingestion layer exists.

**Resolution plan.** Correct counts and example; commit the diagram asset; add `LICENSE`; document the integration in `CLAUDE.md`. The ontology typo is deferred — renaming a class touches every subclass reference and is not worth the churn in M1. Recorded as accepted for now.

**Verification.** README example executes without error; counts match a programmatic census. See `TC-DOC-01`.

---

#### D17 · Relationships with missing endpoints are silently dropped

| Field | Value |
|---|---|
| **Severity** | S3 · **Status** Open · **Component** Princiv · pipeline |
| **Location** | `ingestion/pipeline.py:137-138` |
| **Violates** | API principle `AP-6` (Interface Design §4) · **Milestone** M4 |

**Description.** `_relationships_to_graph_rels` skips any accepted relationship whose endpoints are not both present in the entity map:

```python
if src is None or tgt is None:
    continue
```

No counter, no log, no signal. This is the only place in the pipeline where data disappears without being recorded.

**Impact.** Low in practice — endpoints are normally present, since relationships derive from the same entity list. But it violates the stated principle that nothing hidden succeeds, and if it ever fires at volume there would be no way to know.

**Detection.** Found while writing the Technical Design Document, not during the original repository review. **First defect added after the briefing** — evidence that writing the design surfaced something the code review did not.

**Resolution plan.** Add a counter to `PipelineResult` and log at `WARNING` with the offending references.

**Verification.** A test supplies a relationship with a dangling reference and asserts it is counted, not silently dropped. See `TC-PIPE-01`.

---

## 6. Accepted, not fixed

Recorded so that "not in the log" never means "not known."

| Item | Reason | Revisit |
|---|---|---|
| `:ConclussivePresumption` spelling (part of D16) | Renaming touches every subclass reference; churn outweighs benefit during M1 | If the ontology is substantially revised |
| No independent code review | No second contributor exists | If a contributor joins |
| No SSA domain expert review of modelled rules | No access to one | Before any user-facing release |
| Three of four Princiv test files auto-skip locally without Neo4j | Correct behaviour for local development; CI compensates via `NFR-25` | Only if CI coverage proves insufficient |

---

## 7. Adding a defect

1. Assign the next `D` number. Never reuse one.
2. Set severity by the §3 definitions — the S1 question is detectability, not consequence.
3. Record location as `file:line` against `main`.
4. Name the requirement or principle violated. If none applies, the finding may be a change request rather than a defect.
5. Assign a milestone. **An unassigned defect is not tracked** — if it does not fit a milestone, it belongs in §6 with a stated reason.
6. Write the verification step before writing the fix. If it cannot be expressed as an executable check, say so explicitly.
7. Update the §2 dashboard.

---

*Test cases referenced here are specified in [`10-test-cases.md`](10-test-cases.md).*
