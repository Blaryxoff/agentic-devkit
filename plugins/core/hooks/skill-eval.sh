#!/bin/sh
# skill-eval.sh — UserPromptSubmit hook for Claude Code.
#
# Emits the shared skill-activation instruction. The canonical text lives in
# skill-eval.txt — the same snippet the Codex/Cursor adapters embed (one source).
# Adapted from umputun/cc-thingz (MIT). Instruction only — no permissions, no writes.

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cat "$dir/skill-eval.txt"
