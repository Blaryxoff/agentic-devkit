#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT/plugins/core/skills/estimate/SKILL.md"

python3 - "$SKILL" <<'PY'
from pathlib import Path
import sys
import yaml

skill = Path(sys.argv[1]).read_text()
assert skill.startswith("---\n")
_, frontmatter, body = skill.split("---\n", 2)
metadata = yaml.safe_load(frontmatter)
assert metadata["name"] == "devkit-estimate"

description = " ".join(metadata["description"].lower().split())
for trigger in (
    "estimate this task",
    "how long will development take",
    "agent-first",
    "vibe-coding",
    "agent-led development elapsed time",
    "direct paste",
):
    assert trigger in description, trigger

rules = " ".join(body.lower().split())
for rule in (
    "through focused self-checks and handoff",
    "agent runtime and passive test runtime cost zero developer hours",
    "default to elapsed time for an agent-led implementation",
    "include agent execution, attended review, corrections",
    "agent-led elapsed by default, attended developer hours when explicitly requested",
    "external qa, fixes found after handoff, deployment",
    "a planned prerequisite owned by another task is a dependency, not hours",
    "count the shared work once",
    "read its latest scoped figure and later scope decisions",
    "exact and continuation behavior already delivered costs zero",
    "a foundation promised by a separately estimated predecessor",
    "a prior estimate is a planning anchor, not measured duration",
    "if a smaller follow-on task takes longer",
    "use one connected implementation lane by default",
    "count an interval once when it covers several screens",
    "longest dependency path plus integration",
    "a traditional coding estimate divided by eight is only a low-confidence starting point",
    "default to one likely elapsed-hour figure",
    "attended developer hours separately when requested",
    "recalculate when a user challenges the figure",
    "return only a self-contained message",
    "assume the recipient has not seen this conversation",
    "до передачи на тестирование",
    "do not add calendar days, deployment, qa cycles",
    "use no markdown table",
    "do not create a report file unless asked",
    "the text can be pasted into a fresh chat",
    "../../conduct/readiness-gate.md",
):
    assert rule in rules, rule

for stale in (
    "production = beta +",
    "open with one table",
    "merge/rollout",
    "rollout margin",
):
    assert stale not in rules, stale

assert len(body.splitlines()) < 180
print("estimate skill tests passed")
PY
