# Test Cases

**Project:** Princiv — Legal Context Engine for Regulated AI Agents
**Document status:** Phase 2
**Companion documents:** [`09-test-plan.md`](09-test-plan.md) · [`11-defect-tracking-log.md`](11-defect-tracking-log.md) · [`../phase-1/05-software-requirements-spec.md`](../phase-1/05-software-requirements-spec.md)

---

## 1. How to use this document

Each case is written to be executable by someone with **no memory of writing it** — a deliberate response to the ~5 hrs/week cadence, where a case may first be run three weeks after it was specified.

**Format.** Level · what it traces to · milestone, then precondition, steps, and expected result.

**Traces** may reference an SRS requirement (`FR-*`, `NFR-*`, `IR-*`), a defect (`D*`), or a Charter success criterion (`S*`). A case with no trace should not exist.

**Status legend.** ✅ exists today · ○ to be written · ⚠ exists but currently fails

---

## 2. Environment — `TC-ENV`

#### TC-ENV-01 · Clean install produces a working environment
**Level** Integration · **Traces** D13, `NFR-22`, `S1` · **Milestone** M1 · **Status** ○

**Precondition.** A fresh virtualenv on Python 3.11+. Neither package installed. No `PYTHONPATH` set.
**Steps.**
1. `pip install -r requirements.txt`
2. `python -c "import layers.ingestion, layers.storage"`
3. `pytest --collect-only`

**Expected.** All three succeed. Collection reports a non-zero test count. No `PYTHONPATH` intervention was required at any point.

---

#### TC-ENV-02 · Engine installs standalone with no runtime dependencies
**Level** Integration · **Traces** `NFR-07`, `NFR-08`, `NFR-09` · **Milestone** M1 · **Status** ○

**Precondition.** Fresh virtualenv. Princiv not installed.
**Steps.** Install veridian-core alone; import every public module; inspect installed distributions.
**Expected.** Imports succeed. No third-party package was installed as a dependency — standard library only.

---

## 3. Continuous integration — `TC-CI`

#### TC-CI-01 · A broken commit fails CI in both repositories
**Level** Integration · **Traces** D15, `NFR-21` · **Milestone** M1 · **Status** ○

**Precondition.** CI workflows configured in both repositories.
**Steps.** On a scratch branch in each repo, introduce a deliberate failure (a syntax error, then separately a failing assertion). Push. Observe the workflow.
**Expected.** Both repositories report a failed run for both failure kinds. Revert and confirm green.

---

#### TC-CI-02 · CI fails rather than skips when the database is unreachable
**Level** Integration · **Traces** `NFR-25`, TR-1, TO-5 · **Milestone** M1 · **Status** ○

**Precondition.** Princiv CI workflow with a Neo4j service container and `PRINCIV_REQUIRE_DB=1`.
**Steps.** Temporarily point `NEO4J_URI` at an unreachable host. Push. Observe.
**Expected.** The run **fails**. It does not report success with skipped tests. Restore and confirm green with integration tests reported as run, not skipped.

> This case exists because a green build that skipped its integration tests is worse than a red one — it asserts confidence that was never earned.

---

## 4. Engine contracts — `TC-ENG`

#### TC-ENG-01 · The engine test suite collects and passes
**Level** Contract · **Traces** D12, `NFR-23`, `IR-11`, `S6` · **Milestone** M2 · **Status** ○

**Precondition.** `veridian-core/tests/` exists.
**Steps.** `pytest` from the engine repository root.
**Expected.** Collection reports a non-zero count. All pass. `testpaths` resolves to a directory that exists.

---

#### TC-ENG-02 · No abstraction remains without an implementation or a removal
**Level** Contract · **Traces** D14, `FR-ING-10`, `FR-ING-11` · **Milestone** M4 · **Status** ○

**Precondition.** M4 complete.
**Steps.** For each ABC in the engine, search both repositories for a concrete subclass.
**Expected.** Every ABC has at least one implementation, or has been removed. Specifically: `DocumentLoader` is implemented or deleted; `ExtractorRegistry` is used or deleted.

---

#### TC-ENG-03 · Abstract members are enforced
**Level** Contract · **Traces** `IR-01`, `IR-03` · **Milestone** M2 · **Status** ○

**Steps.** Define a subclass of `EntityExtractor` that implements only `extract_async`. Attempt to instantiate. Repeat for `GraphStore` with only `close` implemented.
**Expected.** Both raise `TypeError: Can't instantiate abstract class`.

> This is the exact failure the engine README's usage example would produce today (D16).

---

#### TC-ENG-04 · `extract_async` defaults to running `extract` off the event loop
**Level** Contract · **Traces** `IR-02` · **Milestone** M2 · **Status** ○

**Steps.** Define a synchronous-only extractor that records the thread it runs on. Await `extract_async` from an event loop.
**Expected.** Returns the same result as `extract`. Executes on a different thread from the loop.

---

#### TC-ENG-05 · The registry rejects a duplicate identifier
**Level** Contract · **Traces** `FR-ING-11` · **Milestone** M2 · **Status** ○

**Steps.** Register an extractor. Register a second with the same `extractor_id`. Then call `replace` with the same id.
**Expected.** The second `register` raises `ValueError`. `replace` succeeds and overwrites.

*Skip if `ExtractorRegistry` is removed under TC-ENG-02.*

---

#### TC-ENG-06 · The store works as an async context manager
**Level** Contract · **Traces** `IR-04` · **Milestone** M2 · **Status** ○

**Steps.** Use a fake `GraphStore` in `async with`. Exit normally, then exit via an exception.
**Expected.** `close()` is called exactly once in both cases.

---

## 5. Domain packs and conformance — `TC-PACK`

#### TC-PACK-01 · Manifest and graph schema agree in both directions
**Level** Conformance · **Traces** D4, `FR-PACK-04`, `FR-GRAPH-01` · **Milestone** M2 · **Status** ○

**Precondition.** SSA pack authored.
**Steps.** Parse `schema.cypher` for constrained labels. Compare against manifest entity names.
**Expected.** No manifest entity lacks a uniqueness constraint. No constrained label is absent from the manifest. Specifically `WorkLevel` and `EvaluationOutcome` appear in both.

---

#### TC-PACK-02 · Every manifest entity resolves to a declared OWL class
**Level** Conformance · **Traces** D3, D7, `FR-PACK-04`, `FR-ONT-07` · **Milestone** M2 · **Status** ○

**Steps.** Load the pack ontology. For each manifest entity, assert `ontology_class` is declared `owl:Class`.
**Expected.** All resolve. The `Case`/`CourtCase` ambiguity is gone — exactly one is declared and used. The occupation entity resolves to a single declared class used consistently by schema, seed data, and queries.

---

#### TC-PACK-03 · No manifest entry lacks a counterpart
**Level** Conformance · **Traces** D6, `FR-PACK-04` · **Milestone** M2 · **Status** ○

**Steps.** For each manifest relationship, confirm it is either allowlisted or resolves to a declared `owl:ObjectProperty`, and that it is referenced by seed data, a template, or the predicate map.
**Expected.** No orphaned entries. `CAUSES_SYMPTOM` and `RESTRICTS_TO_WORK_LEVEL` are absent or justified.

---

#### TC-PACK-04 · Declared pairings satisfy domain and range axioms
**Level** Conformance · **Traces** `FR-PACK-04`, `IR-08` · **Milestone** M2 · **Status** ○

**Steps.** For each relationship, check its declared `subject` against the property's `rdfs:domain` and `object` against `rdfs:range`, resolving `rdfs:subClassOf` and `owl:equivalentClass`.
**Expected.** All satisfy. Union-typed declarations resolve correctly.

---

#### TC-PACK-05 · Introduced drift fails conformance — **negative test**
**Level** Conformance · **Traces** `FR-PACK-05`, `S5`, TR-5 · **Milestone** M2 · **Status** ○

**Precondition.** Conformance passing on the SSA pack.
**Steps.** In a temporary copy, introduce each of these one at a time:
1. A manifest entity with no schema constraint
2. A manifest entity whose `ontology_class` is not declared
3. A relationship whose `subject` violates the property's domain
4. A schema constraint for a label absent from the manifest

Run conformance after each.
**Expected.** Each is detected, and the report names the specific offending entry. **No drift passes.**

> This is the single most important case in the document. A conformance check with no negative test is indistinguishable from a function that returns `True`. TDD §2.5 step 3 requires the check to fail on first run against the un-corrected manifest — if it passes immediately, it is not checking anything.

---

#### TC-PACK-06 · Conformance reports every violation, not just the first
**Level** Conformance · **Traces** `FR-PACK-06` · **Milestone** M2 · **Status** ○

**Steps.** Introduce three unrelated violations simultaneously. Run once.
**Expected.** All three appear in one report. The check does not short-circuit.

---

#### TC-PACK-07 · The engine contains no domain vocabulary
**Level** Unit · **Traces** `FR-PACK-03`, `S4`, `NFR-06` · **Milestone** M2 · **Status** ○

**Steps.** Search the engine source tree (excluding comments and git history) for `RFC`, `Listing`, `GridRule`, `SSR`, `MedicalCondition`, `Claimant`, `Occupation`, and every other SSA term in the manifest.
**Expected.** Zero matches. `EntityType` and `RelationshipType` no longer exist.

---

#### TC-PACK-08 · A second pack loads with zero engine changes
**Level** Conformance · **Traces** `S7`, `FR-PACK-08`, `NFR-06` · **Milestone** M3 · **Status** ○

**Precondition.** Engine at the commit that closed M2. Title IX pack authored.
**Steps.**
1. Load the Title IX pack.
2. Run conformance against it.
3. `git diff` the engine repository between the M2-close commit and now.

**Expected.** The pack loads and passes conformance. **The diff is empty.** Any engine change required is a finding that reopens M2 rather than something to patch.

---

#### TC-PACK-09 · Two packs coexist; one is active per run
**Level** Unit · **Traces** `FR-PACK-07` · **Milestone** M3 · **Status** ○

**Steps.** Load both packs into one process. Construct a pipeline with each in turn. Inspect the vocabulary each exposes.
**Expected.** Both load without interference. Each pipeline sees only its own pack's vocabulary. No global state leaks between them.

---

## 6. Ontology gate — `TC-VAL`

#### TC-VAL-01 · A valid triple is accepted
**Level** Unit · **Traces** `FR-VAL-01` · **Milestone** M1 · **Status** ✅

**Steps.** Construct `MedicalCondition —RESULTS_IN_LIMITATION→ FunctionalLimitation`. Validate.
**Expected.** Accepted. `accepted_count` 1, `rejected_count` 0.

---

#### TC-VAL-02 · An undeclared predicate is rejected
**Level** Unit · **Traces** `FR-VAL-02` · **Milestone** M1 · **Status** ✅

**Steps.** Validate a triple with an invented predicate.
**Expected.** Rejected with reason prefix `undeclared_predicate`.

---

#### TC-VAL-03 · An undeclared class is rejected even when the predicate is allowlisted
**Level** Unit · **Traces** D8, `FR-VAL-03` · **Milestone** M2 · **Status** ⚠

**Precondition.** Gate reordered per TDD §4.4 so allowlisting exempts only the property check.
**Steps.** Construct a triple whose predicate is allowlisted (`CITES`) but whose subject type is not a declared `owl:Class`. Validate.
**Expected.** Rejected with `invalid_subject_type`. **This currently passes incorrectly** — the allowlist returns before the class check, which is D8.

---

#### TC-VAL-04 · A domain violation is rejected
**Level** Unit · **Traces** `FR-VAL-04` · **Milestone** M1 · **Status** ✅

**Steps.** Use `Claimant` as subject of a property whose domain is `Impairment`.
**Expected.** Rejected with `domain_violation`.

---

#### TC-VAL-05 · A range violation is rejected
**Level** Unit · **Traces** `FR-VAL-05` · **Milestone** M1 · **Status** ✅

**Steps.** Use `Listing` as object of a property whose range is `FunctionalLimitation`.
**Expected.** Rejected with `range_violation`.

---

#### TC-VAL-06 · Subclass and equivalence are resolved
**Level** Unit · **Traces** `FR-VAL-04`, `FR-VAL-05` · **Milestone** M1 · **Status** ✅

**Steps.** Use `MedicalCondition` as subject of a property whose domain is declared `Impairment` — the two are `owl:equivalentClass`. Separately, use a subclass where its parent is declared.
**Expected.** Both accepted. Expansion walks `rdfs:subClassOf` and `owl:equivalentClass` in both directions.

---

#### TC-VAL-07 · Acronym property names resolve
**Level** Conformance · **Traces** D1, `FR-VAL-07`, `IR-09` · **Milestone** M1 · **Status** ⚠

**Steps.** For every relationship in the manifest, read its declared `ontology_property` and assert it is declared in the ontology.
**Expected.** All resolve, including `AFFECTS_RFC_COMPONENT → affectsRFCComponent`. **This currently fails** — derivation produces `affectsRfcComponent`, which is D1. After the fix, no name is derived by string transformation; every mapping is declared.

---

#### TC-VAL-08 · Metrics report counts and reasons
**Level** Unit · **Traces** `FR-VAL-08` · **Milestone** M1 · **Status** ✅

**Steps.** Validate a mixed batch of five valid and four invalid triples spanning at least three rejection reasons.
**Expected.** `accepted_count` 5, `rejected_count` 4, and `rejection_reasons` is a counter with the correct breakdown.

---

#### TC-VAL-09 · Rejected triples never reach storage
**Level** Unit · **Traces** `FR-VAL-09`, `NFR-02` · **Milestone** M1 · **Status** ✅

**Steps.** Run the pipeline with a store spy over a batch where every triple is invalid.
**Expected.** The store receives zero relationships. No partial write, no quarantine path.

---

#### TC-VAL-10 · Union-typed domains and ranges resolve
**Level** Unit · **Traces** `FR-VAL-06` · **Milestone** M1 · **Status** ✅

**Steps.** Validate triples using each member of an `owl:unionOf` domain declaration.
**Expected.** All accepted. The blank-node collection is walked correctly.

---

## 7. Extraction — `TC-ING`

#### TC-ING-01 · Entities carry confidence and source span
**Level** Unit · **Traces** `FR-ING-02`, `NFR-18` · **Milestone** M1 · **Status** ✅

**Steps.** Extract from a known sentence.
**Expected.** Each entity has a confidence in [0, 1] and a `SourceSpan` whose offsets, applied to the source text, return the entity's own text.

---

#### TC-ING-02 · NER labels come from the active pack
**Level** Unit · **Traces** `FR-ING-03`, `FR-PACK-02` · **Milestone** M2 · **Status** ○

**Steps.** Construct an extractor with a pack whose label map has been altered. Inspect the prompts passed to the model.
**Expected.** Prompts match the pack, not a module constant. Changing the pack changes the prompts with no code change.

---

#### TC-ING-03 · Entities are deduplicated within a document
**Level** Unit · **Traces** `FR-ING-06` · **Milestone** M1 · **Status** ✅

**Steps.** Extract from text mentioning the same condition three times.
**Expected.** One entity for that identifier. First occurrence retained.

---

#### TC-ING-04 · Extraction recall exceeds 90% on the reference set
**Level** Model · **Traces** `NFR-01`, `BM-1` · **Milestone** M1 · **Status** ✅

**Precondition.** GLiNER and spaCy installed. The 20-document reference set with its labelled mentions.
**Steps.** Extract from each document. A mention counts as found if any extracted entity text contains it, case-insensitively. Compute found ÷ expected.
**Expected.** Recall ≥ 0.90. Failure message reports the ratio and the count.

> Re-run whenever the extractor, the model checkpoint, or the pack's label map changes — a vocabulary change can move recall without any code change.

---

#### TC-ING-05 · The model loads lazily
**Level** Unit · **Traces** `NFR-13` · **Milestone** M1 · **Status** ○

**Steps.** Import the extractor module and construct an instance without calling `extract`. Observe whether a model download or load occurs.
**Expected.** No model is loaded. Loading happens on first extraction only.

---

## 8. Persistence — `TC-STORE`

#### TC-STORE-01 · Merge is idempotent
**Level** Integration · **Traces** `FR-STORE-01`, `NFR-04` · **Milestone** M1 · **Status** ○

**Precondition.** Neo4j reachable and empty.
**Steps.** Upsert the same batch of nodes and relationships three times. Count nodes and relationships after each.
**Expected.** Counts identical after runs 1, 2, and 3. Properties reflect the last write.

---

#### TC-STORE-02 · A batch rolls back entirely on failure
**Level** Integration · **Traces** `FR-STORE-03` · **Milestone** M4 · **Status** ○

**Steps.** Submit a batch whose final relationship references a non-existent endpoint. Count nodes before and after.
**Expected.** Counts unchanged. No node from the batch persists. The failure surfaces rather than being swallowed.

---

#### TC-STORE-03 · Nodes are written before relationships
**Level** Integration · **Traces** `FR-STORE-02` · **Milestone** M1 · **Status** ○

**Steps.** Submit a batch where every relationship's endpoints are created in the same batch.
**Expected.** The batch succeeds. Ordering guarantees endpoints exist when relationships are written.

---

#### TC-STORE-04 · A missing endpoint raises
**Level** Integration · **Traces** D9, `FR-STORE-04` · **Milestone** M4 · **Status** ⚠

**Steps.** Call `upsert_relationship` where the source node does not exist.
**Expected.** Raises `MissingEndpointError` naming both endpoints. **Currently returns `WriteResult(created=False)`** — a silent no-op, which is D9.

---

#### TC-STORE-05 · Created and merged counts are accurate
**Level** Integration · **Traces** D9, `FR-STORE-05` · **Milestone** M4 · **Status** ⚠

**Steps.** Against an empty graph, upsert three nodes and two relationships. Repeat the identical batch. Inspect `BatchWriteResult` both times.
**Expected.** First run reports 3 created / 0 merged, 2 created / 0 merged. Second reports 0 created / 3 merged, 0 created / 2 merged. **Currently everything is tallied as merged**, which is D9.

*If the extra lookup proves too costly at batch scale, the interface drops the four-counter breakdown rather than reporting numbers that are false — in which case this case is rewritten to assert the reduced contract.*

---

#### TC-STORE-06 · Out-of-vocabulary labels and relationship types raise
**Level** Unit · **Traces** D10, `FR-STORE-06` · **Milestone** M4 · **Status** ⚠

**Steps.** Attempt to upsert a node whose label is a valid identifier but absent from the pack vocabulary. Separately, a relationship whose type is absent from the pack.
**Expected.** Both raise `ValueError`. **Currently the label passes** — the guard's disjunction with a permissive regex makes the allowlist unreachable — and the relationship type is not validated at all. That is D10.

---

#### TC-STORE-07 · Every write emits an audit record
**Level** Integration · **Traces** `FR-STORE-07`, `NFR-15`, `NFR-16` · **Milestone** M1 · **Status** ○

**Steps.** Capture log output while upserting a batch. Parse each record as JSON.
**Expected.** One record per write, each parseable, each containing `action`, `label`, `entity_id`, `created`, and an ISO-8601 `ts`.

---

#### TC-STORE-08 · No untyped node exists after a run
**Level** Integration · **Traces** `NFR-03`, `FR-STORE-08`, `BM-3` · **Milestone** M4 · **Status** ○

**Steps.** After a full pipeline run, query for nodes carrying no label, and for nodes whose label is absent from the pack vocabulary.
**Expected.** Both return zero.

---

## 9. Query — `TC-QRY`

#### TC-QRY-01 · Grid Rule lookup resolves through the composite index
**Level** Integration · **Traces** `FR-QRY-01`, `NFR-12` · **Milestone** M1 · **Status** ✅

**Steps.** Run `GRID_RULE_LOOKUP` with all four vocational factors. Run `EXPLAIN` on the same query.
**Expected.** Returns the expected rule with `rule_number`, `decision`, `outcome`, and `cfr_cite`. The plan shows an index seek on the composite index, not a label scan.

---

#### TC-QRY-02 · Step 5 returns extracted occupations
**Level** Integration · **Traces** D3, `FR-QRY-02` · **Milestone** M4 · **Status** ⚠

**Steps.** Ingest a document mentioning a DOT occupation. Run `STEP5_OTHER_WORK` for the matching work level.
**Expected.** The extracted occupation appears in the results. **Currently it does not** — extraction writes `Occupation` while the query reads `DOTOccupation`, which is D3.

---

#### TC-QRY-03 · The step router returns only changed state
**Level** Unit · **Traces** `FR-QRY-06` · **Milestone** M1 · **Status** ✅

**Steps.** Invoke the router with a mock driver and a known state. Inspect the returned keys.
**Expected.** Only changed keys are present. Merging into the prior state yields a correct full state.

---

#### TC-QRY-04 · The step router detects a terminal outcome
**Level** Integration · **Traces** `FR-QRY-07` · **Milestone** M1 · **Status** ✅

**Steps.** Traverse to a step whose branch leads to an `EvaluationOutcome`.
**Expected.** `is_terminal` true, `active_step` `None`, `disposition` set to the outcome's result.

---

#### TC-QRY-05 · The step router raises on a missing branch
**Level** Unit · **Traces** `FR-QRY-08` · **Milestone** M1 · **Status** ✅

**Steps.** Invoke with a step id that has no matching branch edge. Separately, invoke with an answer outside `{yes, no}` and with `active_step` absent.
**Expected.** `LookupError` naming the step and the likely cause for the first; `ValueError` for the other two.

---

#### TC-QRY-06 · Results carry citations
**Level** Integration · **Traces** `FR-QRY-09`, `BC-6`, `BM-6` · **Milestone** M4 · **Status** ○

**Steps.** Run each query template that returns a legal conclusion. Inspect the returned columns.
**Expected.** Every such result includes a citation field, populated and non-empty. No conclusion is returned without its authority.

---

## 10. Pipeline — `TC-PIPE`

#### TC-PIPE-01 · A dangling relationship is counted, not silently dropped
**Level** Unit · **Traces** D17, `AP-6` · **Milestone** M4 · **Status** ⚠

**Steps.** Supply an accepted relationship whose `source_ref` matches no extracted entity. Run the conversion. Inspect `PipelineResult` and captured logs.
**Expected.** The relationship is excluded from the write **and** counted in a dropped-reference counter, with a `WARNING` naming the reference. **Currently it is dropped with no signal**, which is D17.

---

#### TC-PIPE-02 · Results aggregate across documents
**Level** Unit · **Traces** `FR-ING-01` · **Milestone** M1 · **Status** ○

**Steps.** Run the pipeline over three documents with a store spy.
**Expected.** `documents_processed` 3. Entity, relationship, accepted, rejected, and written counts are sums across all three. Rejection reasons merge into one counter.

---

## 11. End to end — `TC-E2E`

#### TC-E2E-01 · A document becomes an answerable question
**Level** End-to-end · **Traces** D2, `S8`, `FR-QRY-04`, `BM-7` · **Milestone** M4 · **Status** ⚠

**Precondition.** Neo4j reachable. SSA pack active. Graph seeded with the evaluation steps and Grid Rules.
**Steps.**
1. Ingest a document describing a medical condition and its functional limitations.
2. Confirm the entities and relationships were written.
3. Run `MEDEVOC_CHAIN` for that condition.

**Expected.** A non-empty result tracing condition → limitation → RFC component → work level → Grid Rule → outcome, built from **ingested** data rather than seed data.

> **The MVP's headline claim.** It currently fails: four of the chain's five hops have no vocabulary entry, and the extractor emits differently-named near-synonyms for two of them. That is D2, and this case is how its fix is verified.

---

## 12. Data hygiene — `TC-DATA`

#### TC-DATA-01 · No contract-law data remains
**Level** Integration · **Traces** D11, `S3`, `FR-GRAPH-08` · **Milestone** M1 · **Status** ○

**Steps.** Search the working tree (excluding `.git`) for `unconscionab`, `Concepcion`, `Armendariz`, `contract formation`. Seed a fresh graph and run the validation suite.
**Expected.** Zero matches. The validation suite passes with no query referencing contract law. `CLAUDE.md` describes the actual post-seed state.

---

#### TC-DATA-02 · Seed loaders fail visibly when run out of order
**Level** Integration · **Traces** D18, `NFR-26` · **Milestone** M1 · **Status** ○

**Precondition.** Neo4j reachable and empty. Schema applied.
**Steps.**
1. Load `load_grid_rules_and_occupations.cypher` **before** `load_mvp_regulatory_content.cypher`.
2. Query for `GOVERNS` edges from `WorkLevel` and `RESULTS_IN_DECISION` edges to `EvaluationOutcome`.
3. Run the validation queries.
4. Reset. Load in the correct order — evaluation steps, regulatory content, grid rules. Repeat steps 2 and 3.

**Expected.** The wrong order produces zero `GOVERNS` and zero `RESULTS_IN_DECISION` edges, and the validation queries **fail**. The correct order produces both edge sets and the validation queries pass.

> The point of this case is that the wrong order currently produces *no error at all* — `MATCH` finds nothing, `MERGE` never runs, loading reports success. The test makes that silence detectable.

---

## 13. Documentation — `TC-DOC`

#### TC-DOC-01 · Documented counts and examples are correct
**Level** Unit · **Traces** D16, `NFR-26` · **Milestone** M1 · **Status** ○

**Steps.** Execute the engine README's usage example verbatim. Programmatically count entity and relationship types and compare against the documented figures. Confirm the architecture diagram resolves from a fresh clone. Confirm `LICENSE` exists.
**Expected.** The example runs without error. Counts match. The diagram resolves. The licence file exists and matches the claim.

---

## 14. Traceability

### 14.1 Charter success criteria

Every criterion has at least one case.

| Criterion | Cases | Milestone |
|---|---|---|
| **S1** Clean install works | TC-ENV-01, TC-ENV-02 | M1 |
| **S2** CI green both repos | TC-CI-01, TC-CI-02 | M1 |
| **S3** Contract-law data removed | TC-DATA-01 | M1 |
| **S4** No SSA terms in the engine | TC-PACK-07 | M2 |
| **S5** Drift fails conformance | TC-PACK-05, TC-PACK-06 | M2 |
| **S6** Engine suite passes | TC-ENG-01 | M2 |
| **S7** Second pack loads unchanged | TC-PACK-08, TC-PACK-09 | M3 |
| **S8** Chain traverses ingested data | TC-E2E-01 | M4 |
| **S9** Store contract honoured | TC-STORE-04, TC-STORE-05, TC-STORE-06 | M4 |

### 14.2 Defects

Every S1 and S2 defect has a regression case, per `TO-2`.

| Defect | Severity | Case | Milestone |
|---|---|---|---|
| D1 | S1 | TC-VAL-07 | M1 |
| D2 | S1 | TC-E2E-01 | M4 |
| D3 | S1 | TC-PACK-02, TC-QRY-02 | M4 |
| D4 | S2 | TC-PACK-01 | M2 |
| D5 | S2 | TC-E2E-01 | M4 |
| D6 | S2 | TC-PACK-03 | M2 |
| D7 | S2 | TC-PACK-02 | M2 |
| D8 | S2 | TC-VAL-03 | M2 |
| D9 | S2 | TC-STORE-04, TC-STORE-05 | M4 |
| D10 | S2 | TC-STORE-06 | M4 |
| D11 | S3 | TC-DATA-01 | M1 |
| D12 | S3 | TC-ENG-01 | M2 |
| D13 | S3 | TC-ENV-01 | M1 |
| D14 | S3 | TC-ENG-02 | M4 |
| D15 | S3 | TC-CI-01 | M1 |
| D16 | S3 | TC-DOC-01, TC-ENG-03 | M1 |
| D17 | S3 | TC-PIPE-01 | M4 |
| D18 | S2 | TC-DATA-02 | M1 |

### 14.3 Summary

| Status | Count |
|---|---|
| ✅ Exist today and pass | 15 |
| ⚠ Exist but currently fail | 8 |
| ○ To be written | 31 |
| **Total** | **54** |

| Milestone | Cases |
|---|---|
| M1 | 28 |
| M2 | 14 |
| M3 | 2 |
| M4 | 10 |
| **Total** | **54** |

Two things are worth reading off these numbers.

**The eight failing cases are the S1 and S2 defects, written as tests.** They are specified before their fixes exist, which is deliberate — per Test Plan §8, a test written before the fix verifies the *defect*, and that is what proves the test checks something real.

**M1 carries 28 cases, more than any other milestone.** That is not because M1 does the most work — it does the least. It is because M1 establishes CI and the environment, and most existing behaviour gets its first test there. The effort is in wiring, not in authoring 27 novel cases.

---

## 15. Approval

| Role | Name | Date | Status |
|---|---|---|---|
| Project sponsor | Jeremy Jones | | Pending |

---

*Next in Phase 2: Deployment Plan, then Release Notes and user guides post-MVP.*
