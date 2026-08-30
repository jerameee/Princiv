# Princiv Documentation

Project documentation for **Princiv** (legal context engine, SSA disability domain) and **Veridian Core** (its reusable ingestion/storage platform).

These documents cover both repositories as a single platform: Veridian Core is the reusable engine, Princiv is the first application built on it, and Title IX case management is the named second consumer.

---

## Reading order

### Start here

| Document | What it gives you |
|---|---|
| [`00-technical-briefing.md`](00-technical-briefing.md) | Complete account of what exists in both repositories, why it was built that way, how the pieces connect, what was planned but never built, and a prioritised register of accumulated debt |

Read the briefing first. Everything else assumes it.

### Phase 1 — Planning, requirements, design

**Project Initiation and Planning**

| Document | Status |
|---|---|
| [`phase-1/01-project-charter.md`](phase-1/01-project-charter.md) | Pending |
| [`phase-1/02-business-case.md`](phase-1/02-business-case.md) | Pending |
| [`phase-1/03-project-management-plan.md`](phase-1/03-project-management-plan.md) | Pending |

**Requirements and Analysis**

| Document | Status |
|---|---|
| [`phase-1/04-business-requirements-document.md`](phase-1/04-business-requirements-document.md) | Pending |
| [`phase-1/05-software-requirements-spec.md`](phase-1/05-software-requirements-spec.md) | Pending |

**Architecture and Design**

| Document | Status |
|---|---|
| [`phase-1/06-system-architecture-document.md`](phase-1/06-system-architecture-document.md) | Pending |
| [`phase-1/07-technical-design-document.md`](phase-1/07-technical-design-document.md) | Pending |
| [`phase-1/08-uiux-wireframes.md`](phase-1/08-uiux-wireframes.md) | Pending |

### Phase 2 — QA, deployment, maintenance

Not started. Begins after Phase 1 is approved. Will cover: Test Plan, Test Cases, Defect Tracking Log, Deployment Plan, Release Notes, User Manuals & Guides.

---

## Project parameters

These decisions frame every document in this set.

| Parameter | Setting |
|---|---|
| **Product surface** | API/engine core now; user interface a later phase |
| **Positioning** | Research / portfolio project; commercial direction deliberately deferred |
| **Resourcing** | Solo contributor working with Claude Code |
| **Scope posture** | Full vision documented; execution plan sequences a deliberately narrow MVP first |
| **Repository relationship** | Veridian Core = reusable platform · Princiv = first application · Title IX = planned second consumer |
| **Domain-pack refactor** | Move SSA vocabulary out of the library into a loadable domain pack; validate with a minimal Title IX pack |

---

## Conventions

- **Diagrams** are Mermaid, so they render on GitHub and diff as text.
- **Code references** use `path/to/file.py:line` against `main` in the relevant repository.
- **Target state vs. current state** — where a document describes something not yet built, it says so explicitly. Nothing here implies a capability that does not exist.
- **Requirement identifiers** carry an MVP / Phase 2 / Future tag so scope boundaries stay visible.

---

*Documentation branch: `docs/project-documentation`*
