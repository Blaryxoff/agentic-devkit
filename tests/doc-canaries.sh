#!/usr/bin/env bash
# Wording canaries for skills, conduct and hook payloads.
#
# These are deliberate tripwires against silent edits to rules an agent is supposed
# to follow, not behavioural assertions: each one checks that a specific phrase is
# still present in a specific Markdown file. They live apart from
# tests/context-efficiency.sh so that a copy-edit fails here — where the message is
# "the wording moved, re-anchor or re-approve it" — instead of reading as a
# regression in the structural invariants and size budgets that file owns.
#
# Fixing a failure here means one of two things: restore the phrase, or move the
# canary to the new wording on purpose.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  grep -Fq "$2" "$1" || fail "expected $1 to contain: $2"
}

assert_not_contains() {
  if grep -Fq "$2" "$1"; then
    fail "expected $1 not to contain: $2"
  fi
}

# Behavioural routing canaries: compact loading must still detect omitted responsibilities.
assert_contains "$ROOT/plugins/core/skills/plan-creator/SKILL.md" 'even if the user or draft omitted it'
assert_contains "$ROOT/plugins/core/skills/plan-creator/SKILL.md" 'transitive `dependencies`'
assert_contains "$ROOT/plugins/core/skills/plan-reviewer/SKILL.md" 'Missing coverage is itself a trigger'
assert_contains "$ROOT/plugins/core/skills/plan-reviewer/SKILL.md" 'transitive `dependencies`'
assert_contains "$ROOT/plugins/core/skills/plan-reviewer/SKILL.md" 'When reviewing a paired product + dev plan, load both references.'
assert_contains "$ROOT/plugins/core/skills/verify/SKILL.md" 'Conduct requirements'
assert_contains "$ROOT/plugins/core/skills/verify/SKILL.md" 'transitive `dependencies`'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'terminal learning-capture gate'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" "environment's structured question tool"
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'Save only the selected items.'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" "current harness's native project"
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'placement guidance defined at project or user scope'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" '`AGENTS.md` for Codex'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" '`CLAUDE.md` for Claude Code'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" '`~/.claude/rules/*.md`'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'every applicable `AGENTS.md` already loaded'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" "another harness's global file"
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'Different-task test'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'Established-evidence test'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'supported beyond one failure path by multiple project locations'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'workflow, or a confirmed team decision'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'intentional project conventions or invariants established across the codebase'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" "the bug cause, fix, failed approach, or defensive check from the task just completed"
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'framework, language, library, ORM, or serialization behaviour'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'implementation-level query, matching, parsing, payload, or comparison idioms'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'Recurrence prevention alone is insufficient.'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'Survives-its-own-fix test'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'it is work, not memory'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'actionable repository findings'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'deferred-work-backlog.md'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'Split each candidate to a single claim'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'never an inventory of which files are live or dead'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'not evidence of intent'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'including documentation the project should have'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'Never use this default to rescue a candidate'
assert_not_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'Would it save future debugging time?'
assert_not_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'AskUserQuestion'
assert_contains "$ROOT/plugins/core/skills/backlog/SKILL.md" 'docs/backlog/<slug>.md'
assert_contains "$ROOT/plugins/core/skills/backlog/SKILL.md" 'Process one item at a time.'
assert_contains "$ROOT/plugins/core/skills/backlog/SKILL.md" 'not the project root.'
assert_contains "$ROOT/plugins/core/skills/backlog/SKILL.md" 'commit plus push them together.'
assert_contains "$ROOT/plugins/core/skills/task/SKILL.md" 'Codex review/fix loop'
assert_contains "$ROOT/plugins/core/skills/task/SKILL.md" 'up to 10 iterations'
assert_contains "$ROOT/plugins/core/skills/task/references/codex-review.md" 'Never let Codex write.'
assert_contains "$ROOT/plugins/core/skills/task/references/codex-review.md" '`"$(cat "$prompt_file")"`'
assert_contains "$ROOT/plugins/core/skills/task/references/codex-review.md" 'must reach Codex literally, not execute in the launcher shell.'
assert_contains "$ROOT/plugins/core/skills/task/references/codex-review.md" 'Scan the complete response for `CRITICAL`, `MAJOR`, and `MINOR` before checking `NO ISSUES FOUND`.'
assert_contains "$ROOT/plugins/core/skills/task/references/codex-review.md" '`NO ISSUES FOUND` counts as clean only when no severity tag appears'
assert_contains "$ROOT/plugins/core/conduct/overview.md" '[deferred-work-backlog.md](./deferred-work-backlog.md)'
assert_contains "$ROOT/plugins/core/conduct/deferred-work-backlog.md" 'Do not treat a shared path as proof of duplication.'
assert_contains "$ROOT/plugins/core/skills/wrapup/SKILL.md" 'It does not authorize deployment.'
assert_not_contains "$ROOT/plugins/core/skills/wrapup/SKILL.md" '## Step 6 — Deploy'
assert_not_contains "$ROOT/plugins/core/commands/wrapup.md" 'deploy'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'finish silently'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'strongest three at most'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'Never write project memory directly'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'Skill(devkit-core--learn)'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" '**Established**'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'low-level query or payload-matching idioms'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'framework or'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'serialization behaviour'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'A lesson does not qualify merely because it could prevent the same bug'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" '**Survives its own fix**'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'it is work, not memory'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'Split each candidate to a single claim'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" '[deferred-work-backlog.md](./deferred-work-backlog.md)'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'never file one silently'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'offer the choice: fix it now'
assert_contains "$ROOT/plugins/core/hooks/skill-eval.txt" 'offer a fix or backlog deferral in one line'
assert_contains "$ROOT/plugins/core/hooks/skill-eval.sh" 'offer a fix or backlog deferral in one line'
assert_contains "$ROOT/plugins/core/skills/coder/SKILL.md" 'Offer a fix or backlog deferral in one line'
assert_contains "$ROOT/plugins/core/conduct/readiness-gate.md" 'actionable repository finding is offered in one line'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'neither is evidence of intent'
assert_contains "$ROOT/plugins/core/hooks/skill-eval.txt" '{{DEVKIT_HOME}}/plugins/core/conduct/learning-capture-gate.md'
assert_contains "$ROOT/plugins/core/skills/reviewer-deep/SKILL.md" 'review-specialist-fanout.md'
assert_contains "$ROOT/plugins/core/skills/reviewer-deep/SKILL.md" 'Generic quality fallback'
assert_contains "$ROOT/plugins/core/skills/reviewer-deep/SKILL.md" 'complete resolved reviewer set'
assert_contains "$ROOT/plugins/core/skills/reviewer-business-logic/SKILL.md" 'do not dispatch them independently'
assert_contains "$ROOT/plugins/core/skills/reviewer-business-logic/SKILL.md" 'Generic implementation fallback'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'The invoking agent owns the numbered coverage ledger'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'newest available Codex Luna'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'model-routing.md'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'Missing cells trigger another Luna/Haiku execution wave'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'Multi-agent fan-out is allowed'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'top-level agent runs Codex browser-client lanes sequentially'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'Mutation-capable non-production lanes use append-only namespaced test records'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Clean each completed executor tree immediately'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Explicit user choice is a hard constraint and wins first'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Codex Bridge means only the external Chrome/extension binding'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Move the entire dependent lane to a capable surface'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Pre-existing Bridge tabs are inspection-only by default'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'identity blocks mutation'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'revalidate the full pin'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Production is read-only by default'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'A local QA request authorises and requires append-only test-data preparation'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'seeder/factory is preferred, never a prerequisite'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Read-only browser assertions and worker shell sandboxes do not waive'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'keep those cells blocked/uncovered and the pass incomplete'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'local QA authorises append-only'
assert_not_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'not applicable — read-only lane'
assert_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" 'seeder or read-only worker sandbox is not a seeding exemption'
assert_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" 'not the QA lead'
assert_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" 'every delegated stage on the same resolved Luna'
assert_not_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" 'medium'
assert_not_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'medium'
assert_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" '"${luna_cli_args[@]}"'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'without erasing an evidenced functional result'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Cells may reference the same snapshot'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'Re-run only named missing,'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'after the initial review, reviewers inspect only new or invalidated results'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'results potentially affected by new fixes'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Previously passed results in that impact map need recheck and review'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'a fresh worker or another report'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'do not keep retrying merely to obtain a green report'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'without commissioning another full review'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Do not carry over the original lane'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Do not dispatch one agent per element or control state'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Do not close the browser and defer an available assigned check'
assert_contains "$ROOT/plugins/core/conduct/browser-layout-audit.md" 'Ungrouped candidates remain unresolved'
assert_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" 'The invoking agent keeps its current model and owns planning'
assert_not_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" 'Keep the canonical planner, reviewer and escalation'
assert_not_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" 'Terra'
assert_not_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'Terra'
assert_not_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" 'Sol'
assert_not_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'Sol'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'never replace missing browser evidence with inference or dispatch a separate adjudication model'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'at least two read-only reviewers'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'additional reviewer pairs by independent lane groups'
assert_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" 'partition large ledgers across more Luna pairs'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Confirm before filing'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Styling preference,'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" '§7.2–§7.4 for issue eligibility, severity and confirmation'
assert_contains "$ROOT/plugins/core/skills/lunaqa/SKILL.md" 'Both reviewers and the invoker apply'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" "If a click's effects are uncertain, treat it as a mutation and do not click."
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'A spot pass drops only the coverage ledger'
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" 'Never edit a previous brief into a new one'
assert_contains "$ROOT/plugins/core/conduct/browser-ui-oracles.md" 'Rasterise colours before computing contrast'
assert_contains "$ROOT/plugins/core/conduct/browser-ui-oracles.md" 'Count rendered nodes, not presence'
assert_contains "$ROOT/plugins/core/conduct/browser-ui-oracles.md" 'A probe that cannot fire on the defect it targets certifies nothing'
assert_contains "$ROOT/plugins/core/conduct/review-specialist-fanout.md" 'maximum independent set in parallel waves'
assert_contains "$ROOT/plugins/core/conduct/review-specialist-fanout.md" 'Never nest orchestration or dispatch the same axis twice.'
assert_contains "$ROOT/plugins/core/conduct/review-specialist-fanout.md" 'Every prompt must require read-only operation'
assert_contains "$ROOT/plugins/core/conduct/review-specialist-fanout.md" 'tests or test fixtures changed'
assert_contains "$ROOT/plugins/core/conduct/review-specialist-fanout.md" 'human documentation changed'
assert_contains "$ROOT/plugins/core/conduct/code-smells.md" 'Pass-through layers'
assert_contains "$ROOT/plugins/core/conduct/overview.md" '[review-gate.md](./review-gate.md)'
assert_contains "$ROOT/plugins/core/conduct/conduct-loading.md" 'must not relax applicable safety'
assert_contains "$ROOT/plugins/core/conduct/docker-deployment.md" 'source-code bind mounts'
assert_contains "$ROOT/plugins/core/conduct/docker-deployment.md" 'backup failure alerts wired'
assert_contains "$ROOT/plugins/core/conduct/docker-deployment.md" 'Read-only filesystems'
docker_checklist=$(sed -n '/^## 13\./,$p' "$ROOT/plugins/core/conduct/docker-deployment.md")
for required_check in 'REDIS_PREFIX' 'APP_PROD_HOST' 'DEPLOY_<ENV>_SSH_PRIVATE_KEY' 'timeout'; do
  [[ "$docker_checklist" == *"$required_check"* ]] \
    || fail "Docker §13 checklist is missing mandatory coverage: $required_check"
done

model_paths=("$ROOT/plugins" "$ROOT/bin" "$ROOT/adapters" "$ROOT/tests" "$ROOT/docs" "$ROOT/howto"
  "$ROOT/examples" "$ROOT/schemas" "$ROOT/README.md" "$ROOT/CLAUDE.md" "$ROOT/MIGRATION.md")
model_pattern='gpt[-_][0-9]|claude[-_](opus|sonnet|haiku)[-_][0-9]|(GPT|Opus|Sonnet|Haiku|Gemini)[- ][0-9]'
if command -v rg >/dev/null 2>&1; then
  model_pins=$(rg -n -i "$model_pattern" "${model_paths[@]}" --glob '!**/__pycache__/**' || true)
else
  model_pins=$(grep -rInEi "$model_pattern" "${model_paths[@]}" --exclude-dir=__pycache__ || true)
fi
[ -z "$model_pins" ] || fail "numbered model releases must be resolved at runtime:\n$model_pins"

echo "doc canary tests passed"
