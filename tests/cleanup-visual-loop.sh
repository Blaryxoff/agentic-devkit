#!/usr/bin/env bash
# Covers bin/devkit-cleanup-visual-loop.mjs, which rewrites a consumer's
# package.json and unlinks a file with no dry-run and had no test.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

if ! command -v node >/dev/null 2>&1; then
  echo "SKIP: node not installed"
  exit 0
fi

CLEAN="$ROOT/bin/devkit-cleanup-visual-loop.mjs"

run() {
  set +e
  node "$CLEAN" "$@" > "$TMP_DIR/out" 2>&1
  local status=$?
  set -e
  return $status
}

# --- a project carrying the artifacts -----------------------------------------

p="$TMP_DIR/project"
mkdir -p "$p/visual"
cat > "$p/package.json" <<'JSON'
{
  "name": "consumer",
  "version": "1.0.0",
  "scripts": {
    "build": "vite build",
    "ui:check": "node ui-check.mjs",
    "ui:loop": "node ui-loop.mjs",
    "test": "vitest"
  },
  "dependencies": { "vite": "^5.0.0" }
}
JSON
printf '{"cookies":[]}\n' > "$p/visual/.auth-state.json"
printf '{"baseline":true}\n' > "$p/visual/config.json"

run "$p" || fail "cleanup exited non-zero: $(cat "$TMP_DIR/out")"

[ "$(jq -r '.scripts["ui:check"] // "gone"' "$p/package.json")" = "gone" ] || fail "ui:check was not removed"
[ "$(jq -r '.scripts["ui:loop"] // "gone"' "$p/package.json")" = "gone" ] || fail "ui:loop was not removed"
[ "$(jq -r '.scripts.build' "$p/package.json")" = "vite build" ] || fail "an unrelated script was removed"
[ "$(jq -r '.scripts.test' "$p/package.json")" = "vitest" ] || fail "an unrelated script was removed"
[ "$(jq -r '.name' "$p/package.json")" = "consumer" ] || fail "an unrelated top-level key was lost"
[ "$(jq -r '.dependencies.vite' "$p/package.json")" = "^5.0.0" ] || fail "dependencies were lost"
[ -e "$p/visual/.auth-state.json" ] && fail ".auth-state.json was not removed"
[ -f "$p/visual/config.json" ] || fail "visual/config.json must be kept"
grep -q "removed 2 ui:\* script(s)" "$TMP_DIR/out" || fail "the removal was not reported: $(cat "$TMP_DIR/out")"

# --- --dry-run -----------------------------------------------------------------
# The real run above already consumed this project's artifacts, so use a fresh one.

dry="$TMP_DIR/dry"
mkdir -p "$dry/visual"
printf '{"scripts":{"ui:check":"x","build":"b"}}\n' > "$dry/package.json"
printf '{}\n' > "$dry/visual/.auth-state.json"
before_pkg=$(cat "$dry/package.json")

run --dry-run "$dry" || fail "--dry-run exited non-zero"
grep -q "would remove" "$TMP_DIR/out" || fail "--dry-run did not report what it would do"
[ "$(cat "$dry/package.json")" = "$before_pkg" ] || fail "--dry-run rewrote package.json"
[ -f "$dry/visual/.auth-state.json" ] || fail "--dry-run deleted the auth cache"

run "$dry" || fail "the real run after --dry-run exited non-zero"
[ "$(jq -r '.scripts["ui:check"] // "gone"' "$dry/package.json")" = "gone" ] \
  || fail "the real run did not apply what --dry-run reported"
[ -e "$dry/visual/.auth-state.json" ] && fail "the real run did not remove the auth cache"

# --- idempotence ---------------------------------------------------------------

before=$(cat "$p/package.json")
run "$p" || fail "a second run exited non-zero"
[ "$(cat "$p/package.json")" = "$before" ] || fail "a second run rewrote package.json"
grep -q "nothing to clean" "$TMP_DIR/out" || fail "a clean project was not reported as clean"

# --- a project with no package.json --------------------------------------------

empty="$TMP_DIR/empty"
mkdir -p "$empty"
run "$empty" || fail "a project without package.json must not fail"
grep -q "nothing to clean" "$TMP_DIR/out" || fail "an empty project was not reported as clean"

# --- argument handling ---------------------------------------------------------

run && fail "no arguments must exit non-zero"
grep -q "Usage:" "$TMP_DIR/out" || fail "no-argument invocation printed no usage"
run --help || fail "--help must exit 0"

# A malformed package.json must abort with a message, not a stack trace or a rewrite.
bad="$TMP_DIR/bad"
mkdir -p "$bad"
printf '{ not json' > "$bad/package.json"
run "$bad" && fail "a malformed package.json must exit non-zero"
[ "$(cat "$bad/package.json")" = "{ not json" ] || fail "a malformed package.json was rewritten"

echo "cleanup-visual-loop tests passed"
