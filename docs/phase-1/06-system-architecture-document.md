# System Architecture Document

**Project:** Princiv — Legal Context Engine for Regulated AI Agents
**Platform component:** Veridian Core
**Document status:** Phase 1, Set C
**Companion documents:** [`05-software-requirements-spec.md`](05-software-requirements-spec.md) · [`07-technical-design-document.md`](07-technical-design-document.md) · [`../00-technical-briefing.md`](../00-technical-briefing.md)

---

## 1. Purpose and scope

This document describes the **system-level architecture**: the layers, their responsibilities, how data moves between them, what technology each uses and why, and how the whole is deployed. Component-level and code-level design is in the Technical Design Document.

Diagram sources are in [`../diagrams/`](../diagrams/) as Excalidraw JSON.

> **Current state vs. target state.** This document describes the **target** architecture — the domain-pack design that the MVP delivers. Sections that describe something not yet built are marked **[TARGET]**. Sections describing what exists today are marked **[CURRENT]**. The distinction matters: about two-thirds of MVP requirements are met, but the entire domain-pack subsystem is unbuilt.

---

## 2. Architectural drivers

The architecture is shaped by six forces, in priority order.

| # | Driver | Architectural consequence |
|---|---|---|
| **AD-1** | Legal correctness must be enforceable, not hoped for | A validation gate sits between extraction and storage. Nothing invalid enters the store, ever |
| **AD-2** | The same engine must serve multiple legal domains | Domain vocabulary is data loaded at runtime, not code. The engine holds no domain terms |
| **AD-3** | Legal meaning and legal facts have different query shapes | Two stores: an OWL ontology for meaning and inference, a property graph for facts and traversal |
| **AD-4** | Every assertion must be attributable | Citations are first-class nodes; extracted entities retain source offsets; every write is audited |
| **AD-5** | One contributor, ~5 hrs/week, no reviewer | Correctness enforced mechanically. Components must be independently testable and independently resumable |
| **AD-6** | The decision procedure changes when the law changes | The procedure is stored as data and traversed, not compiled into control flow |

---

## 3. Logical architecture **[TARGET]**

> **Diagram:** [`01-target-architecture`](../diagrams/01-target-architecture.excalidraw.json) — four layers, dependencies downward only.

Four layers. Dependencies point downward only; no layer knows about the layer above it.

### 3.1 Domain Packs **[TARGET]**

A self-contained bundle supplying everything needed to operate in one legal domain. Exactly one pack is active per pipeline run (`FR-PACK-07`).

Each pack supplies four artifacts (`FR-PACK-01`):

| Artifact | Purpose |
|---|---|
| OWL ontology | Formal domain model — classes, properties, domain/range axioms, rule types |
| Graph schema | Constraints and indexes for the domain's node labels |
| Vocabulary manifest | Entity types, relationship types, and their permitted subject/object pairings |
| Extraction label map | Natural-language prompts for the NER model, mapped to vocabulary entries |

Two packs are planned: **SSA Disability** (full — the existing ontology, schema, and seed content) and **Title IX** (vocabulary only — its purpose is to prove pluggability, not to serve an application).

**Why packs rather than configuration.** A configuration file would let the engine be parameterised, but the four artifacts must agree with each other, and that agreement is exactly what has been drifting. Bundling them makes the agreement checkable as a unit (`FR-PACK-04`) rather than assumed across four separately-edited files.

### 3.2 Veridian Core — the engine **[CURRENT, partial]**

Domain-agnostic. Contains no legal vocabulary of any kind (`FR-PACK-03`). Zero runtime dependencies beyond the Python standard library (`NFR-07`).

| Component | Responsibility | Status |
|---|---|---|
| **Pack Loader** | Read a pack; expose its vocabulary to the pipeline | ○ Unbuilt |
| **Conformance Check** | Verify manifest, schema, and ontology agree; fail the build if not | ○ Unbuilt |
| **Abstract Interfaces** | `EntityExtractor`, `GraphStore`, `DocumentLoader` | ✅ Built |
| **Interchange Types** | `Document`, `ExtractedEntity`, `ExtractedRelationship`, `GraphNode`, `GraphRelationship` | ✅ Built |

**Why the engine holds abstractions and the application holds implementations.** Neo4j, GLiNER, spaCy, torch, and rdflib are all Princiv dependencies. Keeping them out of the engine means a future consumer takes on only the dependencies it actually uses — a Title IX application backed by a different store imports no Neo4j driver. The cost is that the engine's contracts have no reference implementation to test against, which `NFR-23` and `IR-11` address by requiring an engine-side test suite.

### 3.3 Princiv — the SSA application **[CURRENT]**

Implements the engine's interfaces for the SSA domain, and provides the query layer.

| Component | Responsibility |
|---|---|
| **GLiNER Extractor** | Zero-shot NER using the active pack's label map; emits typed entities with confidence and source offsets |
| **Relation Extractor** | Sentence-scoped entity pairing; emits typed triples |
| **Ontology Gate** | Validates every triple against the active pack's ontology before storage |
| **Neo4j Store** | Idempotent MERGE writes with structured audit logging |
| **Cypher Templates** | Parameterised queries: Grid Rule lookup, Step 5 other-work, medical-vocational chain |
| **Step Router** | Reads the sequential evaluation from the graph and advances it one step per answer |

### 3.4 Infrastructure

| Store | Holds | Accessed by |
|---|---|---|
| **Neo4j** | Legal facts, entities, relationships, the decision procedure as graph structure | Cypher templates, Step Router, Neo4j Store |
| **Jena / Fuseki** | The active pack's ontology, with materialised inferences | Ontology Gate (via rdflib, in-process), SPARQL validation queries |

Note the asymmetry: the ontology is loaded **in-process by rdflib** for per-triple validation (`NFR-10`, `NFR-11`), while Fuseki serves the reasoning and validation workload. The gate cannot afford a network round trip per triple.

---

## 4. Data flow

> **Diagram:** [`02-data-flow`](../diagrams/02-data-flow.excalidraw.json) — document to answer, including the rejection path.

| Stage | Input | Output | Requirement |
|---|---|---|---|
| 1 · Load | File or raw text | `Document` | `FR-ING-01`, `FR-ING-10` |
| 2 · Extract | `Document` | Typed entities with confidence and offsets | `FR-ING-02` |
| 3 · Relate | Entity list | Typed triples | `FR-ING-07`, `FR-ING-08` |
| 4 · Validate | Triples | Accepted set + rejected set with reasons | `FR-VAL-01`…`FR-VAL-12` |
| 5 · Store | Accepted triples | Merged graph nodes and edges + audit records | `FR-STORE-01`…`FR-STORE-08` |
| 6 · Query | A question | An answer with citations | `FR-QRY-01`…`FR-QRY-09` |

**The gate is a hard boundary.** Rejected triples are counted, logged with a reason, and discarded (`FR-VAL-09`). There is no quarantine, no retry queue, and no "store it anyway and clean up later" path. This is deliberate: the value proposition is that an agent can trust the store, and a store that is only periodically valid cannot be trusted between validations.

---

## 5. Domain-pack architecture **[TARGET]**

The MVP's structural centre, and the architecture's least conventional element. Worth explaining in full.

### 5.1 The problem it solves

Today, vocabulary is defined in three places that must agree and have no mechanism keeping them in agreement:

1. `EntityType` / `RelationshipType` enums in Veridian Core
2. Node labels and constraints in `graph/schema.cypher`
3. Classes and object properties in `ontology/ssa_domain.ttl`

Plus two derived mappings — the NER prompt map and an implicit `SCREAMING_SNAKE_CASE` → `camelCase` transformation between enum names and ontology property names.

The briefing catalogued the result: roughly fifteen drifts, including one predicate rejected 100% of the time because the name transformation cannot round-trip an acronym.

### 5.2 The inversion

**Today:** vocabulary lives in the engine, and the domain must conform to it. Adding a domain means editing the engine.

**Target:** vocabulary lives in the pack, and the engine adapts. Adding a domain means adding a directory.

```
Today                              Target
─────                              ──────
engine ── defines ──> vocabulary   pack ── supplies ──> vocabulary
   ^                                                        │
   └── domain must conform                  engine ── reads ┘
```

### 5.3 Why this also fixes the drift

A vocabulary manifest is a single declaration of the domain's terms. The conformance check verifies that manifest against the pack's own schema and ontology (`FR-PACK-04`) and fails the build on disagreement (`FR-PACK-05`).

The three sources of truth become one source plus two checked projections. **Drift stops being possible rather than merely being fixed** — which is why this single piece of work closes eight separate debt items.

### 5.4 The acronym lesson, generalised

`IR-09` requires the manifest to declare the vocabulary-to-ontology name mapping **explicitly**, rather than deriving it by string transformation.

This is a small requirement with a general point behind it. The current system infers a relationship that it could have declared, and inference over names is brittle in ways that are invisible until a specific case breaks. `AFFECTS_RFC_COMPONENT` was that case. Patching the transformation would fix one symptom; declaring the mapping removes the category.

---

## 6. Technology choices

Each with the alternatives considered and the reason for rejection.

| Choice | Selected | Alternatives rejected | Rationale |
|---|---|---|---|
| **Knowledge representation** | OWL 2.0 + Neo4j property graph | OWL only · graph only · relational | Reasoning over large citation networks is impractically slow in a triplestore; a property graph cannot express cardinality restrictions or derive subclass membership. Each store does what it is good at (AD-3) |
| **Ontology language** | OWL 2.0 (Turtle) | RDFS · SHACL · JSON Schema | RDFS cannot express the cardinality and equivalence axioms the domain needs. SHACL validates shapes but does not support inference. OWL DL is decidable and reasoner-supported |
| **Graph database** | Neo4j | ArangoDB · TigerGraph · Neptune | Mature Cypher tooling, strong local development story, composite index support matching the Grid Rule access pattern. No budget for hosted alternatives (`BCN-3`) |
| **Reasoner / SPARQL** | Apache Jena + Fuseki | HermiT · Pellet standalone · GraphDB | Open source, scriptable, runs locally, integrates OWL reasoning with a SPARQL endpoint in one stack |
| **In-process ontology access** | rdflib | Jena over HTTP · owlready2 | Per-triple validation cannot afford a network round trip (`NFR-11`). rdflib loads once and answers in-process |
| **Entity extraction** | GLiNER (zero-shot) | Fine-tuned transformer · spaCy NER · LLM extraction | Takes entity type names as prompts, so vocabulary comes from the pack rather than a trained label set. No annotation effort, and measured recall already exceeds the 90% bar. Checkpoint is swappable (`FR-ING-05`) |
| **Sentence segmentation** | spaCy (`ner`/`textcat` disabled) | NLTK · regex · pysbd | Already a transitive dependency; accurate on legal prose; loading only the parser keeps it light |
| **Relation extraction** | Sentence-scoped type-pair mapping | Dependency parsing · LLM extraction | Every emitted triple traces to an explicit map entry derived from an OWL axiom. High precision by construction, and auditable — which matters more here than recall, since the gate rejects structural errors downstream |
| **Workflow orchestration** | LangGraph | Custom state machine · Temporal · Prefect | The sequential evaluation is a stateful, branching, human-in-the-loop workflow. Building it by hand means reimplementing state merging and checkpointing |
| **Audit logging** | stdlib `logging`, JSON formatted | Audit table in Neo4j · dedicated service | No new infrastructure. Redirect the logger and the trail follows. An audit table would double write volume for data that is rarely queried transactionally |
| **Packaging** | Two repos, engine installed as a dependency | Monorepo · single package · git submodule | The engine is intended for reuse by applications that will not live in this repository. See §6.1 |

### 6.1 On the two-repository split

The briefing identified a real risk: the engine's code depends on nothing from Princiv, but its *meaning* depended entirely on Princiv, and the hand-maintained mirror between them had drifted badly.

The split is retained because the stated goal is reuse — a Title IX application, and others after it, that will not live in this repository. Consolidating would make today simpler at the cost of the platform thesis (`BG-2`).

**But the split is only justified once the engine is genuinely domain-agnostic.** Until the domain-pack refactor lands, the split carries all of the cost and none of the benefit. That is why `FR-PACK-03` and the M3 Title IX validation exist: they convert the split from an assertion into a tested property. If M3 finds that engine changes are required, the split's justification fails and consolidation becomes the correct response.

---

## 7. Deployment view

### 7.1 MVP — local development only

```
Developer machine
├── Python 3.11+ virtualenv
│   ├── veridian-core        (editable install, pinned)
│   └── princiv              (working tree)
├── Neo4j                    (local instance, bolt://localhost:7687)
└── Jena/Fuseki              (local, ontology validation + SPARQL)

GitHub Actions
├── Princiv CI               lint · unit tests · Neo4j service container · conformance
└── veridian-core CI         lint · unit tests · contract tests
```

No hosted services, no containers in production, no authentication surface — there are no users (`BCN-3`).

**CI must run Neo4j in a service container** (`NFR-25`). Three of four Princiv test files auto-skip when Neo4j is unreachable, which means a suite can report success while exercising almost nothing. This is not an optional refinement to CI; without it, CI provides false assurance.

### 7.2 Configuration

| Setting | Source | Default |
|---|---|---|
| `NEO4J_URI` | Environment | `bolt://localhost:7687` |
| `NEO4J_USER` / `NEO4J_PASS` | Environment | `neo4j` |
| Active domain pack | Pipeline construction argument | — |
| GLiNER checkpoint | Extractor constructor | `urchade/gliner_medium-v2.1` |
| Confidence threshold | Extractor constructor | 0.5 |

No credentials in source. No configuration file format is introduced — environment variables and constructor arguments are sufficient at this scale, and a config system would be speculative (`BCN-1`).

### 7.3 Future deployment **[FUTURE]**

Out of scope for the MVP; recorded for continuity. A hosted deployment would need: containerised services, a managed Neo4j, an API gateway with authentication, and a data-protection posture that does not exist today because no user data exists.

---

## 8. Cross-cutting concerns

### 8.1 Auditability

Every write emits `{action, label, entity_id, created, timestamp}` as JSON through stdlib logging (`FR-STORE-07`, `NFR-15`, `NFR-16`). Every rejection is recorded with its reason (`FR-VAL-10`, `NFR-19`). Every extracted entity retains a character offset into its source (`NFR-18`).

Together these mean any assertion in the store can be traced back to the document span it came from and the run that wrote it.

### 8.2 Error handling

| Condition | Behaviour |
|---|---|
| Triple fails validation | Rejected with a reason; counted; pipeline continues |
| Relationship endpoint missing | **[TARGET]** Raise. Currently a silent no-op (D9, `FR-STORE-04`) |
| Batch write fails | Full transaction rollback (`FR-STORE-03`) |
| Step router finds no branch edge | Raise with a diagnostic naming the likely cause (`FR-QRY-08`) |
| Invalid answer supplied to step router | Raise immediately |
| Pack conformance fails | **[TARGET]** Fail the build (`FR-PACK-05`) |

The pattern: **data problems are counted and reported; structural problems raise.** A malformed triple is expected in normal operation and should not halt a run. A missing node when writing a relationship means the caller's assumptions are wrong, and continuing would corrupt the graph silently.

### 8.3 Idempotency

All writes use MERGE (`FR-STORE-01`). Re-ingesting a document produces no duplicates. This is load-bearing: sources get reprocessed after extractor improvements, schema changes, and failures, and without idempotency each reprocessing would multiply the graph.

### 8.4 Concurrency

Single-writer, sequential. No locking, no coordination, no concurrent pipeline runs. `ExtractorRegistry` is explicitly not thread-safe. This is appropriate at current scale and is recorded so that a future multi-writer requirement is recognised as an architectural change rather than a tuning exercise.

---

## 9. Quality attributes

How the architecture delivers the non-functional requirements.

| Attribute | Mechanism | Requirements |
|---|---|---|
| **Correctness** | Validation gate before storage; OWL axioms as the specification | `NFR-01`…`NFR-05` |
| **Portability** | Domain packs; zero engine dependencies; abstract store interface | `NFR-06`…`NFR-09` |
| **Performance** | Ontology loaded once; composite index for the four-factor lookup; lazy model loading | `NFR-10`…`NFR-13` |
| **Auditability** | Structured logs; source offsets; rejection reasons | `NFR-15`…`NFR-19` |
| **Maintainability** | CI; conformance check; contract tests; recorded decisions | `NFR-21`…`NFR-28` |

---

## 10. Architecture decision record

Decisions with lasting consequence, their rationale, and what would overturn them.

| # | Decision | Rationale | Would be overturned by |
|---|---|---|---|
| **ADR-1** | Two knowledge stores rather than one | Meaning and facts have different query shapes (AD-3) | Reasoner performance improving enough to serve traversal, or graph databases gaining OWL inference |
| **ADR-2** | Validate before storage, not after | A store that is only periodically valid cannot be trusted (AD-1) | A use case requiring provisional data to be queryable |
| **ADR-3** | Abstractions in the engine, implementations in the application | Keeps the engine dependency-free for reuse | The engine acquiring dependencies for another reason |
| **ADR-4** | Domain vocabulary as loadable data, not code | Enables reuse; eliminates the drift mechanism (AD-2) | M3 finding the abstraction unworkable |
| **ADR-5** | The decision procedure stored as graph data | Procedure changes become data migrations; traversal is explainable (AD-6) | A procedure too complex to express as node-and-edge branching |
| **ADR-6** | Zero-shot extraction over fine-tuning | No annotation effort; vocabulary derives from the pack | Recall falling below 90% after vocabulary changes |
| **ADR-7** | Two repositories retained | Reuse is the stated goal (`BG-2`) | M3 requiring engine changes — see §6.1 |
| **ADR-8** | Explicit name mapping over derived transformation | Inference over names is brittle; `IR-09` | Nothing — this is a strict improvement |

---

## 11. Known architectural debt

Carried forward from the briefing. Full detail in Part VIII there; here is the architectural significance.

| Debt | Architectural significance |
|---|---|
| **D1** Acronym transformation | The specific failure that motivates `IR-09`. A category of defect, not one bug |
| **D2** Chain unreachable from ingestion | Ingestion and seeding write the same node pairs under different edge names — two vocabularies inside one system |
| **D3** `Occupation` / `DOTOccupation` | Three-way disagreement between enum, schema, and data |
| **D4** Load-bearing labels absent from vocabulary | The extraction path structurally cannot produce node types the query path depends on |
| **D9, D10** Store contract violations | The implementation does not honour its own interface. Undermines the value of having the interface |
| **D11** Contract-law legacy | A prior domain's data still present and still documented as the expected baseline |
| **D12** No engine tests | Every documented contract is unverified upstream |
| **D13** Dependency not declared | The two repositories are not actually connected by any packaging mechanism |

All are addressed within the MVP (Charter §5). **D1 through D8 are symptoms of one absent mechanism**, which §5.3 introduces.

---

## 12. Approval

| Role | Name | Date | Status |
|---|---|---|---|
| Project sponsor | Jeremy Jones | | Pending |

---

*Next: [`07-technical-design-document.md`](07-technical-design-document.md)*
