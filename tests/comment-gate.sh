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
# The Write branch reads $target from disk to subtract pre-existing content, so this
# path must be one this test owns: a stray /tmp/new-xyz.ts on the host would become
# the baseline and the licence-exemption branch would never run.
new_file="$TMP_DIR/new-xyz.ts"
[ -e "$new_file" ] && fail "fixture path $new_file already exists"
expect 0 "licence header on a new file is exempt" \
  "$(jq -cn --arg p "$new_file" '{tool_name:"Write",tool_input:{file_path:$p,content:"// SPDX-License-Identifier: MIT\n// Copyright (c) 2026 Example Holdings Limited\n// Licensed under the terms of the MIT licence agreement\nexport const a = 1;"}}')"
# The Write branch subtracts what is already on disk. Both halves are asserted, so a
# regression in either direction is caught: rewriting the same prose is not an addition,
# adding new prose on top of it is.
existing_prose='// The scheduler retries each job three times before it gives up
// and then it writes a line to the dead letter queue for later'
printf '%s\n' "$existing_prose" > "$TMP_DIR/existing.ts"
expect 0 "a Write that rewrites pre-existing prose adds nothing" \
  "$(jq -cn --arg p "$TMP_DIR/existing.ts" --arg c "$existing_prose
export const a = 1;" '{tool_name:"Write",tool_input:{file_path:$p,content:$c}}')"
expect 2 "a Write adding new prose on top of pre-existing prose blocks" \
  "$(jq -cn --arg p "$TMP_DIR/existing.ts" --arg c "$existing_prose
// this narration is new and the gate has to notice it
// together with this second new line of narration
export const a = 1;" '{tool_name:"Write",tool_input:{file_path:$p,content:$c}}')"
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
expect 0 "container build files are exempt from the no-prose default" "$(edit /tmp/Dockerfile.hermes '# The upstream base symlinks tini to the s6 init, so calling it here crash-loops the container
# and the static build is the only one that reaps orphans as PID 1 without it
RUN echo build')"
expect 0 "extensionless Dockerfile is exempt too" "$(edit /tmp/Dockerfile '# Arch comes from dpkg at run time because the legacy builder never populates TARGETARCH
# and the release assets both use that exact suffix
RUN echo build')"
expect 2 "container build files still block change narration" "$(edit /tmp/Dockerfile '# previously pinned to the old base
RUN echo build')"
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

sid_payload() {
  jq -cn --arg f "$1" --arg c "$2" --arg s "$3" \
    '{session_id:$s,tool_name:"Write",tool_input:{file_path:$f,content:$c}}'
}

rm -f "$TMP_DIR/devkit-comment-gate-seen-sess-x"
first=$(gate_stderr "$(sid_payload /tmp/first.js "$prose_block" sess-x)")
second=$(gate_stderr "$(sid_payload /tmp/second.js "$prose_block" sess-x)")
printf '%s' "$first" | grep -q 'How to proceed' \
  || fail "the first block in a session must carry the full payload"
printf '%s' "$second" | grep -q 'same rule as before' \
  || fail "a repeat block in the same session must collapse to the short form"
printf '%s' "$second" | grep -q 'Offending added line(s)' \
  || fail "the short form must still name the offending lines"
[ "${#second}" -lt "${#first}" ] || fail "the short form must be shorter than the full payload"
other=$(gate_stderr "$(sid_payload /tmp/third.js "$prose_block" sess-y)")
printf '%s' "$other" | grep -q 'How to proceed' \
  || fail "a different session must start from the full payload"

history_block='// previously used the old parser
const x = 1;'
history=$(gate_stderr "$(sid_payload /tmp/fourth.js "$history_block" sess-x)")
printf '%s' "$history" | grep -q 'narrates change history' \
  || fail "a different rule in the same session must still carry its own full payload"

echo "comment gate tests passed"
