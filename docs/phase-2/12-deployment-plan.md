# Deployment Plan

**Project:** Princiv — Legal Context Engine for Regulated AI Agents
**Document status:** Phase 2
**Companion documents:** [`09-test-plan.md`](09-test-plan.md) · [`11-defect-tracking-log.md`](11-defect-tracking-log.md) · [`../phase-1/06-system-architecture-document.md`](../phase-1/06-system-architecture-document.md)

---

## 1. Scope, and what this document is not

**There is no hosted service and there are no users.** The MVP is an engine consumed in-process by a developer on a local machine (Charter §3.1). Nothing is served over a network, nothing is multi-tenant, and no data belongs to anyone but the contributor.

So this document is deliberately narrow. It covers three things that genuinely need a defined procedure:

| Covered | Why it needs a plan |
|---|---|
| **Graph lifecycle** | The graph is rebuilt often — after schema changes, pack changes, and failed ingestion runs. An undefined rebuild sequence produces inconsistent state |
| **CI pipeline** | The only mechanical check available with no reviewer (`NFR-21`, `NFR-25`) |
| **Version and dependency pinning** | D13 exists because this was never defined |

**Not covered, because it does not exist:** hosted infrastructure, containers in production, load balancing, authentication, secrets management, database backup policy, zero-downtime strategy, or a data-protection posture. §8 records what a future hosted deployment would need, so the gap is documented rather than implied.

**Step-by-step setup instructions are not here.** Those belong in the installation guide (`14-user-guides.md`, pending — delivered in M1). This document defines the *sequence and strategy*; the guide defines the keystrokes.

---

## 2. Environments

| Environment | Purpose | Composition |
|---|---|---|
| **Local — no database** | Writing code; fast feedback | Python 3.11+, both packages installed editable. Database tests skip with a visible message |
| **Local — with database** | Integration and ingestion work | Adds Neo4j at `bolt://localhost:7687`; optionally Fuseki for SPARQL validation |
| **CI** | Merge gate | GitHub Actions. Princiv runs a Neo4j service container; Veridian Core needs no services |

No staging environment. With one contributor and no production, a staging tier would be ceremony with no function.

---

## 3. Graph lifecycle

The graph is **derived state.** Everything in it comes from version-controlled Cypher plus ingested documents. That single property is what makes the rest of this document short: the graph is never the authoritative copy of anything, so it can always be discarded and rebuilt.

### 3.1 Initialisation — current

```cypher
:source graph/schema.cypher
:source graph/seed_data/load_evaluation_steps.cypher
:source graph/seed_data/load_mvp_regulatory_content.cypher
:source graph/seed_data/load_grid_rules_and_occupations.cypher
:source graph/validation_queries.cypher
```

> **This differs from `CLAUDE.md`.** That file's sequence loads `load_seed_data.cypher` — 597 lines of California contract law — and documents the resulting contract-law state as the expected baseline. That is D11. The sequence above is the correct one for the SSDI domain. `CLAUDE.md` is corrected in M1.

### 3.1.1 Why this order, specifically

The seed loaders have a real dependency order that is **documented nowhere in the repository** and is not obvious from the filenames. It was established by tracing which loader creates each label and which consumes it:

| Label | Created by | Consumed by |
|---|---|---|
| `EvaluationOutcome` | `load_evaluation_steps` (2 nodes) | `load_mvp_regulatory_content` (4 MATCH), `load_grid_rules_and_occupations` (2 MATCH) |
| `WorkLevel` | `load_mvp_regulatory_content` (5 nodes) | `load_grid_rules_and_occupations` (7 MATCH) |
| `GridRule` | Both, over **disjoint** id sets | Each file matches only its own |

So the order is forced: **evaluation steps → regulatory content → grid rules.** `load_grid_rules_and_occupations` runs last because it is the only pure consumer of `WorkLevel`.

Constraints must also precede all data, or uniqueness is not enforced during load.

**Getting this wrong fails silently.** The dependent clauses are all `MATCH … MERGE`. A `MATCH` that finds nothing yields zero rows, so the `MERGE` simply does not execute — no error, no warning. Loading `load_grid_rules_and_occupations` before `load_mvp_regulatory_content` produces a graph that looks populated but has no `GOVERNS` edges from `WorkLevel` and no `RESULTS_IN_DECISION` edges to `EvaluationOutcome`. Those are precisely the hops the Step 5 queries traverse.

This is recorded as **D18**.

### 3.2 Initialisation — after M2 **[TARGET]**

Once packs exist, initialisation is pack-driven:

```
1. Load the active pack               -> validates the manifest
2. Run conformance                    -> aborts on any drift
3. Apply pack schema                  -> constraints and indexes
4. Apply pack seed data, in order     -> domain content
5. Run validation queries             -> confirm expected counts
```

**Conformance runs before anything touches the database.** A pack whose manifest disagrees with its schema would create constraints that the vocabulary cannot satisfy — cheaper to catch before the write than after.

### 3.3 Reset

```cypher
MATCH (n) DETACH DELETE n;
SHOW CONSTRAINTS;   // drop each
SHOW INDEXES;       // drop each
```

Then re-initialise per §3.1.

Dropping constraints and indexes matters. `CREATE CONSTRAINT … IF NOT EXISTS` is a no-op against an existing constraint, so a reset that only deletes nodes leaves stale constraints behind — including any belonging to a pack no longer in use.

### 3.4 When a rebuild is required

| Trigger | Reason |
|---|---|
| Schema change | Constraints and indexes are not retroactive |
| Pack change | Vocabulary change may invalidate stored labels |
| Ontology change affecting domain/range | Previously-valid triples may no longer validate |
| Failed ingestion run | Batches are atomic, but a multi-document run can fail partway |
| Switching active pack | Two packs' data should not share a graph in the MVP |

---

## 4. Release sequence

A "release" in the MVP is a milestone closing and merging to `main`. There is nothing to deploy — the release is the merge.

| Step | Action | Gate |
|---|---|---|
| 1 | All milestone work items complete or deferred with a change-log entry | Test Plan E1 |
| 2 | All milestone exit criteria objectively verified | Test Plan E2 |
| 3 | All milestone defects at **Verified**, not merely Fixed | Test Plan E3 |
| 4 | CI green on both repositories | Test Plan E5 |
| 5 | Rebuild the graph from clean; validation queries pass | §3.3, §3.1 |
| 6 | Merge to `main` in both repositories | — |
| 7 | Tag veridian-core; update Princiv's pin (§6) | — |
| 8 | Update the defect log dashboard | Test Plan E6 |
| 9 | Write release notes for the milestone | `13-release-notes.md` (pending) |

**Step 5 is the one most easily skipped.** Tests passing against a graph that accumulated state over weeks of development is not the same as tests passing against a graph built from scratch. The difference is where "works on my machine" comes from.

**Step 7 is ordered deliberately.** Veridian Core is tagged *before* Princiv's pin is updated, because the pin must reference a tag that exists.

---

## 5. Rollback

Rollback is straightforward precisely because the graph is derived state (§3).

| Failure | Response |
|---|---|
| Bad merge to `main` | `git revert` the merge commit. Both repositories independently |
| Graph in a bad state | Reset (§3.3) and re-initialise. No backup needed — nothing unique lives there |
| Pack change broke conformance | Revert the manifest; conformance blocks the merge before this reaches `main` |
| Ingestion produced wrong data | Reset the graph, fix the extractor or pack, re-ingest |
| Engine tag broken | Repin Princiv to the prior tag; fix forward |

**No rollback window and no data-loss risk.** Every graph state is reproducible from version-controlled inputs. The only irreplaceable artifacts are the repositories themselves, which are on GitHub.

This changes the moment real user data enters the system. §8 records that.

---

## 6. Versioning and pinning

### 6.1 Veridian Core

Semantic versioning, tagged on each milestone close. Princiv pins to a **tag or commit SHA — never a branch**.

D13 exists because the current pin, in a commented-out line, targets a merged feature branch. A branch pin is a moving reference that can be deleted; a tag is not.

```
veridian-core @ git+https://github.com/jerameee/veridian-core.git@v0.2.0
```

| Change | Version bump |
|---|---|
| Interface contract change | Major |
| New abstraction or capability | Minor |
| Fix with no contract change | Patch |

Removing `EntityType` and `RelationshipType` in M2 is a breaking interface change — `v1.0.0` would be appropriate were the project not pre-1.0. It closes M2 as `v0.2.0` with the break recorded in release notes.

### 6.2 Domain packs

Each pack carries its own version in `pack.yaml` (TDD §2.2). Packs version independently of the engine — a vocabulary correction does not require an engine release.

`FR-PACK-09` (declaring the engine version a pack targets) is Phase 2 and unbuilt. Until it exists, engine/pack compatibility is unenforced. Worth knowing; not worth building before a third pack exists.

### 6.3 Python dependencies

Pinned in `requirements.txt` with lower bounds at minimum, exact pins for anything that has broken before. GLiNER, spaCy, and torch move quickly and have already caused a version conflict during setup — those get exact pins.

---

## 7. CI pipeline

| Repository | Steps |
|---|---|
| **Veridian Core** | Checkout → Python 3.11 → install `.[dev]` → lint → `pytest` → import check |
| **Princiv** | Checkout → Python 3.11 → **start Neo4j service container** → install requirements + engine → lint → `pytest` with `PRINCIV_REQUIRE_DB=1` → conformance check → import check |

### 7.1 Two non-negotiables

**`PRINCIV_REQUIRE_DB=1` turns an unreachable database into a failure rather than a skip.** Three of four Princiv test files auto-skip without Neo4j. Correct locally; catastrophic in CI, where a green build would mean the integration tests never ran. `TC-CI-02` verifies this.

**Conformance is a blocking step, not advisory.** It is the mechanism that closes D1 through D8. A conformance check that warns rather than fails is a conformance check that will eventually be ignored.

### 7.2 Caching

The GLiNER model is several hundred megabytes. CI caches it between runs keyed on the checkpoint name. Without caching, recall tests would dominate CI time and would end up being disabled — which is how `NFR-01` stops being enforced.

---

## 8. What a hosted deployment would require **[FUTURE]**

Out of scope. Recorded so the gap is explicit rather than discovered later.

| Concern | Status |
|---|---|
| Containerisation | Not started |
| Managed Neo4j | Not evaluated |
| API gateway, authentication | No public API exists (`FR-QRY-12`, Future) |
| Secrets management | Environment variables only; sufficient for local |
| Backup and restore | **Unnecessary today** — graph is derived state. **Mandatory** once claimant data exists |
| Data protection posture | None. Would become a prerequisite the moment real claim data is handled |
| Monitoring, alerting | None |
| Migration strategy | Rebuild-from-source works only while the graph holds no unique data |

**Two of these change character rather than merely appearing.** Backup and migration are genuinely unnecessary now because nothing in the graph is irreplaceable. The moment a claimant's data is stored, rebuild-from-source stops being a valid rollback and both become hard requirements. That transition is a prerequisite of `BC-12`, not an afterthought to it.

---

## 9. Approval

| Role | Name | Date | Status |
|---|---|---|---|
| Project sponsor | Jeremy Jones | | Pending |

---

*Remaining in Phase 2: `13-release-notes.md` and `14-user-guides.md` — the installation guide in M1, the rest post-MVP.*
