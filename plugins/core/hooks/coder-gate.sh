#!/bin/sh
# coder-gate.sh — PreToolUse hook for Claude Code and Codex code edits.
#
# Hard-gates the FIRST code edit of a session: blocks once (exit 2), surfaces the
# core comment/surgical rules + the instruction to load devkit-coder, then lets the
# retried edit through — so the rules are in context BEFORE any code lands. Fires once
# per session via a marker file keyed on session_id. Payload text lives in
# coder-gate.txt (one source, editable without touching this script).
#
# Fail-open by design: if jq is missing or the input is unparseable, allow the edit
# rather than block every write. Adapted alongside skill-eval.sh.

input=$(cat)

# Without jq we cannot reliably read tool_name/session_id — never block blindly.
command -v jq >/dev/null 2>&1 || exit 0

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
case "$tool" in
  Edit | Write | MultiEdit | apply_patch) ;;
  *) exit 0 ;;
esac

sid=$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null)
marker="${TMPDIR:-/tmp}/devkit-coder-gate-$sid"
[ -f "$marker" ] && exit 0
: > "$marker"

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cat "$dir/coder-gate.txt" >&2
exit 2
