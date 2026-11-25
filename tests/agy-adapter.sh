#!/usr/bin/env bash
# Covers adapters/agy/generate: skill links, rules, MCP config, hooks, and collision gates.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

CLONE="$TMP_DIR/relocated-clone"
PROJECT="$TMP_DIR/project"
HOME_DIR="$TMP_DIR/home"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mkdir -p "$CLONE" "$HOME_DIR" "$PROJECT/.devkit"
tar -cf - --exclude .git -C "$ROOT" . | tar -xf - -C "$CLONE"
git -C "$PROJECT" init -q

# A fixture plugin with a real skill
mkdir -p "$CLONE/plugins/fixture/custom-skills/real" "$CLONE/plugins/fixture/custom-skills/empty"
printf -- '---\nname: devkit-fixture-real\ndescription: fixture\n---\n\nbody\n' \
  > "$CLONE/plugins/fixture/custom-skills/real/SKILL.md"
jq -n '{name:"devkit-fixture", version:"1.0.0", description:"fixture plugin",
        layer:"stack", defaultEnabled:false, dependencies:[],
        paths:{skills:"./custom-skills", conduct:"./conduct"}}' > "$CLONE/plugins/fixture/plugin.json"
mkdir -p "$CLONE/plugins/fixture/conduct"
printf -- '# Fixture conduct\n' > "$CLONE/plugins/fixture/conduct/overview.md"

printf '%s\n' '{"version":1,"enabled":["devkit-css","devkit-fixture","devkit-nestjs","devkit-nextjs","devkit-tailwind"]}' > "$PROJECT/.devkit/toolkit.json"

run_adapter() {
  DEVKIT_PROJECT_ROOT="$PROJECT" HOME="$HOME_DIR" bash "$CLONE/adapters/$1/generate"
}

out="$TMP_DIR/agy.out"
run_adapter agy > "$out" 2>&1 || fail "agy adapter exited non-zero: $(tail -3 "$out")"

# --- Skill links in .agents/skills/<skill-name> ---
skills_dir="$PROJECT/.agents/skills"
[ -d "$skills_dir" ] || fail ".agents/skills directory missing"
[ -L "$skills_dir/devkit-fixture-real" ] || fail "devkit-fixture-real was not linked"
[ ! -e "$skills_dir/empty" ] || fail "directory without SKILL.md was linked"

# --- Rules in .agents/rules/devkit-*.md ---
rules_dir="$PROJECT/.agents/rules"
[ -d "$rules_dir" ] || fail ".agents/rules directory missing"
[ -f "$rules_dir/devkit-core.md" ] || fail "devkit-core.md rule missing"
[ -f "$rules_dir/devkit-fixture.md" ] || fail "devkit-fixture.md rule missing"
grep -Fq 'alwaysApply: true' "$rules_dir/devkit-core.md" || fail "devkit-core.md missing alwaysApply"
grep -Fq 'overview.md' "$rules_dir/devkit-fixture.md" || fail "devkit-fixture.md missing conduct link"

# --- MCP config in .agents/mcp_config.json ---
mcp_file="$PROJECT/.agents/mcp_config.json"
[ -f "$mcp_file" ] || fail ".agents/mcp_config.json missing"
jq -e 'has("mcpServers")' "$mcp_file" >/dev/null || fail ".agents/mcp_config.json missing mcpServers"

# --- Hooks in .agents/hooks.json ---
hooks_file="$PROJECT/.agents/hooks.json"
[ -f "$hooks_file" ] || fail ".agents/hooks.json missing"
jq -e '.devkit.PreToolUse | length >= 4' "$hooks_file" >/dev/null || fail "PreToolUse gates missing in .agents/hooks.json"
jq -e '[.devkit.PreToolUse[].matcher | select(. == "run_command")] | length >= 2' "$hooks_file" >/dev/null \
  || fail "run_command matcher missing for server/peer gates"
jq -e '[.devkit.PreToolUse[].matcher | select(. == "edit_file|write_file")] | length >= 2' "$hooks_file" >/dev/null \
  || fail "edit_file|write_file matcher missing for coder/comment gates"
jq -e '.devkit.SessionStart | length >= 1' "$hooks_file" >/dev/null || fail "SessionStart hook missing"
jq -e '.devkit.UserPromptSubmit | length >= 1' "$hooks_file" >/dev/null || fail "UserPromptSubmit hook missing"

# --- .gitignore entry ---
grep -Fq '.agents/' "$PROJECT/.gitignore" || fail ".agents/ missing from .gitignore"

# --- Clean stale links and preserve user files ---
ln -s "$CLONE/plugins/core/skills/coder" "$skills_dir/stale-skill"
mkdir -p "$skills_dir/user-skill"
touch "$skills_dir/user-skill/SKILL.md"

run_adapter agy > "$out" 2>&1 || fail "second agy adapter run failed"
[ ! -L "$skills_dir/stale-skill" ] || fail "stale skill link was not reaped"
[ -d "$skills_dir/user-skill" ] || fail "user skill was reaped"

# --- Collision check: non-symlink collision fails safely ---
touch "$skills_dir/devkit-fixture-real.tmp"
rm -f "$skills_dir/devkit-fixture-real"
touch "$skills_dir/devkit-fixture-real" # regular file now occupies the skill path
if run_adapter agy > "$out" 2>&1; then
  fail "agy adapter should have failed on non-symlink collision"
fi
grep -Fq 'occupied by a non-symlink' "$out" || fail "wrong error message for collision: $(cat "$out")"

echo "agy-adapter: all assertions passed"
