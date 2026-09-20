#!/usr/bin/env bash
# Covers adapters/cursor/generate beyond the skill links and .mdc files that
# codex-adapter.sh already asserts: the hook commands' clone path, paths.skills,
# the SKILL.md requirement, and per-plugin rule globs.
#
# The clone is copied to a non-default location on purpose — a hook command built
# from a hardcoded ~/.claude/agentic-devkit passes every test run from the real one.

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

# A plugin whose skills live outside the conventional ./skills directory, holding one
# real skill and one directory that is not a skill.
mkdir -p "$CLONE/plugins/fixture/custom-skills/real" "$CLONE/plugins/fixture/custom-skills/empty"
printf -- '---\nname: devkit-fixture-real\ndescription: fixture\n---\n\nbody\n' \
  > "$CLONE/plugins/fixture/custom-skills/real/SKILL.md"
jq -n '{name:"devkit-fixture", version:"1.0.0", description:"fixture plugin",
        layer:"stack", defaultEnabled:false, dependencies:[],
        paths:{skills:"./custom-skills"}}' > "$CLONE/plugins/fixture/plugin.json"

# A directory with no SKILL.md inside a conventional plugin must not be linked either.
mkdir -p "$CLONE/plugins/css/skills/not-a-skill"

printf '%s\n' '{"version":1,"enabled":["devkit-css","devkit-fixture"]}' > "$PROJECT/.devkit/toolkit.json"

run_adapter() {
  DEVKIT_PROJECT_ROOT="$PROJECT" HOME="$HOME_DIR" bash "$CLONE/adapters/$1/generate"
}

out="$TMP_DIR/cursor.out"
run_adapter cursor > "$out" 2>&1 || fail "cursor adapter exited non-zero: $(tail -3 "$out")"

# --- hook commands point at the clone that generated them ----------------------

hooks="$PROJECT/.cursor/hooks/hooks.json"
[ -f "$hooks" ] || fail "no .cursor/hooks/hooks.json was written"
commands=$(jq -r '[.. | objects | select(has("command")) | .command] | join("\n")' "$hooks")
[ -n "$commands" ] || fail "no hook commands in hooks.json"
printf '%s\n' "$commands" | grep -q "$CLONE/bin/devkit-update" \
  || fail "the auto-update hook does not point at the clone that generated it: $commands"
for gate in coder-gate.sh comment-gate.sh; do
  printf '%s\n' "$commands" | grep -q "$CLONE/plugins/core/hooks/$gate" \
    || fail "$gate does not point at the clone that generated it: $commands"
done
printf '%s\n' "$commands" | grep -q "$HOME_DIR/.claude/agentic-devkit" \
  && fail "a hook command still uses the hardcoded default clone location"
while IFS= read -r cmd; do
  script=$(printf '%s\n' "$cmd" | sed "s/^sh '//; s/'$//; s/ --if-stale$//")
  [ -e "$script" ] || fail "hook command target does not exist: $script"
done <<< "$commands"

# --- paths.skills and the SKILL.md requirement ---------------------------------

[ -L "$PROJECT/.cursor/skills/devkit-fixture--real" ] \
  || fail "a skill under a declared paths.skills directory was not linked"
[ -e "$PROJECT/.cursor/skills/devkit-fixture--empty" ] \
  && fail "a directory without SKILL.md was linked as a skill"
[ -e "$PROJECT/.cursor/skills/devkit-css--not-a-skill" ] \
  && fail "a directory without SKILL.md was linked as a skill"

# --- rule globs ----------------------------------------------------------------

css_rule="$PROJECT/.cursor/rules/devkit-css.mdc"
[ -f "$css_rule" ] || fail "no rule file for devkit-css"
globs=$(sed -n 's/^globs:[[:space:]]*//p' "$css_rule" | head -1)
case "$globs" in
  '**/*' | '["**/*"]') fail "devkit-css still falls through to the catch-all glob" ;;
esac
printf '%s\n' "$globs" | grep -q '\*\*/\*\.css' || fail "devkit-css globs do not include css: $globs"

# --- the Codex adapter shares both skill-linking defects ------------------------

run_adapter codex > "$TMP_DIR/codex.out" 2>&1 || fail "codex adapter exited non-zero"
[ -L "$PROJECT/.codex/skills/devkit-fixture--real" ] \
  || fail "codex ignored paths.skills"
[ -e "$PROJECT/.codex/skills/devkit-fixture--empty" ] \
  && fail "codex linked a directory without SKILL.md"
[ -e "$PROJECT/.codex/skills/devkit-css--not-a-skill" ] \
  && fail "codex linked a directory without SKILL.md"

echo "cursor adapter tests passed"
