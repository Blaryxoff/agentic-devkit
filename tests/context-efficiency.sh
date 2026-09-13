#!/usr/bin/env bash

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

broad_loading_pattern='read all.*conduct|load conduct for all|load.*all active plugins|read each plugin.s conduct|read and apply the following conduct'
if command -v rg >/dev/null 2>&1; then
  broad_loading=$(rg -n -i "$broad_loading_pattern" \
    "$ROOT/plugins" "$ROOT/CLAUDE.md" "$ROOT/adapters" \
    --glob 'SKILL.md' --glob '*.md' --glob 'generate' || true)
else
  broad_loading=$(grep -rniE "$broad_loading_pattern" \
    --include='*.md' --include='generate' \
    "$ROOT/plugins" "$ROOT/CLAUDE.md" "$ROOT/adapters" || true)
fi
[ -z "$broad_loading" ] || fail "wholesale conduct loading directive found:\n$broad_loading"

[ ! -e "$ROOT/plugins/laravel/conduct/database_safety.md" ] || fail "duplicate database safety policy returned"
[ ! -e "$ROOT/plugins/laravel/conduct/CLAUDE.md" ] || fail "Laravel conduct meta copy returned"
[ ! -e "$ROOT/plugins/laravel/conduct/README.md" ] || fail "Laravel conduct README copy returned"
[ ! -e "$ROOT/plugins/nuxt/conduct/CLAUDE.md" ] || fail "Nuxt conduct meta copy returned"
[ ! -e "$ROOT/plugins/nuxt/conduct/README.md" ] || fail "Nuxt conduct README copy returned"

oversized_skills=0
while IFS= read -r skill; do
  lines=$(wc -l < "$skill")
  [ "$lines" -le 800 ] || fail "skill exceeds 800-line hard ceiling: $skill ($lines)"
  [ "$lines" -le 300 ] || oversized_skills=$((oversized_skills + 1))
done < <(find "$ROOT/plugins" -path '*/skills/*/SKILL.md' -type f | sort)
[ "$oversized_skills" -eq 0 ] || echo "WARN: $oversized_skills skill(s) exceed the 300-line progressive-disclosure target"

# --- Catalog metadata budget -------------------------------------------------
# Every registered skill, generated slash command and generated subagent contributes
# name + description to a metadata block injected into EVERY request, under a hard
# platform cap. Skill BODIES are not in that block; they load on activation. Measure
# the whole surface, not just skills, or the test passes while the catalog overflows.
if python3 -c 'import yaml' >/dev/null 2>&1; then
  python3 - "$ROOT" <<'PY' || fail "catalog metadata budget check failed"
import re
import sys
from pathlib import Path

import yaml

root = Path(sys.argv[1])
install = (root / "bin/devkit-install").read_text()
deny = re.search(r'^SHORT_COMMAND_DENY="([^"]*)"', install, re.M).group(1).split()
authored = {p.stem for p in (root / "plugins/core/commands").glob("*.md")}

PER_SKILL_CAP = 520
TOTAL_CAP = 17000
TOTAL_TARGET = 16000

# A description is selection metadata: what the skill does, when to invoke it, and how it
# differs from its siblings. Mechanics, output formats and conduct citations belong in the
# body, which costs nothing until the skill is selected.
# Conduct and reference citations are read after activation, so they are body content.
# A `docs/plans/**` gate or a `docs/qa/` output path is part of what the skill is for,
# and a bare "claude.md" is a phrase the user types - both stay.
FORBIDDEN = re.compile(r"\b(?:plugins/\w+/conduct/|\w+/conduct/|references/)[\w./*-]+")
TRIGGER = re.compile(
    r"\b(?:invoke|trigger)\b|\b(?:use|run)\b[^.]{0,40}?\b(?:when|for|on|alongside|together)\b",
    re.I,
)

total = 0
rows = []
problems = []
for path in sorted(root.glob("plugins/core/skills/*/SKILL.md")):
    slug = path.parent.name
    meta = yaml.safe_load(path.read_text().split("---", 2)[1])
    desc, name = meta["description"].strip(), meta["name"]
    size = len(desc) + len(name)

    if len(desc) > PER_SKILL_CAP:
        problems.append(f"{slug}: description is {len(desc)} chars, cap is {PER_SKILL_CAP}")
    if FORBIDDEN.search(desc):
        problems.append(f"{slug}: description cites a file path - move it to the body")
    fold = re.search(r"[A-Za-z0-9]- [a-z]", desc)
    if fold:
        problems.append(
            f"{slug}: line wrap split a hyphenated token ({fold.group(0)!r}) - "
            "YAML folding turns it into a name that resolves to nothing"
        )
    if not TRIGGER.search(desc):
        problems.append(f"{slug}: description has no trigger clause (when to invoke)")

    total += size
    rows.append((size, "skill", slug))

    if str(meta.get("claudeSubagent", "")).lower() == "true":
        total += size
        rows.append((size, "agent", name))

    if slug not in deny and slug not in authored:
        command = len(f"Run the devkit {slug} workflow.") + len(slug)
        total += command
        rows.append((command, "command", slug))

for path in sorted((root / "plugins/core/commands").glob("*.md")):
    meta = yaml.safe_load(path.read_text().split("---", 2)[1])
    size = len(str(meta.get("description", ""))) + len(path.stem)
    total += size
    rows.append((size, "command", path.stem))

if problems:
    print("catalog metadata contract violations:", file=sys.stderr)
    for line in problems:
        print(f"  {line}", file=sys.stderr)
    raise SystemExit(1)

if total > TOTAL_CAP:
    rows.sort(reverse=True)
    print(f"catalog metadata is {total} chars, hard cap is {TOTAL_CAP}", file=sys.stderr)
    for size, kind, name in rows[:15]:
        print(f"  {size:5d} {kind:8s} {name}", file=sys.stderr)
    raise SystemExit(1)

if total > TOTAL_TARGET:
    print(f"WARN: catalog metadata is {total} chars, target is {TOTAL_TARGET}")
else:
    print(f"catalog metadata: {total} chars across {len(rows)} registrations (target {TOTAL_TARGET})")
PY
else
  echo "WARN: python3 PyYAML unavailable - catalog metadata budget not measured"
fi

# Every emitted subagent must be valid YAML. A description containing ": " (e.g.
# "Routing policy: ...") is not a legal plain scalar, so emit_subagent must fold it.
agent_probe=$(mktemp -d)
trap 'rm -rf "$agent_probe"' EXIT
# shellcheck source=/dev/null
. "$ROOT/adapters/_lib/claude_agents.sh"
emitted=0
for skill_md in "$ROOT"/plugins/*/skills/*/SKILL.md; do
  devkit_is_subagent "$skill_md" || continue
  emit_subagent "$skill_md" "$agent_probe" >/dev/null
  emitted=$((emitted + 1))
done
[ "$emitted" -gt 0 ] || fail "no subagents emitted - the claudeSubagent frontmatter gate is broken"
if python3 -c 'import yaml' >/dev/null 2>&1; then
  python3 - "$agent_probe" <<'PY' || fail "generated subagent frontmatter is not valid YAML"
import sys
from pathlib import Path

import yaml

for path in sorted(Path(sys.argv[1]).glob("*.md")):
    parts = path.read_text().split("---", 2)
    if len(parts) != 3:
        raise SystemExit(f"invalid frontmatter delimiters: {path.name}")
    try:
        data = yaml.safe_load(parts[1])
    except yaml.YAMLError as exc:
        raise SystemExit(f"{path.name}: {exc}")
    if not isinstance(data, dict) or not isinstance(data.get("description"), str):
        raise SystemExit(f"{path.name}: missing description")
PY
fi

# skill-creator documents `claudeSubagent: true` inside a fenced example; an unbounded
# grep would treat it as an isolation skill and drop it from ~/.claude/skills.
devkit_is_subagent "$ROOT/plugins/core/skills/skill-creator/SKILL.md" \
  && fail "claudeSubagent gate matched a fenced body example in skill-creator"

# Parse every skill frontmatter with a real YAML parser. Prefer the existing Python
# environment and fall back to Ruby's standard-library parser without adding a dependency.
if python3 -c 'import yaml' >/dev/null 2>&1; then
  python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
import yaml

root = Path(sys.argv[1])
for path in sorted(root.glob("plugins/*/skills/*/SKILL.md")):
    parts = path.read_text().split("---", 2)
    if len(parts) != 3 or parts[0].strip():
        raise SystemExit(f"invalid frontmatter delimiters: {path}")
    data = yaml.safe_load(parts[1])
    if not isinstance(data, dict) or not isinstance(data.get("name"), str) or not isinstance(data.get("description"), str):
        raise SystemExit(f"invalid skill frontmatter: {path}")
PY
elif command -v ruby >/dev/null 2>&1; then
  ruby -ryaml - "$ROOT" <<'RB'
root = ARGV.fetch(0)
Dir.glob(File.join(root, "plugins/*/skills/*/SKILL.md")).sort.each do |path|
  parts = File.read(path).split(/^---\s*$\n?/, 3)
  abort("invalid frontmatter delimiters: #{path}") unless parts.length == 3 && parts[0].strip.empty?
  data = YAML.safe_load(parts[1], permitted_classes: [], aliases: false)
  valid = data.is_a?(Hash) && data["name"].is_a?(String) && data["description"].is_a?(String)
  abort("invalid skill frontmatter: #{path}") unless valid
end
RB
else
  fail "python3 PyYAML or ruby is required to validate skill frontmatter"
fi

while IFS= read -r hook; do
  bash -n "$hook" || fail "invalid shell hook syntax: $hook"
done < <(find "$ROOT/plugins" -path '*/hooks/*.sh' -type f | sort)

# Every canonical conduct document must be reachable from its plugin index.
for conduct_dir in "$ROOT"/plugins/*/conduct; do
  [ -d "$conduct_dir" ] || continue
  overview="$conduct_dir/overview.md"
  [ -f "$overview" ] || fail "missing conduct index: $overview"

  while IFS= read -r doc; do
    [ "$doc" = "$overview" ] && continue
    rel=${doc#"$conduct_dir/"}
    if grep -Fq "(./$rel)" "$overview"; then
      continue
    fi
    parent=${rel%/*}
    if [ "$parent" != "$rel" ] && grep -Fq "(./$parent/)" "$overview"; then
      continue
    fi
    fail "conduct document is not reachable from $overview: $rel"
  done < <(find "$conduct_dir" -name '*.md' -type f | sort)
done

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
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" '`AGENTS.md` for Codex'
assert_contains "$ROOT/plugins/core/skills/learn/SKILL.md" '`CLAUDE.md` for Claude Code'
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
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'gpt-5.6-sol'
assert_contains "$ROOT/plugins/core/skills/browser/SKILL.md" 'gpt-5.6-luna'
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
assert_contains "$ROOT/plugins/core/conduct/browser-qa-rules.md" "If a click's effects are uncertain, treat it as a mutation and do not click."
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

echo "context efficiency tests passed"
