#!/usr/bin/env bash
# Covers bin/devkit-update, which had no test. It runs as a SessionStart hook on
# every machine devkit is installed on and always exits 0, so a regression that
# stops every container updating would otherwise be invisible.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# An origin repo with one commit, and a clone one commit behind it.
origin="$TMP_DIR/origin"
git init -q --bare "$origin"
seed="$TMP_DIR/seed"
git init -q -b master "$seed"
git -C "$seed" config user.email t@example.com
git -C "$seed" config user.name t
mkdir -p "$seed/bin"
cp "$ROOT/bin/devkit-update" "$seed/bin/devkit-update"
printf 'v1\n' > "$seed/marker"
git -C "$seed" add -A
git -C "$seed" commit -q -m one
git -C "$seed" remote add origin "$origin"
git -C "$seed" push -q -u origin master

clone="$TMP_DIR/clone"
git clone -q "$origin" "$clone"
state="$clone/.git/devkit-last-pull"

printf 'v2\n' > "$seed/marker"
git -C "$seed" commit -q -am two
git -C "$seed" push -q origin master

run() {
  set +e
  # DEVKIT_PROJECT_ROOT is pinned away from the fixture so the submodule branch stays out.
  DEVKIT_PROJECT_ROOT="$TMP_DIR/nowhere" bash "$clone/bin/devkit-update" "$@" > "$TMP_DIR/out" 2>&1
  local status=$?
  set -e
  return $status
}

# --- a successful pull ---------------------------------------------------------

run || fail "devkit-update must never fail its caller (exit $?)"
[ "$(cat "$clone/marker")" = "v2" ] || fail "the clone was not fast-forwarded"
grep -q "global updated" "$TMP_DIR/out" || fail "no update line: $(cat "$TMP_DIR/out")"
[ -f "$state" ] || fail "a successful pull wrote no timestamp"
[ -n "$(cat "$state")" ] || fail "the timestamp file is empty"

# --- the staleness guard -------------------------------------------------------

run --if-stale || fail "--if-stale must exit 0"
[ -s "$TMP_DIR/out" ] && fail "--if-stale with a fresh stamp must stay silent: $(cat "$TMP_DIR/out")"

printf '%s' "$(( $(date +%s) - 90000 ))" > "$state"
run --if-stale || fail "--if-stale must exit 0 when stale"
grep -q "global up to date" "$TMP_DIR/out" || fail "a stale stamp did not trigger a fetch"

# A corrupt stamp must be treated as stale, not crash or skip forever.
printf 'not-a-number' > "$state"
run --if-stale || fail "--if-stale must survive a corrupt stamp"
grep -q "global up to date" "$TMP_DIR/out" || fail "a corrupt stamp did not trigger a fetch"

# --- an unreachable origin -----------------------------------------------------
# The stamp must not advance, or the next 24h of sessions skip the update entirely
# while reporting nothing.

before_stamp=$(cat "$state")
git -C "$clone" remote set-url origin "$TMP_DIR/does-not-exist"
run || fail "an unreachable origin must not fail the caller"
grep -q "fetch from origin failed" "$TMP_DIR/out" \
  || fail "a failed fetch was not reported: $(cat "$TMP_DIR/out")"
[ "$(cat "$state")" = "$before_stamp" ] || fail "a failed fetch advanced the timestamp"

# --- not a git repo ------------------------------------------------------------

plain="$TMP_DIR/plain"
mkdir -p "$plain/bin"
cp "$ROOT/bin/devkit-update" "$plain/bin/devkit-update"
set +e
DEVKIT_PROJECT_ROOT="$TMP_DIR/nowhere" bash "$plain/bin/devkit-update" > "$TMP_DIR/out" 2>&1
status=$?
set -e
[ "$status" = "0" ] || fail "a non-repo install must still exit 0"
grep -q "is not a git repo" "$TMP_DIR/out" || fail "a non-repo install was not reported"

echo "devkit-update tests passed"
