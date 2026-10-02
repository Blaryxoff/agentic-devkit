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

assert "state impact, scope, cause, dates, percentages, and eta only when supported" in body_lower
assert "always writes the final answer in russian" in description
assert "write the entire final answer in russian" in body_lower
assert "regardless of the user's language" in body_lower
assert "begin directly with the audience-ready text" in body_lower
assert "bare invocation rewrites the immediately preceding assistant response" in description
assert "when neither is supplied" in body_lower
assert "use the immediately preceding assistant response" in body_lower
assert "if no preceding assistant response exists, ask the user for the source" in body_lower
for actionable_rule in (
    "preserve actionable instructions",
    "same actor, target, sequence, and conditions",
    "exact user-visible names of buttons",
    "открыть операцию №4352 и нажать «повторить завершение»",
    "rather than summarizing it as \"вручную повторить обработку операции\"",
    "a user-visible interface label is not a codebase internal",
    "without guessing which item to open",
):
    assert actionable_rule in body_lower, actionable_rule
print("nontech skill tests passed")
PY2
