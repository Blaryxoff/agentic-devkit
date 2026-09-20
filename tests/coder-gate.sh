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

# --- is_scratch_path: the exemption that lets an edit bypass the gate entirely ---
# Every case below runs with no coder skill in the transcript, so exit 0 can only
# come from the exemption and exit 2 means the gate held.
# $1 is the hook's working directory: a relative path resolves against it, so the
# case that proves relative paths are rejected only means something when the cwd
# is itself inside tmp.
run_edit_in() {
  local cwd="$1" session_id="$2" path="$3" status
  set +e
  jq -nc --arg s "$session_id" --arg t "$empty_transcript" --arg p "$path" \
    '{tool_name:"Write", session_id:$s, transcript_path:$t, tool_input:{path:$p}}' \
    | (cd "$cwd" && TMPDIR="$TMP_DIR" sh "$ROOT/plugins/core/hooks/coder-gate.sh") >/dev/null 2>&1
  status=$?
  set -e
  printf '%s\n' "$status"
}

run_edit() { run_edit_in "$ROOT" "$1" "$2"; }

marker_for() {
  printf '%s\n' "$TMP_DIR/devkit-coder-active-$(printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_')"
}

[ "$(run_edit scratch-plain "$TMP_DIR/scratch.ts")" = "0" ] || fail "plain tmp path should be exempt"
[ -e "$(marker_for scratch-plain)" ] && fail "exempt edit must not create a session marker"

mkdir -p "$TMP_DIR/repo"
git -C "$TMP_DIR/repo" init -q
[ "$(run_edit scratch-git "$TMP_DIR/repo/src.ts")" = "2" ] || fail "tmp path inside a git work tree must gate"

mkdir -p "$TMP_DIR/repo/nested/deep"
[ "$(run_edit scratch-git-deep "$TMP_DIR/repo/nested/deep/src.ts")" = "2" ] \
  || fail "the upward walk must find .git above a nested tmp path"

: > "$TMP_DIR/real.ts"
ln -sf "$TMP_DIR/real.ts" "$TMP_DIR/link.ts"
[ "$(run_edit scratch-symlink "$TMP_DIR/link.ts")" = "2" ] \
  || fail "a symlinked final component must gate even when it points into tmp"

[ "$(run_edit_in "$TMP_DIR" scratch-relative "scratch.ts")" = "2" ] \
  || fail "a relative path must gate even when the cwd is tmp"
# A fixed non-tmp absolute path, not $ROOT: a checkout living under /tmp would make
# the $ROOT form exempt and the assertion would pass for the wrong reason.
[ "$(run_edit scratch-outside "/usr/devkit-scratch-test.ts")" = "2" ] \
  || fail "a path outside tmp must gate"
[ "$(run_edit scratch-missing-dir "$TMP_DIR/no-such-dir/x.ts")" = "2" ] \
  || fail "an unresolvable parent must gate, not fall through to exempt"

echo "coder gate tests passed"
