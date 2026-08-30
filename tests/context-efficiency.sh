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

broad_loading=$(rg -n -i \
  'read all.*conduct|load conduct for all|load.*all active plugins|read each plugin.s conduct|read and apply the following conduct' \
  "$ROOT/plugins" "$ROOT/CLAUDE.md" "$ROOT/adapters" \
  --glob 'SKILL.md' --glob '*.md' --glob 'generate' || true)
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

core_metadata_bytes=0
while IFS= read -r skill; do
  bytes=$(awk 'NR == 1 { next } /^---$/ { exit } { total += length($0) + 1 } END { print total + 0 }' "$skill")
  core_metadata_bytes=$((core_metadata_bytes + bytes))
done < <(find "$ROOT/plugins/core/skills" -name SKILL.md -type f | sort)
[ "$core_metadata_bytes" -le 20000 ] || fail "core skill metadata exceeds 20KB hard ceiling: $core_metadata_bytes"
[ "$core_metadata_bytes" -le 12000 ] || echo "WARN: core skill metadata exceeds the 12KB target: $core_metadata_bytes"

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
assert_not_contains "$ROOT/plugins/core/skills/learn/SKILL.md" 'AskUserQuestion'
assert_contains "$ROOT/plugins/core/skills/backlog/SKILL.md" 'docs/backlog/<slug>.md'
assert_contains "$ROOT/plugins/core/skills/backlog/SKILL.md" 'Process one item at a time.'
assert_contains "$ROOT/plugins/core/skills/backlog/SKILL.md" 'not the project root.'
assert_contains "$ROOT/plugins/core/skills/backlog/SKILL.md" 'commit plus push them together.'
assert_contains "$ROOT/plugins/core/skills/task/SKILL.md" 'Codex review/fix loop'
assert_contains "$ROOT/plugins/core/skills/task/SKILL.md" 'up to 10 iterations'
assert_contains "$ROOT/plugins/core/skills/task/references/codex-review.md" 'Never let Codex write.'
assert_contains "$ROOT/plugins/core/conduct/overview.md" '[deferred-work-backlog.md](./deferred-work-backlog.md)'
assert_contains "$ROOT/plugins/core/conduct/deferred-work-backlog.md" 'Do not treat a shared path as proof of duplication.'
assert_contains "$ROOT/plugins/core/skills/wrapup/SKILL.md" 'It does not authorize deployment.'
assert_not_contains "$ROOT/plugins/core/skills/wrapup/SKILL.md" '## Step 6 — Deploy'
assert_not_contains "$ROOT/plugins/core/commands/wrapup.md" 'deploy'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'finish silently'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'strongest three at most'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'Never write project memory directly'
assert_contains "$ROOT/plugins/core/conduct/learning-capture-gate.md" 'Skill(devkit-core--learn)'
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
