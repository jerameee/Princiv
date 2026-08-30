# Business Case

**Project:** Princiv — Legal Context Engine for Regulated AI Agents
**Platform component:** Veridian Core
**Document status:** Phase 1, Set A
**Companion documents:** [`01-project-charter.md`](01-project-charter.md) · [`03-project-management-plan.md`](03-project-management-plan.md)

---

## 1. Executive summary

AI agents are being deployed into regulated domains faster than the infrastructure for making them *correct* in those domains is being built. The dominant approach — a general model plus document retrieval — reduces obvious fabrication but leaves a class of failures that is harder to see and more dangerous: applying a superseded regulation, treating a rebuttable presumption as conclusive, or ranking a persuasive source above a binding one.

Princiv addresses this by modelling law as **structured knowledge rather than retrievable text**. Its two-store architecture — a formal OWL ontology for meaning and validity, a property graph for facts and traversal — lets an agent query legal structure directly.

Veridian Core generalises the pattern. The pipeline that turns regulatory documents into validated, queryable knowledge is not specific to disability law. It applies to any domain with a defined authority hierarchy and a structured decision procedure. Title IX case management for school districts and higher education is the named next target.

**This project is currently positioned as research and portfolio work.** Its immediate return is demonstrated capability and a defensible technical artifact, not revenue. The commercial question is deliberately deferred, with the decision point and its evidence requirements defined in §7 rather than left implicit.

---

## 2. The problem

### 2.1 Four specific failure modes

These are not general concerns about model reliability. Each is a distinct, observable failure with a distinct structural cause.

**Fabricated citations.** Models generate citations that are formatted correctly, plausibly named, and non-existent. In legal work a citation is the load-bearing element — the claim it supports is only as good as the authority behind it. *Cause: citation format is learnable from text; citation existence is not.*

**Superseded-version conflation.** SSA Listings and Grid Rules change, and the governing version depends on the claim's filing or onset date, not on today's date. A model trained on a corpus spanning multiple versions has no reliable way to select the right one. The treating-physician rule changed materially in March 2017; a claim with a 2016 onset is governed by the earlier rule. *Cause: temporal validity is a property of the authority, not of the text describing it.*

**Defeasibility blindness.** Meeting a Listing mandates a finding of disabled — conclusive. A Grid Rule directs a finding that vocational expert testimony can overcome — rebuttable. The two read almost identically in prose. Conflating them produces confidently wrong conclusions. *Cause: rule strength is a structural property that surface text does not reliably encode.*

**Authority-rank confusion.** The hierarchy `Statute → Regulation → SSR → HALLEX/POMS` determines which source wins in a conflict. POMS is an internal operations manual and does not override a circuit opinion — but both are authoritative-sounding prose. *Cause: relative authority is external to the documents themselves.*

### 2.2 Why the common approach does not solve this

Retrieval-augmented generation grounds output in real documents, which addresses fabrication reasonably well. It does not address the other three.

Retrieval returns text ranked by similarity to a query. Nothing in that operation encodes that one returned document supersedes another, that one outranks another, or that a rule stated in one is defeasible. A retriever asked about Listing 1.04 will happily return the 2014 and 2021 versions together, undifferentiated. The information needed to choose between them is not in either document — it is in the relationship between them.

### 2.3 Why this matters more in regulated domains

In most applications a wrong answer is an inconvenience. In disability adjudication, a wrong answer about whether an impairment meets a Listing can change whether someone receives benefits they are entitled to. The consequences are asymmetric, the users are often unrepresented, and the errors are difficult for a non-expert to detect.

---

## 3. The proposed approach

Model the law as structured knowledge, then let agents query the structure.

| Failure mode | Structural remedy | Where it lives |
|---|---|---|
| Fabricated citations | Citations are graph nodes with uniqueness constraints — a citation either resolves or does not exist | `graph/schema.cypher` |
| Superseded-version conflation | `VersionedAuthority` → `AuthorityVersion` with `effectiveFrom` / `effectiveUntil` / `supersedes` | `ontology/ssa_domain.ttl` §Documentary Layer |
| Defeasibility blindness | `ConclusivePresumption` / `RebuttablePresumption` / `DefeasibleRule` as distinct OWL classes; `Listing` and `GridRule` subclass the appropriate one | `ontology/ssa_domain.ttl` §Normative Layer |
| Authority-rank confusion | Explicit hierarchy with `hasBindingForce` carrying `mandatory` / `binding` / `persuasive` / `internal` | `ontology/ssa_domain.ttl` §Documentary Layer |

A fifth property follows from the same design: **the decision procedure is data.** The SSA five-step evaluation is stored as graph nodes connected by `IF_YES_GO_TO` / `IF_NO_GO_TO` edges, and traversed at runtime. An agent can therefore explain *why* it reached a conclusion by replaying the path — and when SSA changes the procedure, that is a data migration rather than a code change.

---

## 4. Options considered

| # | Option | Assessment |
|---|---|---|
| 1 | **Do nothing** | Rejected. Substantial work already exists and is sound. The problem is pacing and accumulated debt, neither of which resolves by inaction — the drift compounds |
| 2 | **RAG only** | Rejected. Far cheaper and addresses fabrication, but structurally cannot address versioning, defeasibility, or authority rank (§2.2). Solves the visible problem and leaves the dangerous ones |
| 3 | **Fine-tuned domain model** | Rejected. Improves fluency in SSA terminology but does not make reasoning verifiable, and retrains for every regulatory change. Fails the auditability requirement — an agent cannot cite *why* it concluded something |
| 4 | **Ontology only** | Rejected. Correctly encodes meaning and supports inference, but traversing large citation networks through a reasoner is impractically slow, and application tooling against triplestores is thinner |
| 5 | **Property graph only** | Rejected. Fast traversal and good tooling, but cannot express cardinality restrictions, class equivalence, or derive subclass membership — precisely the constructs that encode legal meaning |
| 6 | **Hybrid: ontology + property graph** | **Selected.** Each store does what it is good at. Cost is genuine — two stores to keep synchronised — and is mitigated by the ontology gate, which enforces that the graph never accepts what the ontology would reject |
| 7 | **Commercial legal-research API** | Rejected. Existing products serve human researchers, are priced for law firms, and expose text search rather than queryable structure. None provides the machine-readable decision procedure this project needs |

### 4.1 Buy versus build

No available product provides a machine-queryable model of SSA disability adjudication. Commercial legal research tools (Westlaw, Lexis) serve human researchers with document retrieval; their APIs surface text, not structure. Open datasets exist for SSA regulations as documents but not as ontologies.

The knowledge modelling — deciding that Grid Rules are rebuttable presumptions and Listings are conclusive ones, and encoding that formally — is domain work that no vendor has done in machine-readable form. That is the project's substance, and it must be built.

---

## 5. Value

### 5.1 Current positioning: research and portfolio

The project is positioned as research and portfolio work. Value accrues in four forms.

**Demonstrated capability across an unusual intersection.** Formal ontology engineering (OWL 2.0, description logic, reasoner compatibility), graph database design, NLP pipeline construction, and substantive regulatory domain knowledge. Few projects span all four, and the combination is the point rather than any one part.

**A defensible technical artifact.** A 224-class ontology that correctly models an authority hierarchy, temporal versioning, and rule defeasibility is not a weekend project. It stands up to expert scrutiny in a way that a wrapper around a language model does not.

**A validated architectural thesis.** The claim that regulated-domain reasoning benefits from structured knowledge over pure retrieval is testable. The Title IX pack tests the stronger claim — that the pattern generalises. A tested claim is worth considerably more than an asserted one.

**Retained optionality.** The work required for the research outcome is largely the same work required for any commercial outcome. Deferring the commercial decision costs almost nothing and preserves every path.

### 5.2 The platform thesis

Veridian Core exists because the pattern is not SSA-specific.

Any domain with a defined authority hierarchy and a structured decision procedure fits: formal ontology for meaning, property graph for facts, validated ingestion, procedural traversal. **Title IX is the test case.** It has a regulatory hierarchy (statute → 34 CFR Part 106 → OCR guidance), a defined grievance procedure with steps and branch points, evidentiary standards, and — like SSA disability — real consequences for people who are frequently unrepresented.

**Today the thesis is unproven, and the code contradicts it.** Veridian Core's vocabulary is hardcoded SSA terminology. Serving Title IX would require editing the library itself, which is the opposite of pluggable. The MVP's domain-pack refactor makes the claim true, and the minimal Title IX pack tests it.

That refactor is unusually well-leveraged. It is *also* the structural fix for the drift documented in the briefing — a vocabulary manifest loaded from a domain pack cannot drift from itself. One piece of work serves both the platform goal and the debt-reduction goal, which is exactly what a capacity-constrained project should be looking for.

---

## 6. Cost

Cost is effort and calendar. There is no budget; tooling is open-source and free-tier, and Neo4j runs locally.

### 6.1 MVP

| Milestone | Effort | Calendar |
|---|---|---|
| M1 · Foundation & Hygiene | 13–20 h | 3–4 wks |
| M2 · Domain-Pack Refactor | 22–29 h | 4–6 wks |
| M3 · Title IX Validation | 8–12 h | 2–3 wks |
| M4 · Working Vertical Slice | 19–26 h | 4–5 wks |
| **Total** | **62–87 h** | **12–18 wks** |

At ~5 hours per week, **3–4 months**.

### 6.2 Ongoing

Beyond the MVP, maintenance is modest but non-zero: dependency updates (GLiNER, spaCy, and torch move quickly), regulatory currency as SSA revises Listings and Grid Rules, and ontology extension as new subsystems are queried. Call it 2–4 hours per month to keep the system current without adding capability.

### 6.3 The cost of the alternative

Not proceeding has its own cost. The vocabulary drift is not static — it grows with every change to either repository, because nothing detects it. The Severity 1 defects are already causing silent data loss: `AFFECTS_RFC_COMPONENT` triples are rejected 100% of the time, and the flagship medical-vocational query cannot find anything the pipeline writes.

Each additional month of development on the current foundation adds work that will have to be redone.

---

## 7. Commercialization decision point

The commercial question is deliberately deferred. This section records the candidate paths and what would decide among them, so the deferral is a documented decision rather than an omission.

### 7.1 Candidate paths

| Path | Users | Value proposition | Principal obstacles |
|---|---|---|---|
| **A · Practitioner tool** | Disability attorneys and non-attorney representatives | Faster case assessment, fewer missed arguments, citations that resolve | Requires UI, accuracy liability, established competitors, professional-market sales cycle |
| **B · Claimant self-service** | Individuals pursuing their own claims | Accessible guidance for an underserved, largely unrepresented population | Unauthorized-practice-of-law exposure, higher accuracy stakes, weak willingness to pay, plain-language burden |
| **C · Licensed infrastructure** | Teams building regulated-domain AI | The correctness substrate others do not want to build; SSA and Title IX as reference implementations | Requires the platform claim to be genuinely proven; narrow buyer set; long sales cycle |
| **D · Remain non-commercial** | — | Portfolio, research, and open-source contribution | No revenue; sustained solely by contributor interest |

### 7.2 Evidence that would favour each

- **Toward A:** practitioners shown the working slice describe it as time-saving; accuracy on real cases holds up under expert review
- **Toward B:** claimant-facing accuracy reaches a level where unsupervised use is defensible, and a route around UPL exposure exists
- **Toward C:** the Title IX pack loads cleanly with no core changes, and a third domain is added by someone other than the original author
- **Toward D:** none of the above materialises, or contributor interest shifts

### 7.3 When this is revisited

**At MVP completion (end of M4).** By then S7 will have tested the platform claim and S8 will have demonstrated end-to-end capability. Both are prerequisites for evaluating any commercial path honestly, and neither exists today.

Revisiting earlier would mean deciding without the evidence. Revisiting later would mean building UI or go-to-market work before knowing which path it serves.

---

## 8. Risk to the business case

| Risk | Impact if realised |
|---|---|
| The platform thesis fails — the abstraction does not generalise past SSA | Path C closes; the project's value narrows to a single-domain demonstration |
| Legal-accuracy defects surface in modelled content | Credibility damage disproportionate to the defect; paths A and B become substantially harder |
| Capacity interruption extends the timeline indefinitely | Portfolio value decays as the work ages; mitigated by documentation enabling resumption |
| A competitor ships equivalent structured legal infrastructure | Path C closes; research value largely survives |

---

## 9. Recommendation

**Proceed with the MVP as scoped in the Project Charter.**

The reasoning is that the work is well-leveraged. The domain-pack refactor simultaneously fixes the root cause of the accumulated debt, makes the platform claim true rather than aspirational, and produces the evidence needed to evaluate commercial paths honestly. At 63–82 hours it is a bounded commitment that ends with a testable answer to the project's central question — does this pattern generalise? — rather than with another set of assumptions.

The alternative, continuing to add capability on the current foundation, means building on a defect whose blast radius grows monthly.

---

*Next: [`03-project-management-plan.md`](03-project-management-plan.md)*
