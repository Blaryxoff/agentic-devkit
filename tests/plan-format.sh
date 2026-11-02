#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKER="$ROOT/plugins/core/skills/plan-reviewer/scripts/check-dev-plan.py"
FIXTURES="$ROOT/tests/fixtures/ralphex-plans"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -x "$CHECKER" ]] || fail "checker is not executable: $CHECKER"

assert_clean() {
  local plan="$1" output status=0
  output=$("$CHECKER" "$plan" 2>&1) || status=$?
  [[ $status -eq 0 ]] || fail "$plan exited $status: $output"
  [[ -z "$output" ]] || fail "$plan printed output: $output"
}

shopt -s nullglob

valid=("$FIXTURES"/valid/*.md)
invalid=("$FIXTURES"/invalid/*.md)
[[ ${#valid[@]} -gt 0 ]] || fail "no valid fixtures"
[[ ${#invalid[@]} -gt 0 ]] || fail "no invalid fixtures"

for plan in "${valid[@]}"; do
  assert_clean "$plan"
done
(cd "$FIXTURES/valid" && assert_clean tasks-integer.md)

for plan in "${invalid[@]}"; do
  rule="$(basename "$plan" .md)"
  rule="${rule%%--*}"
  status=0
  output=$("$CHECKER" "$plan" 2>&1) || status=$?
  [[ $status -eq 1 ]] || fail "$plan exited $status, expected 1: $output"
  [[ "$(wc -l <<<"$output")" -eq 1 ]] || fail "$plan reported more than one violation: $output"
  grep -qE "^[^:]+:[0-9]+: ${rule}: " <<<"$output" || fail "$plan did not report rule $rule: $output"
done

status=0
"$CHECKER" >/dev/null 2>&1 || status=$?
[[ $status -eq 2 ]] || fail "missing argument exited $status, expected 2"
status=0
"$CHECKER" "$FIXTURES/does-not-exist.md" >/dev/null 2>&1 || status=$?
[[ $status -eq 2 ]] || fail "missing file exited $status, expected 2"

echo "plan-format: ${#valid[@]} valid, ${#invalid[@]} invalid fixtures OK"
