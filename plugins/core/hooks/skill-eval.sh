#!/bin/sh
# skill-eval.sh — UserPromptSubmit hook for Claude Code.
#
# Reasserts the small per-turn activation gate. The durable routing policy lives
# in ~/.claude/CLAUDE.md; this reminder keeps it salient in long sessions.
# Adapted from umputun/cc-thingz (MIT). Instruction only — no permissions, no writes.

cat <<'EOF'
DEVKIT TURN GATE: Before responding or calling any non-Skill tool, compare the request with available skill descriptions. If any match, first call Skill(<catalog-slug>) for the smallest directly relevant set. Mentioning a skill is not activation. If none match, proceed directly.
EOF
