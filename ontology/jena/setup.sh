#!/usr/bin/env bash
# setup.sh — Initialize the Jena TDB2 dataset and load ssa_domain.ttl.
#
# Run from the project root:
#   ./ontology/jena/setup.sh
#
# Prerequisites (one of):
#   A) Apache Jena installed and $JENA_HOME set (https://jena.apache.org/download/)
#   B) Apache Jena Fuseki standalone downloaded and $FUSEKI_HOME set
#   C) `tdb2.tdbloader` and `arq` available on PATH
#
# After loading, optionally start the Fuseki HTTP server:
#   ./ontology/jena/setup.sh --start-fuseki
#
# Environment variables:
#   JENA_HOME     — path to Jena binary distribution (contains bin/)
#   FUSEKI_HOME   — path to Fuseki standalone distribution (contains fuseki-server)
#   TDB2_DIR      — override default TDB2 location (default: ontology/jena/tdb2)
#   ONTOLOGY_FILE — override default ontology path (default: ontology/ssa_domain.ttl)

set -euo pipefail

# ---------------------------------------------------------------------------
# Config defaults
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TDB2_DIR="${TDB2_DIR:-$PROJECT_ROOT/ontology/jena/tdb2}"
ONTOLOGY_FILE="${ONTOLOGY_FILE:-$PROJECT_ROOT/ontology/ssa_domain.ttl}"
FUSEKI_CONFIG="$PROJECT_ROOT/ontology/jena/fuseki-config.ttl"
START_FUSEKI=false

# Parse args
for arg in "$@"; do
    case "$arg" in
        --start-fuseki) START_FUSEKI=true ;;
        --help|-h)
            echo "Usage: $0 [--start-fuseki]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Locate Jena binaries
# ---------------------------------------------------------------------------
find_binary() {
    local name="$1"
    # 1. Direct PATH
    if command -v "$name" &>/dev/null; then
        echo "$name"
        return
    fi
    # 2. $JENA_HOME/bin/
    if [[ -n "${JENA_HOME:-}" && -x "$JENA_HOME/bin/$name" ]]; then
        echo "$JENA_HOME/bin/$name"
        return
    fi
    # 3. $FUSEKI_HOME/ (Fuseki standalone bundles some Jena tools)
    if [[ -n "${FUSEKI_HOME:-}" && -x "$FUSEKI_HOME/$name" ]]; then
        echo "$FUSEKI_HOME/$name"
        return
    fi
    echo ""
}

TDB_LOADER="$(find_binary tdb2.tdbloader)"
ARQ="$(find_binary arq)"

if [[ -z "$TDB_LOADER" ]]; then
    echo "ERROR: tdb2.tdbloader not found." >&2
    echo "" >&2
    echo "Install Apache Jena:" >&2
    echo "  brew install jena                    # macOS" >&2
    echo "  sudo apt-get install jena            # Debian/Ubuntu" >&2
    echo "  export JENA_HOME=/path/to/apache-jena-*" >&2
    echo "" >&2
    echo "Or download from: https://jena.apache.org/download/" >&2
    exit 1
fi

echo "Using tdb2.tdbloader: $TDB_LOADER"
[[ -n "$ARQ" ]] && echo "Using arq:            $ARQ"

# ---------------------------------------------------------------------------
# Validate ontology source file
# ---------------------------------------------------------------------------
if [[ ! -f "$ONTOLOGY_FILE" ]]; then
    echo "ERROR: Ontology file not found: $ONTOLOGY_FILE" >&2
    exit 1
fi
echo "Ontology source:      $ONTOLOGY_FILE"

# ---------------------------------------------------------------------------
# Create TDB2 directory (gitignored; data is ephemeral per environment)
# ---------------------------------------------------------------------------
if [[ -d "$TDB2_DIR" ]]; then
    echo ""
    echo "TDB2 dataset already exists at: $TDB2_DIR"
    echo "Re-loading will ADD triples (not replace). To start fresh, delete the directory:"
    echo "  rm -rf $TDB2_DIR"
    echo ""
    read -rp "Continue loading? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
else
    mkdir -p "$TDB2_DIR"
    echo "Created TDB2 directory: $TDB2_DIR"
fi

# ---------------------------------------------------------------------------
# 1. Parse / validate with riot (if available) before loading
# ---------------------------------------------------------------------------
RIOT="$(find_binary riot)"
if [[ -n "$RIOT" ]]; then
    echo ""
    echo "Step 1/3 — Parsing ontology with riot..."
    "$RIOT" --validate "$ONTOLOGY_FILE"
    echo "  Parse OK."
else
    echo "Step 1/3 — Skipping riot validation (not found); proceeding to load."
fi

# ---------------------------------------------------------------------------
# 2. Load into TDB2
# ---------------------------------------------------------------------------
echo ""
echo "Step 2/3 — Loading into TDB2 at $TDB2_DIR..."
"$TDB_LOADER" --loc="$TDB2_DIR" "$ONTOLOGY_FILE"
echo "  Load complete."

# ---------------------------------------------------------------------------
# 3. Quick sanity check: count triples
# ---------------------------------------------------------------------------
if [[ -n "$ARQ" ]]; then
    echo ""
    echo "Step 3/3 — Counting loaded triples..."
    TRIPLE_COUNT="$("$ARQ" \
        --loc="$TDB2_DIR" \
        --query=- \
        <<< 'SELECT (COUNT(*) AS ?n) WHERE { ?s ?p ?o }' \
        2>/dev/null | grep -oE '[0-9]+' | tail -1)"
    echo "  Triple count: ${TRIPLE_COUNT:-unknown}"
else
    echo "Step 3/3 — Skipping triple count (arq not found)."
fi

echo ""
echo "Setup complete."
echo ""

# ---------------------------------------------------------------------------
# Optionally start Fuseki HTTP server
# ---------------------------------------------------------------------------
if $START_FUSEKI; then
    FUSEKI_SERVER="$(find_binary fuseki-server)"
    if [[ -z "$FUSEKI_SERVER" ]]; then
        echo "ERROR: fuseki-server not found. Cannot start HTTP endpoint." >&2
        echo "Download Fuseki from: https://jena.apache.org/download/" >&2
        exit 1
    fi
    echo "Starting Fuseki HTTP server..."
    echo "  Config:   $FUSEKI_CONFIG"
    echo "  Endpoint: http://localhost:3030/ssa-ontology/sparql"
    echo ""
    exec "$FUSEKI_SERVER" --config="$FUSEKI_CONFIG"
else
    echo "To start the SPARQL HTTP endpoint:"
    echo "  fuseki-server --config=ontology/jena/fuseki-config.ttl"
    echo ""
    echo "Or rerun with:"
    echo "  ./ontology/jena/setup.sh --start-fuseki"
fi
