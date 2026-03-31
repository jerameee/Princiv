#!/usr/bin/env bash
# run-reasoner.sh — Run the OWL reasoner over the loaded TDB2 dataset to
# materialize inferred triples (subclass/equivalentClass/disjoint axioms).
#
# Requires Apache Jena with the inference API.  This script uses the Jena
# `inference` command (available in Jena 4.x as `infer`) or falls back to
# the ROBOT CLI (https://robot.obolibrary.org/) which wraps HermiT.
#
# Run from the project root:
#   ./ontology/jena/run-reasoner.sh [--reasoner hermit|rdfs] [--output FILE]
#
# Output: inferred-triples.ttl written alongside the ontology by default.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ONTOLOGY_FILE="$PROJECT_ROOT/ontology/ssa_domain.ttl"
TDB2_DIR="$PROJECT_ROOT/ontology/jena/tdb2"
REASONER="hermit"
OUTPUT_FILE="$PROJECT_ROOT/ontology/jena/inferred-triples.ttl"

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --reasoner) REASONER="$2"; shift 2 ;;
        --output)   OUTPUT_FILE="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: $0 [--reasoner hermit|rdfs] [--output FILE]"
            exit 0
            ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

find_binary() {
    local name="$1"
    command -v "$name" 2>/dev/null \
        || { [[ -n "${JENA_HOME:-}" ]] && echo "$JENA_HOME/bin/$name"; } \
        || echo ""
}

echo "Reasoner:       $REASONER"
echo "Input ontology: $ONTOLOGY_FILE"
echo "Output:         $OUTPUT_FILE"
echo ""

# ---------------------------------------------------------------------------
# Strategy A: ROBOT CLI (preferred for OWL DL reasoning with HermiT/ELK)
# ---------------------------------------------------------------------------
ROBOT="$(find_binary robot)"
if [[ -n "$ROBOT" ]]; then
    echo "Using ROBOT CLI..."

    ROBOT_REASONER="HermiT"
    case "$REASONER" in
        hermit) ROBOT_REASONER="HermiT" ;;
        elk)    ROBOT_REASONER="ELK"    ;;
        rdfs)   ROBOT_REASONER="structural" ;;
    esac

    "$ROBOT" reason \
        --input "$ONTOLOGY_FILE" \
        --reasoner "$ROBOT_REASONER" \
        --axiom-generators "SubClass EquivalentClass DisjointClasses" \
        --output "$OUTPUT_FILE"

    echo "Inferred triples written to: $OUTPUT_FILE"
    echo ""

    # Load inferred triples into TDB2 if dataset exists
    TDB_LOADER="$(find_binary tdb2.tdbloader)"
    if [[ -d "$TDB2_DIR" && -n "$TDB_LOADER" ]]; then
        echo "Loading inferred triples into TDB2..."
        "$TDB_LOADER" --loc="$TDB2_DIR" "$OUTPUT_FILE"
        echo "Done."
    fi

    exit 0
fi

# ---------------------------------------------------------------------------
# Strategy B: Jena's built-in OWL micro-reasoner via arq + rdfs rules
# (RDFS reasoning only — not full OWL DL; no HermiT dependency)
# ---------------------------------------------------------------------------
ARQ="$(find_binary arq)"
if [[ -n "$ARQ" ]]; then
    echo "ROBOT not found. Falling back to Jena RDFS reasoner via arq..."
    echo "(For OWL DL reasoning, install ROBOT: https://robot.obolibrary.org/)"
    echo ""

    # arq --reasoner rdfs materializes subclass/type inference in-memory
    # and prints the inferred graph in N-Triples
    "$ARQ" \
        --data="$ONTOLOGY_FILE" \
        --reasoner=rdfs \
        --query=- \
        --results=NT \
        <<< 'CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o }' \
        > "$OUTPUT_FILE"

    echo "Inferred triples written to: $OUTPUT_FILE"

    if [[ -d "$TDB2_DIR" ]]; then
        TDB_LOADER="$(find_binary tdb2.tdbloader)"
        if [[ -n "$TDB_LOADER" ]]; then
            echo "Loading into TDB2..."
            "$TDB_LOADER" --loc="$TDB2_DIR" "$OUTPUT_FILE"
        fi
    fi

    exit 0
fi

# ---------------------------------------------------------------------------
# Strategy C: owlready2 (Python)
# ---------------------------------------------------------------------------
if command -v python3 &>/dev/null; then
    echo "Jena tools not found. Trying owlready2 (Python)..."
    python3 - "$ONTOLOGY_FILE" "$OUTPUT_FILE" "$REASONER" <<'PYEOF'
import sys
try:
    from owlready2 import get_ontology, sync_reasoner_hermit, sync_reasoner_pellet
except ImportError:
    print("ERROR: owlready2 not installed. Run: pip install owlready2", file=sys.stderr)
    sys.exit(1)

onto_path, out_path, reasoner = sys.argv[1], sys.argv[2], sys.argv[3]
onto = get_ontology(f"file://{onto_path}").load()
try:
    if reasoner == "hermit":
        sync_reasoner_hermit(infer_property_values=True)
    else:
        sync_reasoner_pellet(infer_property_values=True)
except Exception as e:
    print(f"Reasoner error: {e}", file=sys.stderr)
    sys.exit(1)

onto.save(file=out_path, format="rdfxml")
print(f"Inferred ontology saved to: {out_path}")
PYEOF
    exit 0
fi

echo "ERROR: No suitable reasoner tool found." >&2
echo "Install one of:" >&2
echo "  - ROBOT:      https://robot.obolibrary.org/" >&2
echo "  - Apache Jena: https://jena.apache.org/download/ (set \$JENA_HOME)" >&2
echo "  - owlready2:  pip install owlready2" >&2
exit 1
