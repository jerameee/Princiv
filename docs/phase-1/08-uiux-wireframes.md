# Interface Design and Wireframes

**Project:** Princiv — Legal Context Engine for Regulated AI Agents
**Document status:** Phase 1, Set C
**Companion documents:** [`06-system-architecture-document.md`](06-system-architecture-document.md) · [`07-technical-design-document.md`](07-technical-design-document.md)

---

## 1. Purpose and framing

The MVP has **no user interface**. Its product surface is a Python API consumed by AI agents (Charter §3.1). This document therefore covers two distinct things, and the distinction is load-bearing:

| Part | Status | Content |
|---|---|---|
| **Part A — The API** | **Committed** | The actual interface being built. Interaction model, call shapes, error semantics, design principles |
| **Part B — Future UI** | **Directional only** | Wireframes for an eventual human interface. Not committed, not estimated, not in scope |

Part B exists so that the eventual UI conversation starts from a considered position rather than a blank page. **Nothing in Part B is a commitment.** If it conflicts with what is learned during the MVP, the MVP wins.

Diagram sources are in [`../diagrams/`](../diagrams/).

---

# Part A — The API surface **[MVP]**

## 2. Interaction model

*Diagram: [`../diagrams/05-api-interaction.excalidraw.json`](../diagrams/05-api-interaction.excalidraw.json)*

The evaluation is a **conversation, not a single call.** The engine holds the procedure; the caller supplies answers; each exchange advances one step.

This shape follows directly from ADR-5 — the sequential evaluation lives in the graph as data, and the step router reads it at runtime. A single `evaluate(all_the_facts)` call would require the engine to know in advance which facts every step needs, which would put the procedure back into code.

The turn-by-turn model has three properties worth stating:

- **A human or an agent can supply answers.** The engine does not care which.
- **The path is the explanation.** Every traversal is recorded, so "why did we conclude this?" is answered by replaying the steps rather than by generating a rationale after the fact.
- **The evaluation can pause indefinitely.** State is a plain dict; nothing is held open.

## 3. Call shapes

Illustrative of the intended shape. The public API is `FR-QRY-12` (Future); what exists in the MVP is the Python-level interface below.

### 3.1 Starting and advancing an evaluation

```python
from ingestion.packs import load_pack
from graph.step_router import build_step_router

pack   = load_pack("packs/ssa-disability")
router = build_step_router(driver, pack)

state = {"active_step": "step_1_sga"}
state |= router(state | {"answer": "no"})
# -> {"active_step": "step_2_severity",
#     "step_name": "Step 2: Severity",
#     "outcome_label": "not_engaged_in_sga",
#     "disposition": None,
#     "is_terminal": False}
```

The router returns **only changed keys** (`FR-QRY-06`), so it composes with LangGraph's state merge and with a plain dict update.

### 3.2 Terminal state

```python
# {"active_step": None,
#  "step_name": "Meets Listing 1.15",
#  "outcome_label": "meets_or_equals_listing",
#  "disposition": "disabled",
#  "is_terminal": True}
```

`active_step` becomes `None` and `is_terminal` becomes `True` together. A caller may check either.

### 3.3 Direct queries

```python
from graph.cypher_templates import GRID_RULE_LOOKUP

session.run(GRID_RULE_LOOKUP,
            rfc_level="sedentary",
            age_category="advanced",
            education="limited_or_less",
            work_experience="unskilled_or_none")
# -> rule_number, decision, outcome, cfr_cite
```

`cfr_cite` is returned on every row. Citation is not an optional enrichment — it is part of the result (`BC-6`, `FR-QRY-09`).

### 3.4 Ingestion

```python
result = await Pipeline(store=store, pack=pack).run(documents)
# PipelineResult(documents_processed=12, entities_extracted=847,
#                relationships_extracted=203,
#                validation=ValidationMetrics(accepted_count=181,
#                                             rejected_count=22,
#                                             rejection_reasons=Counter({...})),
#                nodes_written=812, relationships_written=181)
```

Rejection counts are returned rather than logged and forgotten. A caller can assert on them.

## 4. API design principles

| # | Principle | Consequence |
|---|---|---|
| **AP-1** | Citations are results, not metadata | Every query returning a legal conclusion returns its authority in the same row |
| **AP-2** | State is plain data | Dicts and dataclasses, not opaque handles. Serialisable, inspectable, resumable |
| **AP-3** | Partial returns, not full state | The router returns what changed, so callers compose it freely |
| **AP-4** | Data problems are counted; structural problems raise | A rejected triple is normal. A missing node is a bug |
| **AP-5** | Errors name the likely cause | `LookupError` on a missing branch says "verify the evaluation graph is loaded" |
| **AP-6** | Nothing hidden succeeds | No silent fallbacks. If something is dropped, it is counted and reported |
| **AP-7** | The domain is a parameter | Every entry point takes a pack. No global domain state |

**AP-6 has a known violation.** `_relationships_to_graph_rels` silently skips relationships whose endpoints are missing (TDD §5.3). It is assigned to M4.

## 5. Error semantics

| Condition | Response | Caller action |
|---|---|---|
| Triple fails validation | Counted in `ValidationMetrics`, reason recorded | Inspect `rejection_reasons` |
| No branch edge from a step | `LookupError` naming the step and likely cause | Load the evaluation graph |
| Invalid answer | `ValueError` | Pass `"yes"` or `"no"` |
| Missing `active_step` | `ValueError` | Initialise state |
| Relationship endpoint absent | **[M4]** `MissingEndpointError` | Write nodes before relationships |
| Label not in pack vocabulary | **[M4]** `ValueError` | Check the manifest |
| Pack conformance failure | Build fails with all violations listed | Fix the manifest |

## 6. Developer-facing surfaces

No graphical console is planned for the MVP. Three text surfaces serve the developer:

**Structured audit log.** Every write emits JSON — `{action, label, entity_id, created, ts}`. Piping through `jq` gives a usable inspection surface with no tooling to build.

**Pipeline metrics.** `PipelineResult` is a dataclass that prints legibly and asserts cleanly in tests.

**Conformance report.** Lists every violation with its check, the offending manifest entry, and what disagreed (`FR-PACK-06`).

These are sufficient for a single developer. A console is `BC-10` territory, and building one now would be speculative (Charter §3.2).

---

# Part B — Future user interface **[DIRECTIONAL — NOT COMMITTED]**

> Everything below is a sketch of a possible future, produced so that the eventual conversation has a starting point. It is **not** in the MVP, not estimated, and not approved. It will be revisited only after the commercialization decision point (Business Case §7.3), because who the UI serves determines almost everything about it.

## 7. Evaluation walkthrough

*Diagram: [`../diagrams/06-ui-walkthrough-wireframe.excalidraw.json`](../diagrams/06-ui-walkthrough-wireframe.excalidraw.json)*

The central screen. Three regions, each mapping to something the architecture already produces.

| Region | Content | Backed by |
|---|---|---|
| **Left — progress** | Five steps; completed ones show their answer; current is highlighted; future ones are inert | Step router traversal path |
| **Centre — decision** | The step's question, supporting context, and the answer control. Below it, what each answer leads to | `EvaluationStep` node + branch edges |
| **Right — authority** | The governing authorities with their binding force, and which *version* governs given the claim date | Authority hierarchy + temporal versioning |

Three design commitments are embedded in that layout, and each exists because the architecture makes it cheap:

**Consequences are shown before the answer is given.** "Yes → DISABLED (conclusive)" appears next to the button. The user is never surprised by where an answer leads, because the branch edges are already in the graph.

**Rule strength is visible.** The screen says a Listing is a *conclusive* presumption. Conflating conclusive and rebuttable presumptions is one of the four failure modes this project exists to address (BRD §2.1) — a UI that hid the distinction would reintroduce it.

**The governing version is stated, with its reason.** "2021 edition governs — filed 2023." Version selection by claim date rather than current date is `BR-2`, and surfacing it is what makes the system's advantage legible to a user.

## 8. Other screens, described

Not wireframed. Sketched only far enough to be useful later.

| Screen | Purpose | Notes |
|---|---|---|
| **Intake** | Capture claimant facts: dates, work history, impairments, education | Progressive disclosure. Date last insured and onset date drive version selection, so they come first |
| **Authority viewer** | Full text of a cited authority with its version history | Shows supersession explicitly — what this replaced, what replaced it |
| **Determination summary** | The complete path with every step, answer, and authority | This is the explanation. It is a traversal record, not generated prose |
| **Grid Rule explorer** | The four vocational factors as controls; the directed outcome updates live | Makes the Grid legible; also a good demonstration surface |

## 9. Principles for any eventual UI

| # | Principle | Why |
|---|---|---|
| **UP-1** | Never present a conclusion without its authority | The system's entire claim is that conclusions are traceable |
| **UP-2** | Make rule strength visible | Conclusive vs. rebuttable is a real legal distinction users must see |
| **UP-3** | Show the governing version and why it governs | Temporal validity is invisible in most legal tools and is a differentiator here |
| **UP-4** | Distinguish "no rule found" from "the rule does not apply" | `BR-6`. An empty result and a negative finding are different facts |
| **UP-5** | Information, never advice | `BCN-6`, `NFR-29`. Applies to copy, tone, and layout, not just a disclaimer |
| **UP-6** | The path is the explanation | Do not generate a rationale. Show the traversal |

## 10. Accessibility and plain language

Not designed, but the constraints are known and recorded now because retrofitting them is expensive.

**Accessibility.** Any claimant-facing interface serves a population that includes people with the impairments being adjudicated — visual, cognitive, motor. WCAG 2.1 AA is the floor, not the aspiration. Keyboard navigation, screen-reader semantics, and no reliance on colour alone.

**Plain language.** SSA vocabulary is dense and largely opaque to non-specialists. Terms like *substantial gainful activity*, *residual functional capacity*, and *past relevant work* would need plain-language equivalents with the term of art available alongside — the claimant needs to understand it, and any representative needs the precise term.

**Unauthorized practice of law.** A claimant-facing tool that answers "am I disabled?" is closer to legal advice than one that answers "what does Step 3 require?" This is a design constraint on *what the interface asks and answers*, not a disclaimer to be added at the end (`BCN-6`, `UP-5`).

---

## 11. Out of scope

| Excluded | Reason |
|---|---|
| Any implemented UI | MVP is engine-only |
| Visual design, branding, typography | Premature before the audience is decided |
| Responsive and mobile layouts | Premature |
| Authentication, accounts, multi-user | No users |
| Case management and document upload UI | `BC-12`, Future |
| Public HTTP API design | `FR-QRY-12`, Future |

---

## 12. Approval

| Role | Name | Date | Status |
|---|---|---|---|
| Project sponsor | Jeremy Jones | | Pending |

---

*End of Phase 1. Phase 2 — Quality Assurance and Testing, Deployment and Maintenance — begins after Phase 1 approval.*
