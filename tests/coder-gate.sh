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

quoted_transcript="$TMP_DIR/quoted.jsonl"
printf '%s\n' '{"type":"response_item","payload":{"type":"custom_tool_call_output","output":"{\"type\":\"custom_tool_call\",\"input\":\"plugins/core/skills/coder/SKILL.md\"}"}}' \
  > "$quoted_transcript"
[ "$(run_gate quoted "$quoted_transcript")" = "2" ] || fail "quoted transcript output must not open gate"

[ "$(run_gate unavailable "$TMP_DIR/missing.jsonl")" = "0" ] || fail "missing transcript should fail open"

echo "coder gate tests passed"
