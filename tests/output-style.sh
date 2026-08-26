#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SENIOR="$ROOT/plugins/core/output-styles/senior.md"
LACONICA="$ROOT/plugins/core/output-styles/laconica.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -f "$SENIOR" ] || fail "Senior output style is missing"
[ ! -e "$LACONICA" ] || fail "Laconica must be merged into Senior and removed"

python3 - "$SENIOR" <<'PY2'
from pathlib import Path
import sys

body = Path(sys.argv[1]).read_text().lower()
required = (
    "compress the wording, not the facts",
    "short but grammatical",
    "one fact per line",
    "lists over paragraphs",
    "never compress",
    "order-critical",
    "natural, complete sentences",
    "material trade-offs",
)
for phrase in required:
    assert phrase in body, phrase
print("unified Senior output style tests passed")
PY2
