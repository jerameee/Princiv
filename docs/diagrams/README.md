# Diagrams

Diagram sources for the Phase 1 documentation set. Hand-drawn style, authored as Excalidraw elements.

| File | Used by | Shows |
|---|---|---|
| `01-target-architecture.excalidraw.json` | [SAD §3](../phase-1/06-system-architecture-document.md) | Four layers — domain packs, Veridian Core, Princiv, infrastructure |
| `02-data-flow.excalidraw.json` | [SAD §4](../phase-1/06-system-architecture-document.md) | Document to answer, including the rejection path |
| `03-conformance-check.excalidraw.json` | [TDD §3](../phase-1/07-technical-design-document.md) | Three-way agreement between manifest, schema, and ontology |
| `04-validation-algorithm.excalidraw.json` | [TDD §4](../phase-1/07-technical-design-document.md) | The five gate checks and their rejection reasons |
| `05-api-interaction.excalidraw.json` | [Interface §2](../phase-1/08-uiux-wireframes.md) | Turn-by-turn evaluation between agent, engine, and Neo4j |
| `06-ui-walkthrough-wireframe.excalidraw.json` | [Interface §7](../phase-1/08-uiux-wireframes.md) | Directional wireframe of a future evaluation screen |

---

## Format

These files hold **Excalidraw element arrays**, not complete `.excalidraw` scene files.

Two differences from the native format matter:

- Shapes carry an inline `label` property. Native Excalidraw uses separate text elements bound via `containerId`
- `cameraUpdate` entries are viewport directives for the renderer, not drawn elements

A conversion step is therefore needed before opening one directly in the Excalidraw editor: expand each `label` into a bound text element, and drop the `cameraUpdate` entries.

## Rendering

GitHub does not render these inline — the documents link to them rather than embedding them.

To get images in the rendered documents, export PNG or SVG from the Excalidraw editor into this directory and switch the document links to image syntax. That step is manual and has not been done.

## Conventions

Colour usage is consistent across all six diagrams:

| Colour | Meaning |
|---|---|
| Blue | Domain packs, input, the consuming agent |
| Purple | Veridian Core — the engine |
| Green | Princiv, accepted paths, success |
| Amber | Validation, decisions, warnings, directional content |
| Red | Rejection, failure |
| Teal | Storage and infrastructure |
| Grey, dashed | Not built, or structural framing |
