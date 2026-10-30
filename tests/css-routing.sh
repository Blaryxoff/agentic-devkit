#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

make_project() {
  local project="$1" plugin="$2"
  mkdir -p "$project/.devkit"
  git -C "$project" init -q
  printf '{"version":1,"enabled":["%s"]}\n' "$plugin" > "$project/.devkit/toolkit.json"
}

generate() {
  local adapter="$1" project="$2"
  DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/$adapter/generate" \
    > "$TMP_DIR/$adapter.log" 2>&1 \
    || fail "$adapter generation failed: $(tail -3 "$TMP_DIR/$adapter.log")"
}

frontend="$TMP_DIR/frontend"
backend="$TMP_DIR/backend"
mkdir -p "$frontend" "$backend"
make_project "$frontend" devkit-nextjs
make_project "$backend" devkit-laravel

frontend_plugins=$(bash "$ROOT/bin/devkit-resolve" --project="$frontend") \
  || fail "frontend plugin resolution failed"
printf '%s\n' "$frontend_plugins" | grep -qx devkit-css \
  || fail "frontend stack did not resolve devkit-css"
backend_plugins=$(bash "$ROOT/bin/devkit-resolve" --project="$backend") \
  || fail "backend plugin resolution failed"
if printf '%s\n' "$backend_plugins" | grep -qx devkit-css; then
  fail "backend-only project resolved devkit-css"
fi

manual_skills=(css-a11y css-animate css-audit css-debug css-layout css-refactor css-responsive css-theme)
for skill in "${manual_skills[@]}"; do
  source_skill="$ROOT/plugins/css/skills/$skill/SKILL.md"
  grep -Fqx 'disable-model-invocation: true' "$source_skill" \
    || fail "$skill is not manual-only in Claude and Cursor"
  policy="$ROOT/plugins/css/skills/$skill/agents/openai.yaml"
  [ -f "$policy" ] || fail "$skill has no native OpenAI invocation policy"
  python3 - "$policy" <<'PY' || fail "$skill does not disable implicit OpenAI invocation"
import sys, yaml
with open(sys.argv[1], encoding="utf-8") as f:
    data = yaml.safe_load(f)
assert data == {"policy": {"allow_implicit_invocation": False}}, data
PY
done

expert_policy="$ROOT/plugins/css/skills/css-expert/agents/openai.yaml"
if [ -f "$expert_policy" ]; then
  python3 - "$expert_policy" <<'PY' || fail "css-expert must remain implicitly invocable"
import sys, yaml
with open(sys.argv[1], encoding="utf-8") as f:
    data = yaml.safe_load(f)
assert data.get("policy", {}).get("allow_implicit_invocation", True) is True, data
PY
fi
if grep -Fqx 'disable-model-invocation: true' "$ROOT/plugins/css/skills/css-expert/SKILL.md"; then
  fail "css-expert must remain implicitly invocable in Claude and Cursor"
fi

for adapter in claude cursor codex; do
  generate "$adapter" "$frontend"
done

for skill in css-expert "${manual_skills[@]}"; do
  [ -L "$frontend/.claude/skills/devkit-css--$skill" ] \
    || fail "Claude did not register $skill as a direct linked skill"
  [ -L "$frontend/.cursor/skills/$skill" ] \
    || fail "Cursor did not register $skill as a direct linked skill"
  [ -L "$frontend/.codex/skills/devkit-css--$skill" ] \
    || fail "Codex did not register $skill as a direct linked skill"
  for linked in \
    "$frontend/.claude/skills/devkit-css--$skill" \
    "$frontend/.cursor/skills/$skill" \
    "$frontend/.codex/skills/devkit-css--$skill"; do
    target=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$linked")
    expected=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' \
      "$ROOT/plugins/css/skills/$skill")
    [ "$target" = "$expected" ] || fail "$linked does not point directly to its source skill"
  done
done

css_rule="$frontend/.cursor/rules/devkit-css.mdc"
[ -f "$css_rule" ] || fail "frontend Cursor project has no CSS rule"
globs=$(sed -n 's/^globs:[[:space:]]*//p' "$css_rule" | head -1)
for extension in css scss sass less vue tsx jsx html; do
  printf '%s\n' "$globs" | jq -e --arg extension "$extension" \
    'index("**/*." + $extension) != null' >/dev/null \
    || fail "CSS rule does not cover .$extension files: $globs"
done
for extension in ts js; do
  printf '%s\n' "$globs" | jq -e --arg extension "$extension" \
    'index("**/*." + $extension) == null' >/dev/null \
    || fail "CSS rule activates for every .$extension file: $globs"
done

css_body_marker=$(awk 'BEGIN { frontmatter = 0; closed = 0 }
  /^---$/ { if (!frontmatter) frontmatter = 1; else if (!closed) closed = 1; next }
  closed && NF { print; exit }' "$ROOT/plugins/css/skills/css-expert/SKILL.md")
[ -n "$css_body_marker" ] || fail "CSS expert has no body marker"
if grep -Fq "$css_body_marker" "$frontend/AGENTS.md" "$css_rule"; then
  fail "generated discovery indexes contain the CSS skill body"
fi

for adapter in claude cursor codex; do
  generate "$adapter" "$backend"
done
for target in \
  "$backend/.claude/skills/devkit-css--css-expert" \
  "$backend/.cursor/skills/css-expert" \
  "$backend/.codex/skills/devkit-css--css-expert" \
  "$backend/.cursor/rules/devkit-css.mdc"; do
  [ ! -e "$target" ] && [ ! -L "$target" ] || fail "backend-only project received CSS discovery: $target"
done
if grep -Fq '### devkit-css' "$backend/AGENTS.md"; then
  fail "backend-only Codex index received CSS conduct"
fi

echo "css-routing: all assertions passed"
