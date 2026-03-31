#!/usr/bin/env bash
# run_sparql_tests.sh — CI runner for SPARQL validation queries.
#
# Executes:
#   1. All ASK queries in tests/sparql/ask/  (each must return true)
#   2. Structural SELECT queries (class_hierarchy.rq, object_properties.rq)
#      with row-count assertions
#
# Usage:
#   # Run against the local ontology file (default, no server needed):
#   ./ontology/tests/run_sparql_tests.sh
#
#   # Run against a live Fuseki SPARQL endpoint:
#   SPARQL_ENDPOINT=http://localhost:3030/ssa-ontology/sparql \
#     ./ontology/tests/run_sparql_tests.sh
#
# Environment variables:
#   ONTOLOGY_FILE     — path to TTL source (default: ontology/ssa_domain.ttl)
#   TDB2_DIR          — path to TDB2 dataset (default: ontology/jena/tdb2)
#   SPARQL_ENDPOINT   — HTTP SPARQL endpoint (takes priority over file/TDB2)
#   JENA_HOME         — path to Apache Jena binary distribution

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ONTOLOGY_FILE="${ONTOLOGY_FILE:-$PROJECT_ROOT/ontology/ssa_domain.ttl}"
TDB2_DIR="${TDB2_DIR:-$PROJECT_ROOT/ontology/jena/tdb2}"
ASK_DIR="$SCRIPT_DIR/sparql/ask"
SPARQL_DIR="$SCRIPT_DIR/sparql"

PASS=0
FAIL=0
SKIP=0

# ---------------------------------------------------------------------------
# Color output (suppressed in CI environments that set NO_COLOR)
# ---------------------------------------------------------------------------
if [[ -z "${NO_COLOR:-}" && -t 1 ]]; then
    GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; RESET='\033[0m'
else
    GREEN=''; RED=''; YELLOW=''; RESET=''
fi

pass() { echo -e "${GREEN}  PASS${RESET}  $1"; ((PASS++)); }
fail() { echo -e "${RED}  FAIL${RESET}  $1"; ((FAIL++)); }
skip() { echo -e "${YELLOW}  SKIP${RESET}  $1"; ((SKIP++)); }

# ---------------------------------------------------------------------------
# Locate arq / curl
# ---------------------------------------------------------------------------
find_binary() {
    local name="$1"
    command -v "$name" 2>/dev/null \
        || { [[ -n "${JENA_HOME:-}" ]] && [[ -x "$JENA_HOME/bin/$name" ]] \
             && echo "$JENA_HOME/bin/$name"; } \
        || echo ""
}

ARQ="$(find_binary arq)"
CURL="$(find_binary curl)"

# ---------------------------------------------------------------------------
# Query executor — returns raw output string
# ---------------------------------------------------------------------------
run_query() {
    local query_file="$1"

    # Priority 1: HTTP endpoint
    if [[ -n "${SPARQL_ENDPOINT:-}" ]]; then
        if [[ -z "$CURL" ]]; then
            echo "ERROR: curl required for HTTP endpoint mode" >&2
            return 1
        fi
        curl -s -G "$SPARQL_ENDPOINT" \
            --data-urlencode "query@$query_file" \
            -H "Accept: text/plain"
        return
    fi

    # Priority 2: TDB2 persistent dataset (if it exists)
    if [[ -n "$ARQ" && -d "$TDB2_DIR" ]]; then
        "$ARQ" --loc="$TDB2_DIR" --query="$query_file" 2>/dev/null
        return
    fi

    # Priority 3: local file (most common for development / CI)
    if [[ -n "$ARQ" ]]; then
        "$ARQ" --data="$ONTOLOGY_FILE" --query="$query_file" 2>/dev/null
        return
    fi

    echo "__NO_TOOL__"
}

# ---------------------------------------------------------------------------
# ASK query runner — returns 0 (pass) or 1 (fail/skip)
# ---------------------------------------------------------------------------
run_ask() {
    local query_file="$1"
    local name
    name="$(basename "$query_file")"

    local output
    output="$(run_query "$query_file" 2>&1)"

    if [[ "$output" == "__NO_TOOL__" ]]; then
        skip "$name  (arq not found; set JENA_HOME or install Apache Jena)"
        return 0
    fi

    # arq ASK output: a table with "true" or "false" in it
    if echo "$output" | grep -qi "^true$\|^| true |$\|\"true\""; then
        pass "$name"
        return 0
    else
        fail "$name"
        echo "         Output: $(echo "$output" | head -3)"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# SELECT count assertion runner
# Usage: run_select_count <query_file> <expected_row_count> <label>
# ---------------------------------------------------------------------------
run_select_count() {
    local query_file="$1"
    local expected="$2"
    local label="$3"

    local output
    output="$(run_query "$query_file" 2>&1)"

    if [[ "$output" == "__NO_TOOL__" ]]; then
        skip "$label  (arq not found)"
        return 0
    fi

    # Count data rows: lines that start with '|' and contain '|' twice or more,
    # excluding the header separator line (------).
    local row_count
    row_count=$(echo "$output" \
        | grep -E '^\|' \
        | grep -v -- '----' \
        | tail -n +2 \
        | wc -l \
        | tr -d ' ')

    if [[ "$row_count" -eq "$expected" ]]; then
        pass "$label  (${row_count}/${expected} rows)"
    else
        fail "$label  (got ${row_count} rows, expected ${expected})"
        FAIL=$((FAIL))  # already incremented in fail()
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo ""
echo "========================================================"
echo " Princiv Ontology SPARQL Validation Suite"
echo "========================================================"

# Report active data source
if [[ -n "${SPARQL_ENDPOINT:-}" ]]; then
    echo " Source: $SPARQL_ENDPOINT"
elif [[ -d "$TDB2_DIR" ]]; then
    echo " Source: TDB2 ($TDB2_DIR)"
else
    echo " Source: $ONTOLOGY_FILE"
fi
echo ""

# ---------------------------------------------------------------------------
# Section 1: ASK schema invariant checks
# ---------------------------------------------------------------------------
echo "--- ASK Queries (schema invariants) ---"
if [[ ! -d "$ASK_DIR" ]]; then
    echo "ERROR: ASK directory not found: $ASK_DIR" >&2
    exit 1
fi

# Run all ASK queries sorted by filename (ask_01..ask_10)
ANY_ASK_FAIL=0
for f in $(ls "$ASK_DIR"/*.rq 2>/dev/null | sort); do
    run_ask "$f" || ANY_ASK_FAIL=1
done

if [[ $(ls "$ASK_DIR"/*.rq 2>/dev/null | wc -l) -eq 0 ]]; then
    echo "  No .rq files found in $ASK_DIR"
fi

echo ""

# ---------------------------------------------------------------------------
# Section 2: SELECT row-count assertions
# ---------------------------------------------------------------------------
echo "--- SELECT Queries (structural counts) ---"
run_select_count \
    "$SPARQL_DIR/verify_class_count.rq" 13 "verify_class_count.rq (13 required classes)"
run_select_count \
    "$SPARQL_DIR/object_properties.rq" 16 "object_properties.rq (16 required properties)"

echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
TOTAL=$((PASS + FAIL + SKIP))
echo "========================================================"
printf " Results: %d passed, %d failed, %d skipped / %d total\n" \
    "$PASS" "$FAIL" "$SKIP" "$TOTAL"
echo "========================================================"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
