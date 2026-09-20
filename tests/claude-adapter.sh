#!/usr/bin/env bash
# Covers adapters/claude/generate, which no test invoked: the frontmatter-name
# collision guard, the .mcp.json upsert that must preserve a user's own servers,
# the unconditional removal of legacy .claude-plugin/ artifacts, and the generated
# subagents' hand-rolled YAML frontmatter.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

PROJECT="$TMP_DIR/project"
HOME_DIR="$TMP_DIR/home"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# The adapter runs against a copy of the clone, not the repo: the collision guard
# needs two plugins sharing a frontmatter name, and no shipped pair does today.
CLONE="$TMP_DIR/clone"
mkdir -p "$CLONE"
tar -cf - --exclude .git -C "$ROOT" . | tar -xf - -C "$CLONE"
for plugin in laravel nuxt; do
  mkdir -p "$CLONE/plugins/$plugin/skills/dupe"
  printf -- '---\nname: devkit-dupe\ndescription: fixture skill sharing a name across two plugins\n---\n\nbody\n' \
    > "$CLONE/plugins/$plugin/skills/dupe/SKILL.md"
done

generate() {
  DEVKIT_PROJECT_ROOT="$PROJECT" HOME="$HOME_DIR" DEVKIT_HOME_DIR="$CLONE" \
    bash "$CLONE/adapters/claude/generate"
}

mkdir -p "$PROJECT/.devkit" "$HOME_DIR"
git -C "$PROJECT" init -q
printf '%s\n' '{"version":1,"enabled":["devkit-laravel","devkit-nuxt"]}' > "$PROJECT/.devkit/toolkit.json"

# A user's own MCP server and an unrelated top-level key must survive the upsert.
printf '%s\n' '{"mcpServers":{"my-server":{"command":"mine","args":["--keep"]}},"otherKey":"keep me"}' \
  > "$PROJECT/.mcp.json"

# Legacy marketplace artifacts from an older adapter version.
mkdir -p "$PROJECT/.claude-plugin"
printf '{}\n' > "$PROJECT/.claude-plugin/marketplace.json"
printf '{}\n' > "$PROJECT/.claude-plugin/.devkit-state.json"

out="$TMP_DIR/gen.out"
generate > "$out" 2>&1 || fail "claude adapter exited non-zero: $(tail -3 "$out")"

# --- legacy cleanup -----------------------------------------------------------

[ -e "$PROJECT/.claude-plugin" ] && fail "legacy .claude-plugin/ was not removed"

# --- .mcp.json upsert ---------------------------------------------------------

[ "$(jq -r '.mcpServers["my-server"].command' "$PROJECT/.mcp.json")" = "mine" ] \
  || fail "the user's own MCP server was dropped"
[ "$(jq -r '.mcpServers["my-server"].args[0]' "$PROJECT/.mcp.json")" = "--keep" ] \
  || fail "the user's own MCP server args were rewritten"
[ "$(jq -r '.otherKey' "$PROJECT/.mcp.json")" = "keep me" ] \
  || fail "an unrelated top-level key in .mcp.json was dropped"
[ "$(jq '.mcpServers | length' "$PROJECT/.mcp.json")" -gt 1 ] \
  || fail "no plugin MCP server was added alongside the user's"
jq -e . "$PROJECT/.mcp.json" >/dev/null || fail ".mcp.json is not valid JSON after the upsert"

# --- frontmatter-name collision guard -----------------------------------------
# Both enabled plugins define a skill named devkit-dupe. Exactly one may be linked,
# and the adapter has to say which one it dropped.
grep -q "WARN: skill name 'devkit-dupe'" "$out" \
  || fail "no collision warning for the duplicated frontmatter name: $(cat "$out")"
linked_dupes=0
for link in "$PROJECT"/.claude/skills/*; do
  [ -L "$link" ] || continue
  linked_name=$(sed -n 's/^name:[[:space:]]*//p' "$link/SKILL.md" 2>/dev/null | head -1)
  if [ "$linked_name" = "devkit-dupe" ]; then
    linked_dupes=$((linked_dupes + 1))
  fi
done
[ "$linked_dupes" = "1" ] || fail "expected exactly one devkit-dupe skill link, found $linked_dupes"

# --- generated subagents ------------------------------------------------------
# emit_subagent hand-rolls YAML frontmatter in awk and has a recorded past bug there.

agents_dir="$PROJECT/.claude/agents"
[ -d "$agents_dir" ] || fail "no stack subagents were generated"
agent_count=0
for agent in "$agents_dir"/*.md; do
  [ -f "$agent" ] || continue
  agent_count=$((agent_count + 1))
  head -1 "$agent" | grep -qx -- '---' || fail "$agent does not open with a frontmatter fence"
  [ "$(grep -cx -- '---' "$agent")" -ge 2 ] || fail "$agent has an unterminated frontmatter block"
  fm=$(sed -n '2,/^---$/p' "$agent" | sed '$d')
  printf '%s\n' "$fm" | grep -q '^name:' || fail "$agent has no name in its frontmatter"
  printf '%s\n' "$fm" | grep -q '^description:' || fail "$agent has no description in its frontmatter"
  # A description folded mid-token would yield a dangling `devkit-` on its own line.
  printf '%s\n' "$fm" | grep -qE '(^|[[:space:]])devkit-$' \
    && fail "$agent has a description folded inside a hyphenated token"
  python3 -c 'import sys, yaml; yaml.safe_load(sys.stdin.read())' <<< "$fm" 2>/dev/null \
    || ruby -ryaml -e 'YAML.safe_load(STDIN.read)' <<< "$fm" 2>/dev/null \
    || fail "$agent frontmatter is not parseable YAML"
done
[ "$agent_count" -gt 0 ] || fail "no subagent files were written"

# --- idempotence --------------------------------------------------------------
# The adapter is re-run on every plugin-set change; a second run must not duplicate
# or destroy anything.

before_mcp=$(jq -S . "$PROJECT/.mcp.json")
generate > "$TMP_DIR/gen2.out" 2>&1 || fail "second run exited non-zero"
[ "$(jq -S . "$PROJECT/.mcp.json")" = "$before_mcp" ] || fail "a second run changed .mcp.json"
[ "$(ls "$agents_dir" | wc -l | tr -d ' ')" = "$agent_count" ] \
  || fail "a second run changed the generated subagent set"
[ "$(grep -cxF '.cursor/chrome-profile/' "$PROJECT/.gitignore")" = "1" ] \
  || fail "the chrome-profile .gitignore entry was duplicated across runs"

echo "claude adapter tests passed"
