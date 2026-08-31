# Business Requirements Document

**Project:** Princiv — Legal Context Engine for Regulated AI Agents
**Platform component:** Veridian Core
**Document status:** Phase 1, Set B
**Companion documents:** [`01-project-charter.md`](01-project-charter.md) · [`02-business-case.md`](02-business-case.md) · [`05-software-requirements-spec.md`](05-software-requirements-spec.md)

---

## 1. Purpose and scope of this document

This document states **what the business needs**, in business terms. It deliberately avoids technical solutions — those belong in the Software Requirements Specification, which traces every requirement back to a capability defined here.

The audience is the project sponsor, any future contributor, and anyone assessing whether the system does what it set out to do.

**Positioning note.** The project is currently research and portfolio work. "Business" here means the goals and value defined in [`02-business-case.md`](02-business-case.md) — demonstrated capability, a validated architectural thesis, and retained optionality — not revenue. The commercial question is deferred to a defined decision point (Business Case §7).

---

## 2. Problem statement

AI agents deployed into regulated legal domains fail in ways that are hard to detect and consequential when missed.

A general-purpose model, with or without document retrieval, will:

- produce citations that are correctly formatted and do not exist
- apply the current version of a regulation to a claim governed by an earlier one
- treat a rule that can be rebutted as though it were conclusive
- rank an internal operations manual above a binding circuit court opinion

These are not variations of one problem. Each has a distinct structural cause, and none is addressed by supplying more text. The information needed to avoid them — which authority supersedes which, which outranks which, which rules are defeasible — lives in the *relationships between* legal sources, not in the sources themselves.

In SSA disability adjudication the consequences are asymmetric: claimants are frequently unrepresented, the errors are difficult for a non-expert to detect, and the outcome determines whether someone receives benefits they are entitled to.

---

## 3. Business goals

| # | Goal | Rationale |
|---|---|---|
| **BG-1** | Enable AI agents to reason about regulated law without fabricating authority | The core problem in §2. Without this the system has no reason to exist |
| **BG-2** | Demonstrate that the approach generalises beyond a single legal domain | Distinguishes a reusable platform from a one-off application; the basis of the Veridian Core thesis |
| **BG-3** | Establish a foundation that resists knowledge drift as it grows | The briefing documented sixteen debt items whose Severity 1–2 entries all stem from one missing mechanism. Growth without a guard repeats it |
| **BG-4** | Preserve optionality for a future commercial direction | The work needed for the research outcome is largely the work needed for any commercial one; deferring costs little and forecloses nothing |

---

## 4. Stakeholders and their needs

| Stakeholder | Needs | Priority |
|---|---|---|
| **Project sponsor** | A system that demonstrably works; honest visibility into progress; scope that stays where it was set | High |
| **Future contributors** | Enough written context to resume cold; architecture whose rationale is recoverable, not inferred | High |
| **AI agents (consuming systems)** | Structured, queryable legal knowledge; citations that resolve; explicit rule strength and temporal validity | High |
| **Second-domain implementers** | Ability to add a domain without modifying the engine | Medium |
| **End users — practitioners** | Deferred. Needs captured in Business Case §7.1 (Path A) | Deferred |
| **End users — claimants** | Deferred. Needs captured in Business Case §7.1 (Path B) | Deferred |

The two deferred rows are recorded so that the eventual commercialization decision starts from a stated position rather than a blank page.

---

## 5. Business capabilities

What the system must be able to do, expressed without reference to how. Each is traced to functional requirements in the SRS.

### Core capabilities

| # | Capability | Supports | Priority |
|---|---|---|---|
| **BC-1** | Represent a regulated legal domain formally — including the authority hierarchy, the temporal validity of each authority, and the strength of each rule | BG-1 | Must |
| **BC-2** | Store legal facts and the relationships between them in a form that can be queried directly | BG-1 | Must |
| **BC-3** | Convert regulatory source documents into structured knowledge | BG-1 | Must |
| **BC-4** | Reject knowledge that does not conform to the domain model, before it is stored | BG-1, BG-3 | Must |
| **BC-5** | Answer domain questions by traversing the domain's own decision procedure | BG-1 | Must |
| **BC-6** | Provide a resolvable citation for every legal assertion | BG-1 | Must |
| **BC-7** | Support additional legal domains without modification to the engine | BG-2 | Must |
| **BC-8** | Maintain an audit record of everything that enters the knowledge base | BG-1, BG-3 | Must |
| **BC-9** | Detect automatically when the domain model and the stored knowledge disagree | BG-3 | Must |

### Deferred capabilities

Recorded so the full vision is preserved; explicitly not required for the MVP.

| # | Capability | Supports | Phase |
|---|---|---|---|
| **BC-10** | Expose a stable public interface for external consumers | BG-4 | Future |
| **BC-11** | Present the evaluation to a human through a user interface | BG-4 | Future |
| **BC-12** | Handle claimant-specific case data and produce case-level assessments | BG-4 | Future |
| **BC-13** | Track regulatory change and flag affected stored knowledge | BG-3 | Future |

---

## 6. Business rules

Constraints arising from the legal domain rather than from technical design. These are non-negotiable and drive requirements in the SRS.

| # | Rule |
|---|---|
| **BR-1** | Authority is ranked. Where sources conflict, the higher-ranked source governs: Statute → Regulation → Social Security Ruling → HALLEX/POMS |
| **BR-2** | Authority is time-bound. The version of an authority that governs a claim is determined by the claim's relevant date, not by the current date |
| **BR-3** | Rules differ in strength. A conclusive presumption mandates its outcome; a rebuttable presumption directs an outcome that contrary evidence can overcome |
| **BR-4** | The sequential evaluation is ordered and terminating. Steps are evaluated in sequence, and certain outcomes end the analysis rather than continuing to the next step |
| **BR-5** | Every legal assertion must be attributable to a citable source |
| **BR-6** | Absence of knowledge is not a negative finding. The system must distinguish "no applicable rule found" from "the rule does not apply" |

---

## 7. Success metrics

Business-level measures. Each is objectively determinable.

| # | Metric | Target | Capability |
|---|---|---|---|
| **BM-1** | Entity extraction recall on the reference document set | > 90% | BC-3 |
| **BM-2** | Proportion of malformed knowledge rejected before storage | 100% | BC-4 |
| **BM-3** | Untyped records present in the knowledge base after a run | 0 | BC-4 |
| **BM-4** | Engine changes required to add a second domain | 0 | BC-7 |
| **BM-5** | Model/knowledge disagreements detected automatically | 100% of introduced test cases | BC-9 |
| **BM-6** | Legal assertions in the knowledge base lacking a citation | 0 | BC-6 |
| **BM-7** | A question answerable end to end from an ingested document | ≥ 1 demonstrated | BC-3, BC-5 |

BM-1 through BM-7 map onto Charter success criteria S1–S9; the mapping is given in the SRS traceability matrix.

---

## 8. Constraints

Business and environmental constraints. Technical constraints appear in the SRS.

| # | Constraint | Consequence |
|---|---|---|
| **BCN-1** | Approximately 5 hours per week of contributor capacity | Scope must fit 62–87 hours; work must survive multi-week gaps |
| **BCN-2** | Single contributor holding every project role | No parallel work; no independent review; correctness enforced mechanically |
| **BCN-3** | No budget | Open-source and free-tier tooling only; local infrastructure |
| **BCN-4** | No access to SSA domain expert review | Modelled rules carry citations, but correctness of the modelling is unverified by a qualified reviewer. Accepted limitation |
| **BCN-5** | Source legal content must be publicly available | No licensed corpora; regulations, rulings, and published opinions only |
| **BCN-6** | The system produces information, not legal advice | Any future user-facing form must not constitute unauthorized practice of law |

---

## 9. Assumptions

| # | Assumption | If it proves wrong |
|---|---|---|
| **BA-1** | Structured knowledge measurably outperforms retrieval alone for the failure modes in §2 | The project's central premise fails; value narrows to the modelling artifact |
| **BA-2** | The pattern generalises to other compliance domains | BG-2 fails; Veridian Core's separate existence is unjustified and consolidation becomes correct |
| **BA-3** | Publicly available sources are sufficient to model the domain usefully | Coverage gaps limit the demonstration |
| **BA-4** | A domain can be modelled well enough to be useful without expert review | Accuracy defects surface late and damage credibility disproportionately |
| **BA-5** | The existing ontology is adequate for the MVP without extension | Ontology work enters scope, growing M4 |

---

## 10. Out of scope

Aligned with Charter §3.2. Listed here in business terms.

| Excluded | Reason |
|---|---|
| Legal advice or case outcome prediction | The system provides structured information; advice is a professional judgement and a regulatory exposure |
| Case management or claimant record handling | No users; no data-protection posture; BC-12 is Future |
| Any user interface | The engine is the deliverable; BC-11 is Future |
| A Title IX application | The Title IX pack tests pluggability. Building the application is a separate project |
| Complete SSA regulatory coverage | The MVP demonstrates a working path, not exhaustive content |
| Multi-user operation, authentication, hosted deployment | No users |

---

## 11. Glossary

### SSA disability domain

| Term | Definition |
|---|---|
| **ALJ** | Administrative Law Judge. Presides over hearings at the Office of Hearings Operations |
| **AOD / EOD** | Alleged Onset Date — when the claimant says disability began. Established Onset Date — when SSA determines it began. The two frequently differ |
| **Blue Book** | Informal name for the Listing of Impairments |
| **DDS** | Disability Determination Services. State agency making initial and reconsideration determinations |
| **DLI** | Date Last Insured. The last date a claimant holds sufficient work credits for SSDI. Onset must precede it |
| **DOT** | Dictionary of Occupational Titles. US Department of Labor reference for occupational demands, used at Step 5 |
| **Grid Rules** | Medical-Vocational Guidelines, 20 C.F.R. Part 404, Subpart P, Appendix 2. A lookup table keyed on RFC level, age category, education, and work experience that directs a disability finding |
| **HALLEX** | Hearings, Appeals and Litigation Law Manual. Procedural guidance for hearing offices |
| **Listing** | An entry in the Listing of Impairments specifying medical criteria that, if met, conclusively establish disability |
| **ME / VE** | Medical Expert — testifies on medical equivalence. Vocational Expert — testifies on job availability and requirements |
| **POMS** | Program Operations Manual System. Internal SSA manual; lower authority than regulations |
| **PRW** | Past Relevant Work. Work performed within the last 15 years at SGA level for long enough to learn it |
| **RFC** | Residual Functional Capacity. What a claimant can still do despite impairments (20 C.F.R. § 404.1545) |
| **Sequential evaluation** | The mandatory five-step process at 20 C.F.R. § 404.1520 |
| **SGA** | Substantial Gainful Activity. Work above an earnings threshold; engaging in it generally ends the analysis at Step 1 |
| **SSDI / SSI** | Social Security Disability Insurance (Title II, insurance-based, requires work history) / Supplemental Security Income (Title XVI, need-based) |
| **SSR** | Social Security Ruling. Binding SSA policy interpretation published in the Federal Register |
| **SVP** | Specific Vocational Preparation. Time required to learn a job; determines skill level |

### The five-step sequential evaluation

| Step | Question |
|---|---|
| 1 | Is the claimant engaging in substantial gainful activity? |
| 2 | Does the claimant have a severe medically determinable impairment? |
| 3 | Does the impairment meet or equal a Listing? |
| 4 | Given the RFC, can the claimant perform past relevant work? |
| 5 | Given the RFC, age, education, and work experience, can the claimant adjust to other work? |

### Technical and architectural

| Term | Definition |
|---|---|
| **Authority hierarchy** | The ranking that determines which source governs when sources conflict |
| **Conformance check** | An automated test that the vocabulary, the graph schema, and the ontology agree |
| **Defeasible rule** | A rule that applies unless an exception is met |
| **Domain pack** | A self-contained bundle supplying everything the engine needs to work in one legal domain: ontology, schema, vocabulary, and extraction labels |
| **Ontology (OWL)** | A formal, machine-readable model of a domain's concepts and their relationships, supporting automated inference |
| **Ontology gate** | The validation stage that rejects non-conforming knowledge before storage |
| **Property graph** | A graph database model where nodes and edges carry properties. Optimised for traversal |
| **Rebuttable presumption** | A directed outcome that contrary evidence can overcome |
| **Conclusive presumption** | A mandated outcome that evidence cannot overcome |
| **Triple** | A (subject, predicate, object) statement — the unit of extracted knowledge |
| **Vocabulary drift** | Divergence between the entity/relationship names used in different parts of the system |

---

## 12. Approval

| Role | Name | Date | Status |
|---|---|---|---|
| Project sponsor | Jeremy Jones | | Pending |

---

*Next: [`05-software-requirements-spec.md`](05-software-requirements-spec.md)*
