#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT/plugins/core/skills/nontech/SKILL.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -f "$SKILL" ] || fail "nontech skill is missing"

python3 - "$SKILL" <<'PY2'
from pathlib import Path
import sys
import yaml

path = Path(sys.argv[1])
content = path.read_text()
assert content.startswith("---\n")
_, frontmatter, body = content.split("---\n", 2)
metadata = yaml.safe_load(frontmatter)
assert metadata["name"] == "devkit-nontech"
description = metadata["description"].lower()
for trigger in ("non-technical", "для менеджера", "простыми словами"):
    assert trigger in description, trigger

body_lower = body.lower()
for forbidden_detail in (
    "file paths",
    "file names",
    "table names",
    "column names",
    "class names",
    "function names",
    "stack traces",
):
    assert forbidden_detail in body_lower, forbidden_detail

for audience_fact in (
    "what happened",
    "impact",
    "current status",
    "what was done",
    "next step",
):
    assert audience_fact in body_lower, audience_fact

assert "do not invent" in body_lower
assert "always writes the final answer in russian" in description
assert "write the entire final answer in russian" in body_lower
assert "regardless of the user's language" in body_lower
assert "output only the audience-ready text" in body_lower
assert "bare invocation rewrites the immediately preceding assistant response" in description
assert "when neither is supplied" in body_lower
assert "rewrite the immediately preceding assistant response" in body_lower
assert "do not ask the user to paste it again" in body_lower
print("nontech skill tests passed")
PY2
