# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Coding Guidelines

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## Project Overview

Princiv is a **Legal Context Engine for Regulated AI Agents** — a system that models law as structured, queryable knowledge so AI agents can reason about legal constraints in regulated domains. The current focus is SSA disability law (SSI/SSDI).

The architecture has two complementary layers:
- **Neo4j knowledge graph** (`graph/`) — stores concrete legal facts: cases, statutes, courts, jurisdictions, and their relationships (citations, precedence, interpretation)
- **OWL 2.0 ontology** (`ontology/ssa_domain.ttl`) — formally models the SSA 5-step sequential disability evaluation process, medical listings, RFC assessments, and the authority hierarchy (statutes → regulations → SSRs → HALLEX/POMS)

## Working with the Knowledge Graph (Neo4j)

To initialize a fresh Neo4j instance:
```cypher
-- 1. Run constraints and indexes
:source graph/schema.cypher

-- 2. Load seed data
:source graph/seed_data/load_seed_data.cypher

-- 3. Validate the graph
:source graph/validation_queries.cypher
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
