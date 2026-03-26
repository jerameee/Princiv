#!/usr/bin/env bash
# consistency_check.sh
# OWL DL consistency test for ssa_domain.ttl
#
# Requires one of the following (checked in order):
#   1. robot (https://robot.obolibrary.org/) on PATH
#   2. Python 3 with owlready2 installed  (pip install owlready2)
#
# Usage:
#   ./ontology/tests/consistency_check.sh
#   ./ontology/tests/consistency_check.sh --reasoner hermit   # default
#   ./ontology/tests/consistency_check.sh --reasoner pellet

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONTOLOGY="$SCRIPT_DIR/../ssa_domain.ttl"
REASONER="${2:-hermit}"

if [[ ! -f "$ONTOLOGY" ]]; then
  echo "ERROR: ontology not found at $ONTOLOGY" >&2
  exit 1
fi

# ── Option 1: robot CLI ─────────────────────────────────────────────────────
if command -v robot &>/dev/null; then
  echo "Using robot reasoner ($REASONER)..."
  robot reason \
    --input "$ONTOLOGY" \
    --reasoner "$REASONER" \
    --output /dev/null \
    --axiom-generators "SubClass EquivalentClass DisjointClasses" \
    --include-indirect true
  echo "PASS: ontology is consistent (robot/$REASONER)"
  exit 0
fi

# ── Option 2: owlready2 (Python) ─────────────────────────────────────────────
if command -v python3 &>/dev/null; then
  python3 - "$ONTOLOGY" "$REASONER" <<'PYEOF'
import sys, os, pathlib

ontology_path = pathlib.Path(sys.argv[1]).resolve()
reasoner_name = sys.argv[2].lower()

try:
    import owlready2
except ImportError:
    print("ERROR: owlready2 not installed. Run: pip install owlready2", file=sys.stderr)
    sys.exit(2)

# owlready2 requires a local IRI
onto = owlready2.get_ontology(ontology_path.as_uri()).load()

try:
    if reasoner_name == "pellet":
        owlready2.sync_reasoner_pellet(infer_property_values=True)
    else:
        owlready2.sync_reasoner_hermit(infer_property_values=True)
except owlready2.OwlReadyInconsistentOntologyError as exc:
    print(f"FAIL: ontology is INCONSISTENT — {exc}", file=sys.stderr)
    sys.exit(1)
except Exception as exc:
    print(f"FAIL: reasoner error — {exc}", file=sys.stderr)
    sys.exit(1)

print(f"PASS: ontology is consistent (owlready2/{reasoner_name})")
PYEOF
  exit $?
fi

echo "ERROR: neither 'robot' nor 'python3' found on PATH." >&2
echo "Install robot: https://robot.obolibrary.org/" >&2
echo "  or: pip install owlready2" >&2
exit 2
