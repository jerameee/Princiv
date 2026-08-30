# Project Charter

**Project:** Princiv — Legal Context Engine for Regulated AI Agents
**Platform component:** Veridian Core — reusable ingestion and storage layer
**Document status:** Phase 1, Set A
**Prerequisite reading:** [`../00-technical-briefing.md`](../00-technical-briefing.md)

---

## 1. Purpose and justification

### 1.1 Why this project exists

General-purpose language models reason about regulated law in ways that fail quietly. They fabricate citations that look correct, apply a superseded version of a regulation without noticing, treat a rebuttable presumption as though it were conclusive, and cannot reliably rank binding authority against persuasive commentary. In a regulated domain, a confident wrong answer is more dangerous than no answer, because nothing signals that verification is needed.

Retrieval-augmented generation reduces fabrication but does not address the underlying problem. Retrieval surfaces *text*; the failures above are failures of *structure*. No amount of retrieved text tells a model that Step 3 of the SSA sequential evaluation terminates the analysis when a Listing is met, or that the governing version of a Listing depends on the claim's filing date rather than today's date.

Princiv models a body of regulated law as structured, queryable knowledge — an explicit authority hierarchy, an explicit decision procedure, explicit temporal versioning, explicit rule defeasibility — so that agents query structure rather than infer it from prose.

### 1.2 Why now, and why this shape

Substantial work already exists: roughly 9,000 lines in Princiv and 473 in Veridian Core, all merged to `main`. The domain modelling — a 224-class OWL ontology correctly encoding the authority hierarchy, temporal versioning, and rule types — is the hard part, and it is done.

What has not worked is the pace. The original plan was written as though capacity were unlimited. It was not, and the gap between plan and reality accumulated as undocumented debt: sixteen catalogued items, of which the Severity 1 and 2 entries all trace to one missing mechanism.

This project is a **regroup, not a restart**. It preserves the existing work, fixes the root cause of the accumulated debt, and proceeds under a plan sized to actual available capacity.

---

## 2. Objectives

| # | Objective | Measure |
|---|---|---|
| **O1** | Eliminate the vocabulary drift between the two repositories at its root | A conformance test exists that fails the build when a domain pack's vocabulary disagrees with its schema or ontology |
| **O2** | Make Veridian Core genuinely domain-agnostic | Zero SSA-specific terms remain in the Veridian Core codebase |
| **O3** | Prove the platform claim with a second domain | A minimal Title IX vocabulary pack loads and validates with **no changes to Veridian Core** |
| **O4** | Demonstrate one complete path from document to answer | `MEDEVOC_CHAIN` returns results from ingested data, not only from seeded data |
| **O5** | Establish a repeatable, verifiable development baseline | Both repositories have CI; a clean `pip install` produces a working environment |

These objectives are deliberately narrow. Each is a condition that observably holds or does not — none requires a judgement call to assess.

---

## 3. Scope

### 3.1 In scope — the MVP

> Fix the vocabulary drift at its root, complete the domain-pack refactor so Veridian Core is genuinely domain-agnostic, prove pluggability with a minimal Title IX pack, and demonstrate one path end to end: raw document → extraction → validated triples → Neo4j → answerable Steps 3–5 question.

Concretely:

- Repair the Severity 1 defects: the `AFFECTS_RFC_COMPONENT` acronym bug (D1), the unreachable medical-vocational chain (D2), the `Occupation`/`DOTOccupation` split (D3)
- Introduce a domain-pack mechanism so entity and relationship vocabulary is *input to* Veridian Core rather than *part of* it
- Add a conformance test that makes vocabulary drift a build failure
- Build a minimal Title IX vocabulary pack — vocabulary only, no application, no data
- Establish CI in both repositories and fix the broken dependency declaration (D13)
- Remove the contract-law seed data and validation queries 1–30; retain the `schema.cypher` constraints for later SSA circuit-court content
- Give Veridian Core a real test suite (D12)
- Resolve the `GraphStore` contract violations (D9, D10)

### 3.2 Explicitly out of scope for the MVP

Named here so that adding any of them is a visible, recorded scope change rather than quiet drift.

| Excluded | Rationale |
|---|---|
| Fine-tuned NER model | Task 1.7.1's deferred half. Zero-shot GLiNER already exceeds the >90% recall threshold; fine-tuning is optimisation, not capability |
| Complete Grid Rule table | The ontology carries two sample rules. The full Appendix 2 set is data entry, valuable but not on the critical path |
| Any user interface | The engine is the product for now; UI is a later phase |
| A Title IX *application* | The Title IX pack proves pluggability. Building the application is a separate project |
| Childhood disability subsystem | Modelled in the ontology, queried by nothing. Deferred |
| Benefit calculation subsystem | Same |
| Appeals and procedural subsystems | Same |
| Multi-user, auth, deployment infrastructure | No users yet |

### 3.3 The deferred full vision

Recorded so it is not lost, and explicitly **not** committed to in this MVP:

Veridian Core becomes the substrate for a family of compliance-domain applications. Princiv (SSA disability) is the first. Title IX case management for school districts and higher education is the second and is already a named intent. Further domains follow the same pattern: formal ontology, property graph, validated ingestion, procedural traversal. The engine acquires a stable API surface, then a user interface, then — if evidence supports it — a commercial form.

---

## 4. Deliverables

| Deliverable | Milestone |
|---|---|
| Working dependency declaration and CI in both repositories | M1 |
| Contract-law seed data removed; `CLAUDE.md` corrected | M1 |
| Severity 1 defect D1 fixed | M1 |
| Domain-pack mechanism in Veridian Core | M2 |
| SSA vocabulary relocated to a Princiv-owned domain pack | M2 |
| Vocabulary conformance test | M2 |
| Veridian Core test suite | M2 |
| Minimal Title IX vocabulary pack | M3 |
| Aligned relationship vocabulary; traversable ingested chain | M4 |
| `GraphStore` contract violations resolved | M4 |

Documentation deliverables (this document set, and Phase 2's) are tracked separately in [`../README.md`](../README.md).

---

## 5. Milestones

Sized against **~5 hours per week**. Calendar windows are shown so slippage becomes visible early rather than at the end.

| # | Milestone | Effort | Calendar | Exit criteria |
|---|---|---|---|---|
| **M1** | Foundation & Hygiene | 13–20 h | 3–4 wks | `pip install -r requirements.txt` yields a working environment · CI green on both repos · contract-law seed data removed and `CLAUDE.md` corrected · D1 fixed |
| **M2** | Domain-Pack Refactor | 22–29 h | 4–6 wks | Zero SSA terms in Veridian Core · SSA vocabulary lives in a Princiv-owned pack · conformance test fails on a deliberately introduced drift · Veridian Core test suite exists and passes |
| **M3** | Title IX Validation | 8–12 h | 2–3 wks | A minimal Title IX pack loads and validates with **no changes to Veridian Core** |
| **M4** | Working Vertical Slice | 19–26 h | 4–5 wks | `MEDEVOC_CHAIN` returns results from ingested data · D9 and D10 resolved |

**MVP total: 62–87 hours ≈ 12–18 weeks (3–4 months).**

M2 is the largest milestone and the one most likely to need splitting; the PM Plan carries a defined split point for it.

M3 precedes M4 deliberately. It validates the abstraction against a second example *before* further work is built on top of it. An abstraction proven by a single example is usually wrong in ways that remain invisible until the second example arrives.

---

## 6. Stakeholders and roles

| Role | Held by | Responsibility |
|---|---|---|
| Project sponsor | Jeremy Jones | Direction, scope authority, go/no-go at each milestone |
| Product owner | Jeremy Jones | Requirements, prioritisation, acceptance |
| Lead developer | Jeremy Jones, with Claude Code | Implementation, testing, documentation |
| Reviewer | Jeremy Jones | Code review, architectural review |
| End user (current) | Jeremy Jones | Sole consumer during MVP |

### 6.1 Single-contributor risk, stated plainly

Every role above is held by one person. This has three consequences the plan must account for rather than paper over:

- **No independent review.** Architectural mistakes are caught by the person who made them, or not at all. The conformance test and CI exist partly to substitute mechanical checking for a second reviewer.
- **Bus factor of one.** All project knowledge lives with one contributor. The technical briefing and this document set are the mitigation — they exist so the project survives an interruption of arbitrary length.
- **No external schedule pressure.** Nothing forces a milestone to close. Objectively testable exit criteria are the substitute for that pressure.

---

## 7. Success criteria

The MVP is complete when all of the following hold. Each maps to a milestone exit criterion; there are no orphans in either direction.

| # | Criterion | Objective | Milestone |
|---|---|---|---|
| **S1** | A clean checkout plus `pip install -r requirements.txt` produces an environment where the full test suite runs | O5 | M1 |
| **S2** | CI runs on push in both repositories and passes | O5 | M1 |
| **S3** | No contract-law seed data remains; `CLAUDE.md` describes the actual post-seed state | — | M1 |
| **S4** | Searching the Veridian Core codebase for SSA terms (`RFC`, `Listing`, `GridRule`, `SSR`, `MedicalCondition`) returns zero results outside comments and history | O2 | M2 |
| **S5** | Deliberately introducing a vocabulary drift causes the conformance test to fail | O1 | M2 |
| **S6** | Veridian Core's test suite exists, runs, and passes | O5 | M2 |
| **S7** | The Title IX pack loads, validates, and required no Veridian Core changes | O3 | M3 |
| **S8** | A document ingested through the pipeline produces a `MEDEVOC_CHAIN` result | O4 | M4 |
| **S9** | `upsert_relationship` raises on a missing endpoint; `BatchWriteResult` counters distinguish created from merged | — | M4 |

---

## 8. Constraints

| Constraint | Effect on the plan |
|---|---|
| **~5 hours per week** | Milestones sized 8–25 hours so each closes in 2–5 weeks. Work items must be resumable after a week's gap — no task that requires holding large context across sessions |
| **Single contributor** | No parallel workstreams. Milestones are strictly sequential |
| **No budget** | Open-source and free-tier tooling only. Local Neo4j, no hosted services |
| **No independent reviewer** | Correctness must be enforced mechanically — tests, CI, conformance checks — rather than by review |
| **Local development only** | Neo4j runs locally; three of four test files auto-skip when it is unavailable |
| **Existing architecture is fixed** | The two-store design (OWL + property graph) is settled and not reopened in this MVP |

---

## 9. Assumptions

Stated as assumptions rather than facts, so that a wrong one is recognisable as the cause when a milestone slips.

| # | Assumption | If wrong |
|---|---|---|
| **A1** | AI-assisted development sustains roughly 3–5× unassisted throughput on this codebase | Effort estimates scale up proportionally; milestone count stays the same, calendar extends |
| **A2** | ~5 hrs/week is sustainable over 3–4 months | Calendar extends; milestone structure is unaffected |
| **A3** | The domain-pack refactor is contained to Veridian Core's 473 lines plus Princiv's five importing modules | M2 grows; may need splitting |
| **A4** | The existing OWL ontology is sufficient for the MVP without extension | Ontology work enters scope and M4 grows |
| **A5** | GLiNER zero-shot recall stays above 90% after vocabulary changes | Fine-tuning re-enters scope, contradicting §3.2 |
| **A6** | A Title IX vocabulary can be specified well enough to test pluggability without domain expertise | M3 needs research time, or the proof narrows to a synthetic vocabulary |
| **A7** | Local Neo4j remains sufficient — no hosted instance needed | Infrastructure cost and setup enter scope |

---

## 10. High-level risks

Summarised here; the full register with mitigations and triggers is in [`03-project-management-plan.md`](03-project-management-plan.md).

| Risk | Severity |
|---|---|
| Scope creep — the identified historical failure mode | High |
| Vocabulary drift resuming after the refactor | High |
| Single-contributor availability interruption | Medium |
| Domain-pack abstraction proves wrong under the second domain | Medium |
| Legal-accuracy defects in modelled content | Medium |
| Dependency fragility (GLiNER, spaCy, torch version churn) | Low |

---

## 11. Authority and change control

**Approval authority:** the project sponsor approves milestone completion, scope changes, and each documentation set.

**Scope changes** require: a written entry in the PM Plan's change log recording what changed, why, and its effort impact; and explicit re-approval of the affected milestone. Anything added to scope must either displace something of comparable size or extend the milestone's stated effort range.

This is deliberately heavier than a solo project would normally warrant. Undocumented scope expansion is the specific failure this regroup exists to correct, so the friction is the point.

---

## 12. Approval

| Role | Name | Date | Status |
|---|---|---|---|
| Project sponsor | Jeremy Jones | | Pending |

---

*Next: [`02-business-case.md`](02-business-case.md)*
