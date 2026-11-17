#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
CLONE="$TMP_DIR/relocated clone"
PROJECT="$TMP_DIR/project"
HOME_DIR="$TMP_DIR/home"

fail() { echo "FAIL: $*" >&2; exit 1; }

mkdir -p "$CLONE/adapters" "$CLONE/plugins" "$CLONE/bin" "$HOME_DIR/.grok" "$PROJECT/.devkit"
cp -R "$ROOT/adapters/_lib" "$ROOT/adapters/claude" "$ROOT/adapters/grok" "$CLONE/adapters/"
cp -R "$ROOT/plugins/core" "$CLONE/plugins/"
cp "$ROOT/bin/devkit-update" "$CLONE/bin/"
cp -R "$ROOT/schemas" "$CLONE/"
printf '%s\n' 'User Grok guidance.' > "$HOME_DIR/.grok/AGENTS.md"
printf '%s\n' '[compat.cursor]' 'hooks = false' > "$HOME_DIR/.grok/config.toml"
cp "$HOME_DIR/.grok/config.toml" "$TMP_DIR/config.before"
printf '%s\n' '{"canonical_dev_servers":true}' > "$CLONE/projects.json"

run_install() { HOME="$HOME_DIR" bash "$CLONE/adapters/grok/install"; }
run_install > "$TMP_DIR/install.out" 2>&1 || fail "Grok install failed"
hooks="$HOME_DIR/.grok/hooks/devkit-toolkit.json"
[ -f "$hooks" ] || fail "Grok native hook was not installed"
jq -e '.hooks.PreToolUse | length == 1' "$hooks" >/dev/null || fail "native gate registration missing"
jq -e '.hooks.UserPromptSubmit | length == 1' "$hooks" >/dev/null || fail "native feedback registration missing"
feedback_command=$(jq -r '.hooks.UserPromptSubmit[0].hooks[0].command' "$hooks")
[[ "$feedback_command" == *"$CLONE/plugins/core/hooks/jev-feedback.py"* ]] || fail "feedback lost relocated clone path"
command=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$hooks")
[[ "$command" == *"$CLONE/adapters/grok/hook.py"* ]] || fail "hook lost relocated clone path"
[[ "$command" == *"--require-server-config"* ]] || fail "managed runtime requirement was not pinned"
grep -Fq 'User Grok guidance.' "$HOME_DIR/.grok/AGENTS.md" || fail "user guidance was overwritten"
grep -Fq 'read its SKILL.md' "$HOME_DIR/.grok/AGENTS.md" || fail "Grok activation guidance missing"
grep -Fq 'projects_status' "$HOME_DIR/.grok/AGENTS.md" || fail "Grok did not inject the devkit-projects MCP rule"
cmp "$TMP_DIR/config.before" "$HOME_DIR/.grok/config.toml" || fail "user TOML was changed"
cp "$HOME_DIR/.grok/AGENTS.md" "$TMP_DIR/agents.before"
jq '.hooks.PreToolUse += [{hooks:[{type:"command",command:"user-hook"}]}] | .hooks.UserPromptSubmit += [{hooks:[{type:"command",command:"user-prompt-hook"}]}]' "$hooks" > "$TMP_DIR/hooks.json"
mv "$TMP_DIR/hooks.json" "$hooks"
run_install > "$TMP_DIR/install.out" 2>&1 || fail "second Grok install failed"
cmp "$TMP_DIR/agents.before" "$HOME_DIR/.grok/AGENTS.md" || fail "guidance is not idempotent"
jq -e '[.hooks.PreToolUse[].hooks[].command | select(. == "user-hook")] | length == 1' "$hooks" >/dev/null \
  || fail "user native hook was lost"
jq -e '[.hooks.PreToolUse[].hooks[].command | select(contains("adapters/grok/hook.py"))] | length == 1' "$hooks" >/dev/null \
  || fail "managed gate was duplicated"
jq -e '[.hooks.UserPromptSubmit[].hooks[].command | select(contains("jev-feedback.py"))] | length == 1' "$hooks" >/dev/null \
  || fail "managed feedback was duplicated"
jq -e '[.hooks.UserPromptSubmit[].hooks[].command | select(. == "user-prompt-hook")] | length == 1' "$hooks" >/dev/null \
  || fail "user prompt hook was lost"
[ ! -e "$HOME_DIR/.grok/trusted_folders.toml" ] || fail "install silently trusted projects"
printf '%s\n' 'not JSON' > "$CLONE/projects.json"
run_install > "$TMP_DIR/install.out" 2>&1 || fail "Grok reinstall failed with temporarily unreadable runtime config"
jq -e '[.hooks.PreToolUse[].hooks[].command | select(contains("--require-server-config"))] | length == 1' "$hooks" >/dev/null \
  || fail "Grok reinstall dropped the required runtime config boundary"
printf '%s\n' '{"canonical_dev_servers":true}' > "$CLONE/projects.json"

mkdir -p "$CLONE/plugins/fixture/skills/inline"
printf -- '---\nname: devkit-fixture-inline\ndescription: fixture\n---\nbody\n' > "$CLONE/plugins/fixture/skills/inline/SKILL.md"
printf '%s\n' '{"mcpServers":{"fixture":{"command":"fixture-command"}}}' > "$CLONE/plugins/fixture/mcp.json"
printf '%s\n' '{"hooks":{"PostToolUse":[{"matcher":"Read","hooks":[{"type":"command","command":"fixture-hook","timeout":30000}]}]}}' > "$CLONE/plugins/fixture/hooks.json"
printf '%s\n' '{"name":"devkit-fixture","version":"1.0.0","description":"fixture","layer":"stack","defaultEnabled":false,"dependencies":[],"paths":{"skills":"./skills","mcpServers":"./mcp.json","hooks":"./hooks.json"}}' > "$CLONE/plugins/fixture/plugin.json"
printf '%s\n' '{"version":1,"enabled":["devkit-fixture"]}' > "$PROJECT/.devkit/toolkit.json"
printf '%s\n' '{"mcpServers":{"user":{"command":"user-server"},"fixture":{"command":"user-fixture-override"}}}' > "$PROJECT/.mcp.json"
HOME="$HOME_DIR" DEVKIT_PROJECT_ROOT="$PROJECT" bash "$CLONE/adapters/grok/generate" > "$TMP_DIR/generate.out" 2>&1 \
  || fail "Grok project adapter failed: $(tail -3 "$TMP_DIR/generate.out")"
[ -L "$PROJECT/.claude/skills/devkit-fixture--inline" ] || fail "resolved Grok-compatible stack skill missing"
jq -e '.mcpServers.user.command == "user-server" and .mcpServers.fixture.command == "user-fixture-override"' "$PROJECT/.mcp.json" >/dev/null \
  || fail "project MCP merge lost user entries"
jq -e '.hooks.PostToolUse[0].hooks[0].timeout == 30' "$PROJECT/.claude/settings.json" >/dev/null \
  || fail "project hooks were not rendered in Grok-compatible Claude format"

HOME="$HOME_DIR" TMPDIR="$TMP_DIR" python3 - "$CLONE" <<'PY'
import json
from pathlib import Path
import subprocess
import sys
import uuid

root = Path(sys.argv[1])
script = root / "adapters/grok/hook.py"
sid = "grok-adapter-" + uuid.uuid4().hex
fixture = str(root / "fixture.js")


def run(tool, inputs, denied):
    payload = {"sessionId": sid, "toolName": tool, "toolInput": inputs}
    result = subprocess.run(["python3", str(script)], input=json.dumps(payload), text=True, capture_output=True)
    output = json.loads(result.stdout) if result.stdout.strip() else {}
    assert result.returncode == 0, (tool, result.stderr)
    assert (output.get("decision") == "deny") == denied, (tool, output)


run("search_replace", {"file_path": fixture, "old_string": "a", "new_string": "b"}, True)
run("read_file", {"target_file": str(root / "plugins/core/skills/coder/SKILL.md")}, False)
run("search_replace", {"file_path": fixture, "old_string": "a", "new_string": "b"}, False)
run("search_replace", {"file_path": fixture, "new_string": "// Changed this function to fix the bug\nconst a = 2;"}, True)
run("run_terminal_command", {"command": "cursor-agent -p 'test'"}, True)
run("run_terminal_command", {"command": "git status --short"}, False)
run("context7__query_docs", {"query": "example"}, False)
result = subprocess.run(["python3", str(script)], input="not JSON", text=True, capture_output=True)
assert json.loads(result.stdout)["decision"] == "deny"
PY

PUBLIC_PROJECT="$TMP_DIR/public-project"
mkdir -p "$PUBLIC_PROJECT/.devkit"
printf '%s\n' '{"version":1,"enabled":["devkit-laravel"]}' > "$PUBLIC_PROJECT/.devkit/toolkit.json"
HOME="$HOME_DIR" DEVKIT_HOME_DIR="$ROOT" bash "$ROOT/bin/devkit-install" --grok --project="$PUBLIC_PROJECT" \
  > "$TMP_DIR/public-install.out" 2>&1 || fail "public --grok install failed: $(tail -3 "$TMP_DIR/public-install.out")"
HOME="$HOME_DIR" bash "$ROOT/bin/devkit-resolve" --adapter=grok --project="$PUBLIC_PROJECT" \
  > "$TMP_DIR/public-resolve.out" 2>&1 || fail "public Grok resolver failed"
[ -f "$PUBLIC_PROJECT/.claude/agents/devkit-architect.md" ] \
  || fail "public Grok stack subagent missing"
jq -e --arg path "$ROOT/adapters/grok/hook.py" \
  '[.hooks.PreToolUse[].hooks[].command | select(contains($path))] | length == 1' "$hooks" >/dev/null \
  || fail "public installer did not install the native Grok hook"

echo "Grok adapter checks passed"
