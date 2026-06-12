#!/bin/sh
# skill-eval.sh — UserPromptSubmit hook for Claude Code.
#
# Forces the model to evaluate and activate relevant skills before implementing,
# instead of skipping the skill menu and answering generically.
# Adapted from umputun/cc-thingz (MIT).
#
# Injects an instruction only — no permissions, no file writes.

cat <<'EOF'
INSTRUCTION: EVALUATE SKILLS BEFORE ACTING

Before implementing, check the available skills (both globally registered skills
and, for stack-specific work, the devkit router skill `devkit`) for relevance to
this request.

IF any skills are relevant:
  1. State which skills and why (there may be several).
  2. Activate ALL relevant ones via Skill(...) calls before implementing.
  3. For stack/framework conventions not globally registered, activate `devkit`
     to route to the right stack skill.
  4. Then proceed.

IF none are relevant:
  - Proceed directly.

Mentioning a skill without activating it is worthless. Activate, then implement.
EOF
