#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_link() {
  local path="$1"
  local target="$2"
  [ -L "$path" ] || fail "expected symlink: $path"
  [ "$(readlink "$path")" = "$target" ] || fail "unexpected target for $path"
}

assert_absent() {
  [ ! -e "$1" ] && [ ! -L "$1" ] || fail "expected absent: $1"
}

assert_contains() {
  grep -Fq "$2" "$1" || fail "expected $1 to contain: $2"
}

assert_not_contains() {
  if grep -Fq "$2" "$1"; then
    fail "expected $1 not to contain: $2"
  fi
}

skill_snapshot() {
  local skills_dir="$1"
  find "$skills_dir" -type l -print | sort | while IFS= read -r link; do
    printf '%s -> %s\n' "$(basename "$link")" "$(readlink "$link")"
  done
}

home="$TMP_DIR/home"
codex_home="$home/.codex"
cursor_home="$home/.cursor"
claude_home="$home/.claude"
mkdir -p "$codex_home/skills" "$cursor_home/skills" "$claude_home"
ln -s "$ROOT/plugins/css/skills/css-a11y" "$codex_home/skills/devkit-css--css-a11y"
ln -s "$ROOT/plugins/laravel/skills/architect" "$cursor_home/skills/devkit-laravel--architect"
ln -s "$ROOT/plugins/core/skills/coder" "$codex_home/skills/user-skill"
printf '%s\n' 'personal global guidance' > "$claude_home/CLAUDE.md"
legacy_skill_eval="sh $ROOT/plugins/core/hooks/skill-eval.sh"
jq -n --arg legacy "$legacy_skill_eval" '{hooks:{UserPromptSubmit:[{hooks:[{type:"command",command:$legacy},{type:"command",command:"custom-prompt-hook"}]}]}}' \
  > "$claude_home/settings.json"

install_output=$(HOME="$home" CODEX_HOME="$codex_home" CURSOR_HOME="$cursor_home" DEVKIT_HOME_DIR="$ROOT" \
  bash "$ROOT/bin/devkit-install")

assert_link "$codex_home/skills/devkit-core--coder" "$ROOT/plugins/core/skills/coder"
assert_link "$codex_home/skills/devkit-core--devkit-router" "$ROOT/plugins/core/skills/devkit-router"
assert_absent "$codex_home/skills/devkit-css--css-a11y"
assert_absent "$codex_home/skills/devkit-laravel--architect"
assert_link "$codex_home/skills/user-skill" "$ROOT/plugins/core/skills/coder"
assert_link "$cursor_home/skills/devkit-core--coder" "$ROOT/plugins/core/skills/coder"
assert_absent "$cursor_home/skills/devkit-laravel--architect"
[[ "$install_output" == *"Cursor stack skills are now project-scoped"* ]] \
  || fail "Cursor project-skill migration notice was not emitted"
assert_contains "$claude_home/CLAUDE.md" 'personal global guidance'
assert_contains "$claude_home/CLAUDE.md" '<!-- devkit-skill-policy:start -->'
assert_contains "$claude_home/CLAUDE.md" 'Skill selection starts from the catalog metadata.'
assert_contains "$claude_home/CLAUDE.md" "$ROOT/plugins/core/conduct/learning-capture-gate.md"
assert_contains "$claude_home/CLAUDE.md" 'Skill(devkit-core--learn)'
assert_not_contains "$claude_home/CLAUDE.md" '{{DEVKIT_HOME}}'
assert_contains "$claude_home/settings.json" 'skill-eval.sh'
assert_contains "$claude_home/settings.json" 'custom-prompt-hook'
[ "$(jq '[.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains("skill-eval.sh"))] | length' "$claude_home/settings.json")" = "1" ] \
  || fail "expected one skill-eval hook"
assert_link "$claude_home/output-styles/laconica.md" "$ROOT/plugins/core/output-styles/laconica.md"
assert_absent "$claude_home/output-styles/laconica-ru.md"
[ "$(jq -r '.outputStyle' "$claude_home/settings.json")" = "Laconica" ] \
  || fail "expected Laconica default output style"

skill_eval_output=$(sh "$ROOT/plugins/core/hooks/skill-eval.sh")
[[ "$skill_eval_output" == *"$ROOT/plugins/core/conduct/learning-capture-gate.md"* ]] \
  || fail "skill-eval hook did not resolve the installed learning gate"
[[ "$skill_eval_output" == *"Skill(devkit-core--learn)"* ]] \
  || fail "skill-eval hook did not emit the Claude learn slug"

first_claude_guidance=$(cksum < "$claude_home/CLAUDE.md")
jq '.outputStyle = "Laconica RU"' "$claude_home/settings.json" > "$claude_home/settings.json.tmp"
mv "$claude_home/settings.json.tmp" "$claude_home/settings.json"
HOME="$home" CODEX_HOME="$codex_home" CURSOR_HOME="$cursor_home" DEVKIT_HOME_DIR="$ROOT" \
  bash "$ROOT/bin/devkit-install" >/dev/null
[ "$first_claude_guidance" = "$(cksum < "$claude_home/CLAUDE.md")" ] || fail "global CLAUDE.md generation is not idempotent"
[ "$(jq '[.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains("skill-eval.sh"))] | length' "$claude_home/settings.json")" = "1" ] \
  || fail "skill-eval hook installation is not idempotent"
[ "$(jq -r '.outputStyle' "$claude_home/settings.json")" = "Laconica" ] \
  || fail "legacy Laconica RU output style was not migrated"

project="$TMP_DIR/project"
mkdir -p "$project/.devkit" "$project/.codex/skills/custom-skill" "$project/.cursor/skills/custom-skill"
git -C "$project" init -q
printf '%s\n' 'project-local-entry' > "$project/.gitignore"
printf '%s\n' '{"version":1,"enabled":["devkit-laravel","devkit-vue","devkit-inertia","devkit-tailwind"]}' \
  > "$project/.devkit/toolkit.json"
ln -s "$ROOT/plugins/css/skills/css-a11y" "$project/.codex/skills/devkit-css--css-a11y"

DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/codex/generate" >/dev/null

assert_contains "$project/.gitignore" 'project-local-entry'
assert_contains "$project/.gitignore" '.codex/'
assert_absent "$project/.codex/skills/devkit-core--coder"
assert_link "$project/.codex/skills/devkit-frontend--pixel-build" "$ROOT/plugins/frontend/skills/pixel-build"
assert_link "$project/.codex/skills/devkit-laravel--architect" "$ROOT/plugins/laravel/skills/architect"
assert_absent "$project/.codex/skills/devkit-css--css-a11y"
[ -d "$project/.codex/skills/custom-skill" ] || fail "custom skill directory was removed"
assert_contains "$project/AGENTS.md" '### devkit-core'
assert_contains "$project/AGENTS.md" '### devkit-frontend'
assert_contains "$project/AGENTS.md" '### devkit-vue'
assert_contains "$project/AGENTS.md" '### devkit-inertia'
assert_contains "$project/AGENTS.md" '### devkit-laravel'
assert_contains "$project/AGENTS.md" '### devkit-tailwind'
assert_not_contains "$project/AGENTS.md" '### devkit-css'
assert_contains "$project/AGENTS.md" 'plugins/core/conduct/overview.md'
assert_contains "$project/AGENTS.md" '~/.claude/agentic-devkit/plugins/core/conduct/learning-capture-gate.md'
assert_contains "$project/AGENTS.md" 'Codex/Cursor activate `devkit-learn`'
assert_not_contains "$project/AGENTS.md" '{{DEVKIT_HOME}}'
assert_contains "$project/AGENTS.md" 'plugins/laravel/conduct/overview.md'
assert_not_contains "$project/AGENTS.md" 'plugins/core/conduct/docker-deployment.md'
assert_not_contains "$project/AGENTS.md" 'plugins/laravel/conduct/architecture.md'

DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/cursor/generate" >/dev/null
assert_absent "$project/.cursor/skills/devkit-core--coder"
assert_link "$project/.cursor/skills/devkit-frontend--pixel-build" "$ROOT/plugins/frontend/skills/pixel-build"
assert_link "$project/.cursor/skills/devkit-laravel--architect" "$ROOT/plugins/laravel/skills/architect"
[ -d "$project/.cursor/skills/custom-skill" ] || fail "custom Cursor skill directory was removed"
assert_contains "$project/.cursor/rules/devkit-core.mdc" 'plugins/core/conduct/overview.md'
assert_contains "$project/.cursor/rules/devkit-core.mdc" '~/.claude/agentic-devkit/plugins/core/conduct/learning-capture-gate.md'
assert_contains "$project/.cursor/rules/devkit-core.mdc" 'Codex/Cursor activate `devkit-learn`'
assert_not_contains "$project/.cursor/rules/devkit-core.mdc" '{{DEVKIT_HOME}}'
assert_contains "$project/.cursor/rules/devkit-laravel.mdc" 'plugins/laravel/conduct/overview.md'
assert_not_contains "$project/.cursor/rules/devkit-core.mdc" 'plugins/core/conduct/docker-deployment.md'
assert_not_contains "$project/.cursor/rules/devkit-laravel.mdc" 'plugins/laravel/conduct/architecture.md'

first_cursor_skills=$(skill_snapshot "$project/.cursor/skills")
first_cursor_core_rule=$(cksum < "$project/.cursor/rules/devkit-core.mdc")
DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/cursor/generate" >/dev/null
[ "$first_cursor_skills" = "$(skill_snapshot "$project/.cursor/skills")" ] || fail "Cursor skill regeneration is not idempotent"
[ "$first_cursor_core_rule" = "$(cksum < "$project/.cursor/rules/devkit-core.mdc")" ] || fail "Cursor rule regeneration is not idempotent"

first_skills=$(skill_snapshot "$project/.codex/skills")
first_agents=$(cksum < "$project/AGENTS.md")
DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/codex/generate" >/dev/null
[ "$first_skills" = "$(skill_snapshot "$project/.codex/skills")" ] || fail "skill regeneration is not idempotent"
[ "$first_agents" = "$(cksum < "$project/AGENTS.md")" ] || fail "AGENTS.md regeneration is not idempotent"

printf '%s\n' '{"version":1,"enabled":["devkit-css"]}' > "$project/.devkit/toolkit.json"
DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/codex/generate" >/dev/null
DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/cursor/generate" >/dev/null

assert_link "$project/.codex/skills/devkit-css--css-a11y" "$ROOT/plugins/css/skills/css-a11y"
assert_absent "$project/.codex/skills/devkit-frontend--pixel-build"
assert_absent "$project/.codex/skills/devkit-laravel--architect"
assert_contains "$project/AGENTS.md" '### devkit-css'
assert_not_contains "$project/AGENTS.md" '### devkit-laravel'
[ -d "$project/.codex/skills/custom-skill" ] || fail "custom skill directory was removed"
assert_link "$project/.cursor/skills/devkit-css--css-a11y" "$ROOT/plugins/css/skills/css-a11y"
assert_absent "$project/.cursor/skills/devkit-frontend--pixel-build"
assert_absent "$project/.cursor/skills/devkit-laravel--architect"
[ -d "$project/.cursor/skills/custom-skill" ] || fail "custom Cursor skill directory was removed"
assert_contains "$project/.cursor/rules/devkit-core.mdc" 'plugins/core/conduct/overview.md'
assert_contains "$project/.cursor/rules/devkit-css.mdc" 'plugins/css/conduct/overview.md'
for disabled_rule in frontend inertia laravel tailwind vue; do
  assert_absent "$project/.cursor/rules/devkit-${disabled_rule}.mdc"
done

collision_project="$TMP_DIR/collision-project"
mkdir -p "$collision_project/.devkit" \
  "$collision_project/.codex/skills/devkit-css--css-a11y" \
  "$collision_project/.cursor/skills/devkit-css--css-a11y"
printf '%s\n' '{"version":1,"enabled":["devkit-css"]}' > "$collision_project/.devkit/toolkit.json"
if DEVKIT_PROJECT_ROOT="$collision_project" bash "$ROOT/adapters/codex/generate" >/dev/null 2>&1; then
  fail "Codex adapter accepted an occupied enabled-skill destination"
fi
if DEVKIT_PROJECT_ROOT="$collision_project" bash "$ROOT/adapters/cursor/generate" >/dev/null 2>&1; then
  fail "Cursor adapter accepted an occupied enabled-skill destination"
fi
[ -d "$collision_project/.codex/skills/devkit-css--css-a11y" ] \
  || fail "Codex collision path was mutated"
[ -d "$collision_project/.cursor/skills/devkit-css--css-a11y" ] \
  || fail "Cursor collision path was mutated"

echo "codex adapter tests passed"
