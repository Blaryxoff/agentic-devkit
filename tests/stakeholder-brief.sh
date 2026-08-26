#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT/plugins/core/skills/stakeholder-brief/SKILL.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -f "$SKILL" ] || fail "stakeholder-brief skill is missing"

python3 - "$SKILL" <<'PY2'
from pathlib import Path
import sys
import yaml

path = Path(sys.argv[1])
content = path.read_text()
assert content.startswith("---\n")
_, frontmatter, body = content.split("---\n", 2)
metadata = yaml.safe_load(frontmatter)
assert metadata["name"] == "devkit-stakeholder-brief"
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
assert "current conversation language" in body_lower
assert "output only the audience-ready text" in body_lower
print("stakeholder brief skill tests passed")
PY2
