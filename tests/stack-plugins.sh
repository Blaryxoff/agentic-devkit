#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
PROJECT="$TMP_DIR/project"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mkdir -p "$PROJECT/.devkit"
git -C "$PROJECT" init -q
cp "$ROOT/examples/express-native-desktop.json" "$PROJECT/.devkit/toolkit.json"
bash "$ROOT/bin/devkit-resolve" --validate --project="$PROJECT" > "$TMP_DIR/validate.log" 2>&1 \
  || fail "stack schema validation failed: $(tail -3 "$TMP_DIR/validate.log")"
resolved=$(bash "$ROOT/bin/devkit-resolve" --project="$PROJECT")
for plugin in core frontend react drizzle express nextjs react-native electron tailwind; do
  printf '%s\n' "$resolved" | grep -qx "devkit-$plugin" || fail "missing resolved $plugin"
done
[ "$(printf '%s\n' "$resolved" | wc -l | tr -d ' ')" = 9 ] || fail "unexpected resolved plugin set: $resolved"

generate() {
  DEVKIT_PROJECT_ROOT="$PROJECT" bash "$ROOT/adapters/$1/generate" > "$TMP_DIR/$1.log" 2>&1 \
    || fail "$1 generation failed: $(tail -3 "$TMP_DIR/$1.log")"
}

for adapter in claude cursor codex; do
  generate "$adapter"
done

for plugin in express react-native electron; do
  for workflow in architect reviewer-fast reviewer-deep reviewer-business-logic tester; do
    skill="$ROOT/plugins/$plugin/skills/$workflow/SKILL.md"
    name=$(sed -n 's/^name: //p' "$skill" | head -1)
    for adapter in claude cursor; do
      agent="$PROJECT/.$adapter/agents/$name.md"
      [ -f "$agent" ] || fail "$adapter missing $name agent"
      if [ "$workflow" != tester ] && [ "$adapter" = cursor ]; then
        grep -Fq 'readonly: true' "$agent" || fail "$name lost read-only restriction"
      fi
    done
    [ -f "$PROJECT/.cursor/skills/$name/SKILL.md" ] || fail "Cursor missing $name skill"
    [ -f "$PROJECT/.codex/skills/devkit-$plugin--$workflow/SKILL.md" ] || fail "Codex missing $name skill"
  done
done

for workflow in design-critique pixel-build pixel-guard reviewer-motion; do
  skill="$ROOT/plugins/frontend/skills/$workflow/SKILL.md"
  name=$(sed -n 's/^name: //p' "$skill" | head -1)
  [ -f "$PROJECT/.cursor/skills/$name/SKILL.md" ] || fail "Cursor missing shared $name"
  [ -f "$PROJECT/.codex/skills/devkit-frontend--$workflow/SKILL.md" ] || fail "Codex missing shared $name"
  if grep -Fq 'claudeSubagent: true' "$skill"; then
    [ -f "$PROJECT/.claude/agents/$name.md" ] || fail "Claude missing shared $name agent"
  else
    [ -f "$PROJECT/.claude/skills/devkit-frontend--$workflow/SKILL.md" ] || fail "Claude missing shared $name skill"
  fi
done

for plugin in react drizzle express react-native electron; do
  grep -Fq "plugins/$plugin/conduct" "$PROJECT/AGENTS.md" || fail "Codex missing $plugin conduct"
  rule="$PROJECT/.cursor/rules/devkit-$plugin.mdc"
  [ -f "$rule" ] || fail "Cursor missing $plugin rule"
  globs=$(sed -n 's/^globs:[[:space:]]*//p' "$rule" | head -1)
  case "$globs" in
    '' | '**/*' | '["**/*"]') fail "$plugin has no scoped glob" ;;
  esac
done

grep -Fq '"**/main.js"' "$PROJECT/.cursor/rules/devkit-electron.mdc" || fail "Electron main.js glob was split"
grep -Fq '"**/main.ts"' "$PROJECT/.cursor/rules/devkit-electron.mdc" || fail "Electron main.ts glob was split"

cp "$PROJECT/AGENTS.md" "$TMP_DIR/AGENTS.before"
for adapter in claude cursor codex; do
  generate "$adapter"
done
cmp -s "$PROJECT/AGENTS.md" "$TMP_DIR/AGENTS.before" || fail "Codex generation is not idempotent"

printf '%s\n' '{"version":1,"enabled":["devkit-nextjs"]}' > "$PROJECT/.devkit/toolkit.json"
for adapter in claude cursor codex; do
  generate "$adapter"
done
for plugin in express react-native electron; do
  [ ! -e "$PROJECT/.codex/skills/devkit-$plugin--architect" ] || fail "disabled $plugin Codex skill remains"
  [ ! -e "$PROJECT/.cursor/skills/devkit-architect-$plugin" ] || fail "disabled $plugin Cursor skill remains"
  for adapter in claude cursor; do
    [ ! -e "$PROJECT/.$adapter/agents/devkit-architect-$plugin.md" ] || fail "disabled $plugin $adapter agent remains"
  done
done
grep -Fq 'plugins/react/conduct' "$PROJECT/AGENTS.md" || fail "Next.js lost its transitive React conduct"

for plugin in react-native electron; do
  printf '{"version":1,"enabled":["devkit-%s"]}\n' "$plugin" > "$PROJECT/.devkit/toolkit.json"
  resolved=$(bash "$ROOT/bin/devkit-resolve" --project="$PROJECT")
  printf '%s\n' "$resolved" | grep -qx devkit-frontend || fail "$plugin lost shared UI conduct dependency"
  for adapter in claude cursor codex; do
    generate "$adapter"
  done
  [ -f "$PROJECT/.codex/skills/devkit-frontend--pixel-build/SKILL.md" ] || fail "$plugin cannot discover shared visual build"
  [ -f "$PROJECT/.cursor/skills/devkit-pixel-guard/SKILL.md" ] || fail "$plugin cannot discover shared visual guard"
  [ -f "$PROJECT/.claude/agents/devkit-pixel-build.md" ] || fail "$plugin cannot discover shared Claude visual agent"
done
echo "stack-plugins: all assertions passed"
