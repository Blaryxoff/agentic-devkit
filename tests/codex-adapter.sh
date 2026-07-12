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
mkdir -p "$codex_home/skills" "$cursor_home/skills"
ln -s "$ROOT/plugins/css/skills/css-a11y" "$codex_home/skills/devkit-css--css-a11y"
ln -s "$ROOT/plugins/core/skills/coder" "$codex_home/skills/user-skill"

HOME="$home" CODEX_HOME="$codex_home" CURSOR_HOME="$cursor_home" DEVKIT_HOME_DIR="$ROOT" \
  bash "$ROOT/bin/devkit-install" >/dev/null

assert_link "$codex_home/skills/devkit-core--coder" "$ROOT/plugins/core/skills/coder"
assert_link "$codex_home/skills/devkit-core--devkit-router" "$ROOT/plugins/core/skills/devkit-router"
assert_absent "$codex_home/skills/devkit-css--css-a11y"
assert_absent "$codex_home/skills/devkit-laravel--architect"
assert_link "$codex_home/skills/user-skill" "$ROOT/plugins/core/skills/coder"
assert_link "$cursor_home/skills/devkit-laravel--architect" "$ROOT/plugins/laravel/skills/architect"

project="$TMP_DIR/project"
mkdir -p "$project/.devkit" "$project/.codex/skills/custom-skill"
printf '%s\n' '{"version":1,"enabled":["devkit-laravel","devkit-vue","devkit-inertia","devkit-tailwind"]}' \
  > "$project/.devkit/toolkit.json"
ln -s "$ROOT/plugins/css/skills/css-a11y" "$project/.codex/skills/devkit-css--css-a11y"

DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/codex/generate" >/dev/null

assert_link "$project/.codex/skills/devkit-core--coder" "$ROOT/plugins/core/skills/coder"
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

first_skills=$(skill_snapshot "$project/.codex/skills")
first_agents=$(cksum < "$project/AGENTS.md")
DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/codex/generate" >/dev/null
[ "$first_skills" = "$(skill_snapshot "$project/.codex/skills")" ] || fail "skill regeneration is not idempotent"
[ "$first_agents" = "$(cksum < "$project/AGENTS.md")" ] || fail "AGENTS.md regeneration is not idempotent"

printf '%s\n' '{"version":1,"enabled":["devkit-css"]}' > "$project/.devkit/toolkit.json"
DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/codex/generate" >/dev/null

assert_link "$project/.codex/skills/devkit-css--css-a11y" "$ROOT/plugins/css/skills/css-a11y"
assert_absent "$project/.codex/skills/devkit-frontend--pixel-build"
assert_absent "$project/.codex/skills/devkit-laravel--architect"
assert_contains "$project/AGENTS.md" '### devkit-css'
assert_not_contains "$project/AGENTS.md" '### devkit-laravel'
[ -d "$project/.codex/skills/custom-skill" ] || fail "custom skill directory was removed"

echo "codex adapter tests passed"
