# Test Plan

**Project:** Princiv — Legal Context Engine for Regulated AI Agents
**Document status:** Phase 2
**Companion documents:** [`10-test-cases.md`](10-test-cases.md) · [`11-defect-tracking-log.md`](11-defect-tracking-log.md) · [`../phase-1/05-software-requirements-spec.md`](../phase-1/05-software-requirements-spec.md)

---

## 1. Purpose and scope

This plan defines how the MVP is verified: what is tested, at which level, in which environment, and what must hold before a milestone closes.

It covers the MVP defined in Charter §3.1 — the domain-pack refactor, the Title IX pluggability proof, and one working vertical slice. It does not cover anything marked Future in the SRS.

### 1.1 The governing constraint

One contributor, no independent reviewer, ~5 hrs/week.

That single fact shapes every decision here. There is no QA function, no second pair of eyes, and no one to catch a mistake in the tests themselves. **Testing is the substitute for review, not a supplement to it.** Where a conventional plan might rely on inspection or judgement, this one requires an executable check — because a judgement made by the person who wrote the code is not an independent check.

---

## 2. Test objectives

| # | Objective | Measure |
|---|---|---|
| **TO-1** | Every Charter success criterion is demonstrated by a passing test | S1–S9 each map to at least one test case |
| **TO-2** | Every S1 and S2 defect has a regression test before it is marked Verified | 10 of 10 |
| **TO-3** | Vocabulary drift cannot reach `main` undetected | Conformance check runs in CI and blocks merge |
| **TO-4** | Engine interface contracts are verified in the engine repository | Contract test per abstract method |
| **TO-5** | A green CI run means something | CI exercises the database path; it does not skip it |

**TO-5 deserves emphasis.** Three of four Princiv test files auto-skip when Neo4j is unreachable. That is correct locally and dangerous in CI — a green build that skipped its integration tests is worse than a red one, because it asserts confidence that was never earned.

---

## 3. Test levels

| Level | Scope | Runs | Requires DB |
|---|---|---|---|
| **Unit** | Single function or class; mocked collaborators | Every commit, locally and in CI | No |
| **Contract** | An ABC's documented behaviour, against a fake implementation | Every commit | No |
| **Conformance** | Manifest ↔ schema ↔ ontology agreement, per pack | Every commit | No |
| **Integration** | Real Neo4j; real Cypher | CI always; locally when available | Yes |
| **Model** | Extraction recall against the reference document set | Milestone boundaries, and on extractor change | No (needs GLiNER) |
| **End-to-end** | Document in, queryable answer out | Milestone boundaries | Yes |

### 3.1 Level rationale

**Contract tests live in the engine repository, not in Princiv.** D9 exists because `Neo4jGraphStore` violates a contract nothing checked. The contract belongs to the engine, so its test does too — otherwise a second consumer would have to rediscover the same requirements.

**Conformance is its own level.** It is not a unit test (it reads three files and compares them) and not an integration test (it touches no service). It is the mechanism that closes D1–D8, and treating it as a first-class level keeps it from being quietly downgraded.

**Model tests are slow and separate.** Extraction recall requires downloading and running GLiNER. Running it per commit would make the suite unusable at 5 hrs/week, so it runs at milestone boundaries and whenever the extractor or vocabulary changes.

---

## 4. Test environments

| Environment | Purpose | Composition |
|---|---|---|
| **Local — no database** | Fast feedback while writing code | Python 3.11+, both packages installed editable. DB tests skip with a visible message |
| **Local — with database** | Integration work | Adds local Neo4j at `bolt://localhost:7687` |
| **CI — Princiv** | Gate on merge | GitHub Actions, **Neo4j service container**, GLiNER cached between runs |
| **CI — Veridian Core** | Gate on merge | GitHub Actions, no services needed — the engine has no runtime dependencies |

### 4.1 Configuration

| Variable | Default |
|---|---|
| `NEO4J_URI` | `bolt://localhost:7687` |
| `NEO4J_USER` | `neo4j` |
| `NEO4J_PASS` | `neo4j` |

No credentials in source. CI supplies its own for the service container.

### 4.2 The skip policy

Locally, database tests skip when Neo4j is unreachable, with a message naming what was skipped and why.

**In CI they must not skip.** The CI workflow sets a marker (`PRINCIV_REQUIRE_DB=1`) that turns an unreachable database into a failure rather than a skip. Without this, `NFR-25` is unenforceable and TO-5 fails silently.

---

## 5. Coverage

### 5.1 What is tested

| Area | Level | Rationale |
|---|---|---|
| Ontology gate decision logic | Unit, table-driven | The correctness boundary. One case per rejection reason, plus subclass and equivalence acceptance |
| Pack loading and conformance | Conformance | Closes D1–D8. Includes a **negative test** that introduces drift |
| Engine ABC contracts | Contract | Closes D12; prevents the next D9 |
| Store merge semantics | Integration | Idempotency and transactionality cannot be verified against a mock |
| Query templates | Integration | Cypher correctness needs real Cypher |
| Step router traversal | Unit (mock driver) + integration | Logic is mockable; traversal is not |
| Extraction recall | Model | `NFR-01`, the one numeric quality bar that exists |
| Full pipeline | End-to-end | `S8` — the MVP's headline claim |

### 5.2 What is not tested, and why

Stated explicitly so that absence is a decision rather than an oversight.

| Not tested | Reason |
|---|---|
| **Legal accuracy of modelled rules** | No domain expert available (`BCN-4`). Every rule carries its citation, but nobody qualified has verified the modelling is right. **This is the largest untested risk in the project** |
| Performance under load | No users, no baseline. `NFR-14` defers numeric targets |
| Concurrent pipeline runs | Single-writer by design (SAD §8.4). Untested because unsupported |
| GLiNER model internals | Third-party. Tested through recall, not directly |
| Neo4j itself | Third-party |
| Future-phase requirements | Not built |

### 5.3 Coverage targets

No line-coverage percentage is set.

A percentage target on a codebase this size would drive tests toward whatever is easy to cover rather than what matters, and there is no reviewer to notice that happening. **Coverage is defined by requirement instead:** every MVP-phase requirement with status ○ or ⚠ in the SRS must have a test case before it can be marked ✅, and every S1/S2 defect must have a regression test before it moves to Verified.

That is a stronger guarantee than a percentage, and it is checkable by reading the traceability table in `10-test-cases.md`.

---

## 6. Entry and exit criteria

### 6.1 Per milestone

A milestone may close only when all of the following hold.

| # | Criterion |
|---|---|
| **E1** | Every work item is complete, or deferred with a PM Plan change-log entry |
| **E2** | Every milestone exit criterion in Charter §5 is objectively verified — the command run, the output observed |
| **E3** | Every defect assigned to the milestone is **Verified**, not merely Fixed |
| **E4** | Every new or changed requirement has a test case |
| **E5** | CI is green on both repositories |
| **E6** | The defect log dashboard is current |

**E3 is the one most likely to be skipped under time pressure**, and the one that matters most. "Fixed" means a change was made. "Verified" means a test proves it. With no reviewer, that distinction is the entire quality system.

### 6.2 MVP exit

All nine Charter success criteria (S1–S9) demonstrated by passing tests, and no S1 or S2 defect in any state other than Verified.

---

## 7. Milestone test focus

| Milestone | Primary test activity | Defects verified |
|---|---|---|
| **M1** Foundation & Hygiene | Establish CI in both repos; clean-environment install test; D1 regression test | D1, D11, D13, D15, D16 |
| **M2** Domain-Pack Refactor | Conformance suite including the negative drift test; engine contract tests | D4, D6, D7, D8, D12 |
| **M3** Title IX Validation | Second-pack conformance; assert zero engine changes were required | — |
| **M4** Working Vertical Slice | Store contract tests; end-to-end pipeline test | D2, D3, D5, D9, D10, D14, D17 |

M3 has no defects assigned because it introduces no code — it is a test of work already done. **If M3 requires an engine change, that is itself a finding**: it means the M2 abstraction was incomplete, and it reopens M2 rather than being patched in place.

---

## 8. Defect management

Defects are recorded in [`11-defect-tracking-log.md`](11-defect-tracking-log.md), which is the authoritative register and supersedes Part VIII of the technical briefing.

| Step | Action |
|---|---|
| Found | Record with severity, location, requirement violated, milestone |
| Before fixing | Write a failing test that reproduces it |
| Fixed | Commit; status → Fixed |
| Verified | Test passes; status → Verified |
| Not fixing | Move to §6 of the log with a stated reason and a PM Plan change-log entry |

**The failing test comes first for S1 and S2 defects.** A test written after the fix verifies the fix; a test written before verifies the *defect*, which is what proves the test is actually checking something. D1 is the clearest case — the conformance check must fail on first run, or it is not checking anything (TDD §2.5, step 3).

---

## 9. Tooling

| Tool | Use |
|---|---|
| `pytest` | All levels |
| `pytest-asyncio` | Async store tests (`asyncio_mode = "auto"`) |
| GitHub Actions | CI in both repositories |
| Neo4j service container | CI integration environment |
| `rdflib` | Ontology loading in conformance and gate tests |
| Existing SPARQL suite | `ontology/tests/run_sparql_tests.sh` — ontology structure |
| Existing consistency check | `ontology/tests/consistency_check.sh` — OWL DL consistency |

No new test framework is introduced. The existing shell-based ontology suite is retained and wired into CI rather than rewritten — it works, and rewriting it would consume milestone budget for no gain.

---

## 10. Risks to testing

| # | Risk | Mitigation |
|---|---|---|
| **TR-1** | CI passes while skipping database tests | `PRINCIV_REQUIRE_DB=1` turns a skip into a failure (§4.2). Verified by `TC-CI-02` |
| **TR-2** | Tests written by the author encode the author's misunderstanding | Partly unmitigable. Conformance and contract tests check against *declared* specifications rather than intent, which narrows the gap |
| **TR-3** | Model tests too slow to run, so they stop being run | Run at milestone boundaries, not per commit. Cache the model in CI |
| **TR-4** | Legal modelling errors reach a release | **Unmitigated.** No expert review available. Recorded in the log §6 and the PM Plan risk register as accepted |
| **TR-5** | The conformance check passes vacuously | Mandatory negative test (`TC-PACK-05`). A conformance check with no negative test is indistinguishable from `return True` |
| **TR-6** | A three-week gap loses test context | Test cases in `10-test-cases.md` are written to be executable by someone with no memory of writing them |

---

## 11. Approval

| Role | Name | Date | Status |
|---|---|---|---|
| Project sponsor | Jeremy Jones | | Pending |

---

*Next: [`10-test-cases.md`](10-test-cases.md)*
