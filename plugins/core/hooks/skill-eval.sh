#!/bin/sh
# skill-eval.sh — UserPromptSubmit hook for Claude Code.
#
# Reasserts the small per-turn activation gate. The durable routing policy lives
# in ~/.claude/CLAUDE.md; this reminder keeps it salient in long sessions.
# Debounced per session_id: skipped inside the stale window, refired once stale.
# Adapted from umputun/cc-thingz (MIT). Instruction only — no permissions; the only write is the per-session debounce marker under TMPDIR.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEVKIT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)
STALE_SECONDS=1200

gate() {
  printf '%s\n' "DEVKIT TURN GATE: Before responding or calling any non-Skill tool, compare the request with available skill descriptions. If any match, first call Skill(<catalog-slug>) for the smallest directly relevant set. Mentioning a skill is not activation. If none match, proceed directly. Before a top-level final response when completed work may have revealed durable project knowledge, apply $DEVKIT_ROOT/plugins/core/conduct/learning-capture-gate.md; call Skill(devkit-core--learn) only when a candidate passes, otherwise finish silently."
}

if ! command -v jq >/dev/null 2>&1; then
  gate
  exit 0
fi

input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // .sessionId // .conversation_id // empty' 2>/dev/null)

if [ -z "$sid" ]; then
  gate
  exit 0
fi

safe_sid=$(printf '%s' "$sid" | tr -c 'A-Za-z0-9._-' '_')
marker="${TMPDIR:-/tmp}/devkit-skill-gate-last-$safe_sid"
now=$(date +%s)

if [ -f "$marker" ]; then
  last=$(cat "$marker" 2>/dev/null || echo 0)
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  if [ $(( now - last )) -lt "$STALE_SECONDS" ]; then
    exit 0
  fi
fi

printf '%s' "$now" > "$marker"
gate
