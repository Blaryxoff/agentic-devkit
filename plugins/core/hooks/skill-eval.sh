#!/bin/sh
# skill-eval.sh — UserPromptSubmit hook for Claude Code.
#
# Reasserts the small per-turn activation gate. The durable routing policy lives
# in ~/.claude/CLAUDE.md; this reminder keeps it salient in long sessions.
# Adapted from umputun/cc-thingz (MIT). Instruction only — no permissions, no writes.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEVKIT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)

printf '%s\n' "DEVKIT TURN GATE: Before responding or calling any non-Skill tool, compare the request with available skill descriptions. If any match, first call Skill(<catalog-slug>) for the smallest directly relevant set. Mentioning a skill is not activation. If none match, proceed directly. Before a top-level final response when completed work may have revealed durable project knowledge, apply $DEVKIT_ROOT/plugins/core/conduct/learning-capture-gate.md; call Skill(devkit-core--learn) only when a candidate passes, otherwise finish silently."
