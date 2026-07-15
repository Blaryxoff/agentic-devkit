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
