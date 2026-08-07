#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

run_gate() {
  local session_id="$1"
  local transcript="$2"
  local status

  set +e
  printf '%s\n' "{\"tool_name\":\"apply_patch\",\"session_id\":\"$session_id\",\"transcript_path\":\"$transcript\"}" \
    | TMPDIR="$TMP_DIR" sh "$ROOT/plugins/core/hooks/coder-gate.sh" >/dev/null 2>&1
  status=$?
  set -e

  printf '%s\n' "$status"
}

empty_transcript="$TMP_DIR/empty.jsonl"
: > "$empty_transcript"

[ "$(run_gate missing "$empty_transcript")" = "2" ] || fail "missing skill should block"
[ "$(run_gate missing "$empty_transcript")" = "2" ] || fail "retry without skill should still block"

claude_transcript="$TMP_DIR/claude.jsonl"
printf '%s\n' '{"message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"devkit-core--coder"}}]}}' \
  > "$claude_transcript"
[ "$(run_gate claude "$claude_transcript")" = "0" ] || fail "Claude coder skill should open gate"

codex_transcript="$TMP_DIR/codex.jsonl"
printf '%s\n' '{"type":"response_item","payload":{"type":"custom_tool_call","input":"sed -n 1,200p /tmp/plugins/core/skills/coder/SKILL.md"}}' \
  > "$codex_transcript"
[ "$(run_gate codex "$codex_transcript")" = "0" ] || fail "Codex coder skill should open gate"

cursor_transcript="$TMP_DIR/cursor.jsonl"
printf '%s\n' '{"role":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"path":"/Users/blaryx/.cursor/skills/devkit-core--coder/SKILL.md"}}]}}' \
  > "$cursor_transcript"
[ "$(run_gate cursor "$cursor_transcript")" = "0" ] || fail "Cursor coder skill read should open gate"

cursor_readfile_transcript="$TMP_DIR/cursor-readfile.jsonl"
printf '%s\n' '{"role":"assistant","message":{"content":[{"type":"tool_use","name":"ReadFile","input":{"path":"/Users/blaryx/.cursor/skills/devkit-core--coder/SKILL.md"}}]}}' \
  > "$cursor_readfile_transcript"
[ "$(run_gate cursor-readfile "$cursor_readfile_transcript")" = "0" ] || fail "Cursor ReadFile transcript should open gate"

set +e
printf '%s\n' "{\"toolName\":\"ReadFile\",\"session_id\":\"cursor-activate\",\"tool_input\":{\"path\":\"/Users/blaryx/.cursor/skills/devkit-core--coder/SKILL.md\"}}" \
  | TMPDIR="$TMP_DIR" sh "$ROOT/plugins/core/hooks/coder-gate.sh" >/dev/null 2>&1
[ $? -eq 0 ] || fail "Cursor ReadFile preToolUse should allow read"
printf '%s\n' "{\"toolName\":\"StrReplace\",\"session_id\":\"cursor-activate\",\"transcript_path\":\"$empty_transcript\"}" \
  | TMPDIR="$TMP_DIR" sh "$ROOT/plugins/core/hooks/coder-gate.sh" >/dev/null 2>&1
same_turn_status=$?
set -e
[ "$same_turn_status" = "0" ] || fail "edit in same turn after ReadFile preToolUse should allow"

set +e
printf '%s\n' "{\"toolName\":\"StrReplace\",\"session_id\":\"cursor-blocked\",\"transcript_path\":\"$empty_transcript\"}" \
  | TMPDIR="$TMP_DIR" sh "$ROOT/plugins/core/hooks/coder-gate.sh" >/dev/null 2>&1
cursor_block_status=$?
set -e
[ "$cursor_block_status" = "2" ] || fail "Cursor StrReplace without skill should block"

quoted_transcript="$TMP_DIR/quoted.jsonl"
printf '%s\n' '{"type":"response_item","payload":{"type":"custom_tool_call_output","output":"{\"type\":\"custom_tool_call\",\"input\":\"plugins/core/skills/coder/SKILL.md\"}"}}' \
  > "$quoted_transcript"
[ "$(run_gate quoted "$quoted_transcript")" = "2" ] || fail "quoted transcript output must not open gate"

[ "$(run_gate unavailable "$TMP_DIR/missing.jsonl")" = "0" ] || fail "missing transcript should fail open"

echo "coder gate tests passed"
