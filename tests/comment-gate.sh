#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

run_gate() {
  local payload="$1"
  local status

  set +e
  printf '%s' "$payload" | TMPDIR="$TMP_DIR" sh "$ROOT/plugins/core/hooks/comment-gate.sh" >/dev/null 2>&1
  status=$?
  set -e

  printf '%s\n' "$status"
}

edit() {
  local path="$1" new="$2" old="${3-}"
  jq -cn --arg p "$path" --arg n "$new" --arg o "$old" \
    '{tool_name:"Edit",tool_input:{file_path:$p,new_string:$n,old_string:$o}}'
}

patch_payload() {
  jq -cn --arg patch "$1" '{tool_name:"apply_patch",tool_input:{patch:$patch}}'
}

expect() {
  local want="$1" desc="$2" payload="$3"
  [ "$(run_gate "$payload")" = "$want" ] || fail "$desc"
}

prose_block='// A view transition morphs the heading and the metric pill across
// the swap, so neither element blinks out and back at a new width
const swap = 1;'

expect 2 "prose block must block" "$(edit /tmp/a.js "$prose_block")"
expect 2 "history narration must block" "$(edit /tmp/a.js '// previously used the old parser
const x = 1;')"
expect 2 "python prose block must block" "$(edit /tmp/a.py '# The scheduler retries each job three times before it gives up
# and pushes the payload onto the dead letter queue for review
retry(job)')"
expect 2 "css prose block must block" "$(edit /tmp/a.css '/* The grid collapses to a single column below this breakpoint
 * because the sidebar cannot render its labels legibly there
 */
.a { color: red; }')"

expect 0 "lint directives are exempt" "$(edit /tmp/a.js '// eslint-disable-next-line no-console
// eslint-disable-next-line no-undef
console.log(x);')"
expect 0 "machine-readable tags are exempt" "$(edit /tmp/a.php '/**
 * @param string $name
 * @return list<int>
 */')"
expect 0 "licence header on a new file is exempt" \
  "$(jq -cn '{tool_name:"Write",tool_input:{file_path:"/tmp/new-xyz.ts",content:"// SPDX-License-Identifier: MIT\n// Copyright (c) 2026 Example Holdings Limited\n// Licensed under the terms of the MIT licence agreement\nexport const a = 1;"}}')"
expect 0 "a lone prose line stays under the block threshold" \
  "$(edit /tmp/a.js '// this explains the whole thing in one long sentence
const x = 1;')"
expect 0 "dividers are not prose" "$(edit /tmp/a.js '// ----------------
// ----------------
const x = 1;')"
expect 0 "css selectors are not comments" "$(edit /tmp/a.css '#main-navigation-bar { color: red; }
#other-navigation-bar { color: blue; }')"
expect 0 "js private fields are not comments" "$(edit /tmp/a.js 'class A {
  #internalCounterValue = 0;
  #anotherPrivateField = 1;
}')"
expect 0 "prose targets are skipped" "$(edit /tmp/a.md "$prose_block")"
expect 0 "baseline prose is not an addition" "$(edit /tmp/a.js "$prose_block" "$prose_block")"

expect 2 "apply_patch prose block must block" "$(patch_payload '*** Update File: src/app.ts
@@
 const a = 1;
+// The retry budget is shared across every worker in the pool so that
+// a single hot partition cannot starve the others of their attempts
+retry(job);
')"
expect 0 "apply_patch markdown section stays exempt" "$(patch_payload '*** Update File: docs/a.md
@@
+// The retry budget is shared across every worker in the pool so that
+// a single hot partition cannot starve the others of their attempts
')"

expect 0 "non-edit tools are ignored" "$(jq -cn '{tool_name:"Bash",tool_input:{command:"ls"}}')"
expect 0 "malformed input fails open" '{"tool_name":"Edit"}'

gate_stderr() {
  set +e
  printf '%s' "$1" | TMPDIR="$TMP_DIR" sh "$ROOT/plugins/core/hooks/comment-gate.sh" 2>&1 1>/dev/null
  set -e
}

gate_stderr "$(edit /tmp/a.js "$prose_block")" | grep -q 'no-prose default' \
  || fail "prose rejection must reach stderr, not just exit 2"
gate_stderr "$(edit /tmp/a.js '// previously used the old parser
const x = 1;')" | grep -q 'narrates change history' \
  || fail "history rejection must reach stderr, not just exit 2"

echo "comment gate tests passed"
