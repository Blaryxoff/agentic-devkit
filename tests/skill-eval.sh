#!/usr/bin/env bash
# Covers plugins/core/hooks/skill-eval.sh. Its per-session debounce — the whole
# point of the hook — was unreached: the only existing invocation passed empty
# stdin and returned before the marker logic.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

HOOK="$ROOT/plugins/core/hooks/skill-eval.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

run() {
  printf '%s' "$1" | TMPDIR="$TMP_DIR" sh "$HOOK" 2>/dev/null
}

marker_for() {
  printf '%s\n' "$TMP_DIR/devkit-skill-gate-last-$(printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_')"
}

# No session id: fire every time, never write a marker.
out=$(run '{}')
printf '%s\n' "$out" | grep -q 'DEVKIT TURN GATE' || fail "an id-less prompt must still get the gate"
[ "$(ls "$TMP_DIR" | wc -l | tr -d ' ')" = "0" ] || fail "an id-less prompt wrote a marker"

# First prompt of a session fires and records.
out=$(run '{"session_id":"sess-a"}')
printf '%s\n' "$out" | grep -q 'DEVKIT TURN GATE' || fail "the first prompt of a session must fire"
[ -f "$(marker_for sess-a)" ] || fail "the first prompt wrote no debounce marker"

# Second prompt in the same session is debounced.
out=$(run '{"session_id":"sess-a"}')
[ -z "$out" ] || fail "a second prompt in the same session must stay silent, got: $out"

# A different session is independent.
out=$(run '{"session_id":"sess-b"}')
printf '%s\n' "$out" | grep -q 'DEVKIT TURN GATE' || fail "a different session must fire"

# Past the stale window it refires and re-stamps.
printf '%s' "$(( $(date +%s) - 1300 ))" > "$(marker_for sess-a)"
out=$(run '{"session_id":"sess-a"}')
printf '%s\n' "$out" | grep -q 'DEVKIT TURN GATE' || fail "a stale marker must refire the gate"
[ "$(cat "$(marker_for sess-a)")" -gt "$(( $(date +%s) - 60 ))" ] \
  || fail "the refire did not re-stamp the marker"

# A corrupt marker is treated as stale rather than silencing the session forever.
printf 'garbage' > "$(marker_for sess-a)"
out=$(run '{"session_id":"sess-a"}')
printf '%s\n' "$out" | grep -q 'DEVKIT TURN GATE' || fail "a corrupt marker must not silence the gate"

# Session ids are sanitised before becoming a path.
run '{"session_id":"../../escape"}' >/dev/null
[ -f "$(marker_for '../../escape')" ] || fail "a path-like session id was not sanitised into TMPDIR"

# The gate text must name the learning-capture conduct with an absolute path.
out=$(run '{"session_id":"sess-c"}')
printf '%s\n' "$out" | grep -q "$ROOT/plugins/core/conduct/learning-capture-gate.md" \
  || fail "the gate text does not resolve the conduct path against the clone"

echo "skill-eval tests passed"
