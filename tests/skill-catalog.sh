#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/plugins/core/skills/skill-creator/scripts/catalog.py"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/current/alpha" "$tmp/.trash/retired" "$tmp/current/broken" "$tmp/current/other" "$tmp/current/malformed" "$tmp/current/valid" "$tmp/current/double"
cat > "$tmp/current/alpha/SKILL.md" <<'EOF'
---
name: devkit-alpha
description: Alpha skill.
---
Body is not part of the audit.
EOF
cat > "$tmp/current/valid/SKILL.md" <<'EOF'
---
name: devkit-quoted
description: 'A quoted description with doubled ''quotes''.'
short-description:
  en: Short summary.
allowed-tools:
  - Read
  - Bash
hooks: [PreToolUse, PostToolUse]
---
EOF
cat > "$tmp/current/double/SKILL.md" <<'EOF'
---
name: devkit-double
description: "Use \"quoted\" words."
---
EOF
ln -s "$tmp/current/alpha/SKILL.md" "$tmp/current/alpha-copy.md"
cat > "$tmp/current/other/SKILL.md" <<'EOF'
---
name: devkit-alpha
description: Alpha skill.
---
EOF
cat > "$tmp/current/broken/SKILL.md" <<'EOF'
---
name: wrong-name
description:
---
EOF
cat > "$tmp/current/malformed/SKILL.md" <<'EOF'
---
name: [broken
description: Malformed.
---
EOF
cat > "$tmp/.trash/retired/SKILL.md" <<'EOF'
---
name: devkit-retired
description: Retired.
---
EOF
python3 - "$tmp" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
snapshot = {
    "skills": [
        {"name": "devkit-alpha", "description": "Alpha skill.", "source": {"type": "file", "path": str(root / "current/alpha/SKILL.md")}},
        {"name": "devkit-alpha", "description": "Alpha skill.", "source": {"type": "file", "path": str(root / "current/alpha-copy.md")}},
        {"name": "devkit-alpha", "description": "Alpha skill.", "source": {"type": "file", "path": str(root / "current/other/SKILL.md")}},
        {"name": "devkit-retired", "description": "Retired.", "source": {"type": "file", "path": str(root / ".trash/retired/SKILL.md")}},
        {"name": "devkit-missing", "description": "Missing.", "source": {"type": "file", "path": str(root / "gone/SKILL.md")}},
        {"name": "devkit-wrong", "description": "", "source": {"type": "file", "path": str(root / "current/broken/SKILL.md")}},
        {"name": "devkit-bad", "description": "Malformed.", "source": {"type": "file", "path": str(root / "current/malformed/SKILL.md")}},
        {"name": "devkit-quoted", "description": "A quoted description with doubled 'quotes'.", "source": {"type": "file", "path": str(root / "current/valid/SKILL.md")}},
        {"name": "devkit-double", "description": 'Use "quoted" words.', "source": {"type": "file", "path": str(root / "current/double/SKILL.md")}},
        {"name": "devkit-wrong", "description": "", "source": {"type": "plugin", "path": "virtual://one"}},
    ],
    "mcpServers": [{"name": "safe-server", "type": "stdio", "url": "https://private.invalid/token", "command": "secret-command", "env": {"TOKEN": "secret-value"}}, {"name": {"TOKEN": "nested-secret"}, "type": ["secret-type"]}],
    "plugins": [{"name": "safe-plugin", "enabled": True, "config": {"secret": "secret-value"}}, {"name": {"TOKEN": "nested-secret"}, "enabled": {"secret": "nested-secret"}}],
}
(root / "snapshot.json").write_text(json.dumps(snapshot))
PY

python3 "$HELPER" --snapshot "$tmp/snapshot.json" > "$tmp/result.json"
python3 - "$tmp/result.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
issues = data["issues"]
codes = {issue["code"] for issue in issues}
assert "retired_source" in codes
assert "missing_source" in codes
assert "metadata_name_mismatch" in codes
assert "empty_description" in codes
assert "malformed_metadata" in codes
assert "duplicate_effective_name" in codes
assert not any(issue.get("name") in {"devkit-quoted", "devkit-double"} for issue in issues)
assert "secret-value" not in json.dumps(data)
assert "private.invalid" not in json.dumps(data)
assert "secret-command" not in json.dumps(data)
assert "safe-server" in {row["name"] for row in data["mcpServers"]}
assert {row["type"] for row in data["mcpServers"]} >= {"stdio", ""}
assert "nested-secret" not in json.dumps(data)
assert all(isinstance(row["name"], str) and isinstance(row["enabled"], bool) for row in data["plugins"])
PY

printf '{"skills":' > "$tmp/bad.json"
if python3 "$HELPER" --snapshot "$tmp/bad.json" >/dev/null 2>&1; then
  echo "FAIL: malformed JSON was accepted" >&2
  exit 1
fi

echo "PASS: skill catalog audit"
