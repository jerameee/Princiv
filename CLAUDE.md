# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Princiv is a **Legal Context Engine for Regulated AI Agents** — a system that models law as structured, queryable knowledge so AI agents can reason about legal constraints in regulated domains. The current focus is SSA disability law (SSI/SSDI).

The architecture has two complementary layers:
- **Neo4j knowledge graph** (`schema/`) — stores concrete legal facts: cases, statutes, courts, jurisdictions, and their relationships (citations, precedence, interpretation)
- **OWL 2.0 ontology** (`ontology/ssa_domain.ttl`) — formally models the SSA 5-step sequential disability evaluation process, medical listings, RFC assessments, and the authority hierarchy (statutes → regulations → SSRs → HALLEX/POMS)

## Working with the Knowledge Graph (Neo4j)

To initialize a fresh Neo4j instance:
```cypher
-- 1. Run constraints and indexes
:source schema/create_schema.cypher

-- 2. Load seed data
:source schema/load_seed_data.cypher

-- 3. Validate the graph
:source schema/validation_queries.cypher
```

`validation_queries.cypher` contains 30 queries with expected result counts in comments — these are the de facto test suite. Expected state after seed load:
- 13 LegalSource nodes (10 cases, 3 statutes), 5 Courts, 13 LegalConcepts, 3 Jurisdictions
- ~20 ADDRESSES, 9 SUBCONCEPT_OF, 10 DECIDED_BY, 3-4 CITES relationships

## Key Ontology Concepts (ssa_domain.ttl)

**Authority hierarchy** (binding force descends):
`Statute → Regulation → SocialSecurityRuling (SSR) → HALLEX/POMS`

**Sequential evaluation steps** (`SequentialEvaluation`):
1. `Step1_SGA` — Substantial Gainful Activity
2. `Step2_Severity` — Severe medically determinable impairment
3. `Step3_ListingsOrEquivalence` — Meets/equals a Listing
4. `Step4_PastRelevantWork` — RFC vs. past work
5. `Step5_OtherWork` — RFC vs. other work in national economy

**Rule types**: `DefeasibleRule`, `RebuttablePresumption`, `ConclusivePresumption` — rules carry `confidence` (0.0–1.0) for fuzzy logic support.

**Temporal versioning**: `VersionedAuthority` → `AuthorityVersion` with `effectiveFrom`/`effectiveUntil` — critical because SSA listings and Grid Rules change and prior versions govern pending claims.

## Domain Notes

- `area_of_law` is being migrated from contract law examples → SSI/SSDI; current seed data in `schema/` still uses contract law
- Grid Rules reference `20 C.F.R. Part 404, Subpart P, Appendix 2`; Medical Listings reference the Blue Book
- The ontology uses OWL 2.0 with SWRL-style rule encoding; reasoners (e.g., HermiT, Pellet) should be compatible
