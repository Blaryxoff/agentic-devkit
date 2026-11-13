#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/tests/learn-history.py"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
. "$ROOT/adapters/_lib/claude_agents.sh"
mkdir -p "$TMP/cursor" "$TMP/claude"
emit_subagent "$ROOT/plugins/core/skills/mine/SKILL.md" "$TMP/cursor" cursor >/dev/null
emit_subagent "$ROOT/plugins/core/skills/mine/SKILL.md" "$TMP/claude" claude >/dev/null
python3 - "$TMP" <<'PY'
from pathlib import Path
import sys
import yaml

root = Path(sys.argv[1])
for harness in ['cursor', 'claude']:
    path = root / harness / 'devkit-mine.md'
    meta = yaml.safe_load(path.read_text().split('---', 2)[1])
    assert meta['name'] == 'devkit-mine'
    if harness == 'cursor':
        assert meta['readonly'] is True
        assert 'tools' not in meta
    else:
        assert set(meta['tools'].replace(',', ' ').split()) == {'Read', 'Glob', 'Grep'}
PY

echo "learn skill tests passed"
