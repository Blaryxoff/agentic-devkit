#!/usr/bin/env bash
# Covers adapters/_lib/resolve.sh and bin/devkit-resolve: the resolution core every
# adapter depends on. Nothing else in the suite exercises its error paths, its
# multi-root union, or the schema validation behind --validate.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mkproject() {
  local dir="$TMP_DIR/$1" config="$2"
  mkdir -p "$dir/.devkit"
  printf '%s\n' "$config" > "$dir/.devkit/toolkit.json"
  printf '%s\n' "$dir"
}

resolve() {
  set +e
  bash "$ROOT/bin/devkit-resolve" "$@" 2>"$TMP_DIR/err"
  local status=$?
  set -e
  return $status
}

# --- resolution ---------------------------------------------------------------

laravel=$(mkproject laravel '{"version":1,"enabled":["devkit-laravel"]}')
out=$(resolve --project="$laravel") || fail "resolving a valid project failed: $(cat "$TMP_DIR/err")"
[ "$out" = "devkit-core
devkit-laravel" ] || fail "expected core then laravel, got: $out"

# Transitive dependencies are pulled in and sorted by layer, not alphabetically.
# devkit-css is the discriminator: alphabetically it lands second, by layer it is last.
nuxt=$(mkproject nuxt '{"version":1,"enabled":["devkit-nuxt","devkit-css"]}')
out=$(resolve --project="$nuxt") || fail "resolving devkit-nuxt failed"
[ "$(printf '%s\n' "$out" | tail -1)" = "devkit-css" ] \
  || fail "styling must sort last, not alphabetically; got: $out"
[ "$(printf '%s\n' "$out" | head -1)" = "devkit-core" ] || fail "core must sort first, got: $out"
printf '%s\n' "$out" | grep -qx devkit-frontend || fail "transitive devkit-frontend missing"
printf '%s\n' "$out" | grep -qx devkit-vue || fail "transitive devkit-vue missing"
layers=$(printf '%s\n' "$out" | while read -r p; do jq -r '.layer' "$ROOT/plugins/${p#devkit-}/plugin.json"; done)
sorted=$(printf '%s\n' "$layers" | awk '{print index("core stack framework styling", $0) " " $0}' | sort -n | cut -d" " -f2-)
[ "$layers" = "$sorted" ] || fail "plugins are not ordered core -> stack -> framework -> styling: $layers"

# --- multi-root union ---------------------------------------------------------

back=$(mkproject backend '{"version":1,"enabled":["devkit-laravel"]}')
front=$(mkproject frontend '{"version":1,"enabled":["devkit-nuxt","devkit-laravel"]}')
out=$(resolve --project="$back" --project="$front") || fail "multi-root resolution failed"
printf '%s\n' "$out" | grep -qx devkit-laravel || fail "union lost devkit-laravel"
printf '%s\n' "$out" | grep -qx devkit-nuxt || fail "union lost devkit-nuxt"
[ "$(printf '%s\n' "$out" | grep -cx devkit-laravel)" = "1" ] \
  || fail "devkit-laravel, named in both roots, was not de-duplicated"

# _collect_enabled de-duplicates before resolution. Asserted directly, because the
# resolver's own keyed accumulator would mask a duplicate in the merged array.
merged=$(
  source "$ROOT/adapters/_lib/resolve.sh"
  PROJECT_ROOT="$back" DEVKIT_PROJECT_ROOTS="$back:$front" _collect_enabled
)
[ "$(printf '%s' "$merged" | jq 'length')" = "$(printf '%s' "$merged" | jq 'unique | length')" ] \
  || fail "_collect_enabled returned duplicates: $merged"

# A root without a config is skipped with a warning, not silently, and not fatally.
mkdir -p "$TMP_DIR/configless"
out=$(resolve --project="$back" --project="$TMP_DIR/configless") || fail "a configless second root must not be fatal"
grep -q "no .devkit/toolkit.json at $TMP_DIR/configless" "$TMP_DIR/err" \
  || fail "the skipped root was not reported: $(cat "$TMP_DIR/err")"

# A single configless root is an error with an actionable hint.
resolve --project="$TMP_DIR/configless" && fail "a single configless root must fail"
grep -q "No .devkit/toolkit.json found" "$TMP_DIR/err" || fail "missing the no-config error"
grep -q -- "--init" "$TMP_DIR/err" || fail "the no-config error does not suggest --init"

# --- error paths --------------------------------------------------------------

bad_version=$(mkproject badversion '{"version":2,"enabled":[]}')
resolve --project="$bad_version" && fail "version 2 must be rejected"
grep -q "Unsupported toolkit.json version: 2" "$TMP_DIR/err" || fail "missing the version error"

unknown=$(mkproject unknown '{"version":1,"enabled":["devkit-nope"]}')
resolve --project="$unknown" && fail "an unknown plugin must fail"
grep -q "^ERROR: Plugin not found: devkit-nope" "$TMP_DIR/err" \
  || fail "the unknown-plugin error still leaks jq's raw text: $(cat "$TMP_DIR/err")"

resolve --bogus-flag >/dev/null && fail "an unknown option must exit non-zero"

# A dependency cycle must be reported, not recursed into. No shipped pair forms one,
# so the fixture lives in a copy of the clone.
CLONE="$TMP_DIR/clone"
mkdir -p "$CLONE"
tar -cf - --exclude .git -C "$ROOT" . | tar -xf - -C "$CLONE"
for pair in "cycle-a:devkit-cycle-b" "cycle-b:devkit-cycle-a"; do
  dir="${pair%%:*}"
  dep="${pair#*:}"
  mkdir -p "$CLONE/plugins/$dir"
  jq -n --arg n "devkit-$dir" --arg d "$dep" \
    '{name:$n, version:"1.0.0", description:"cycle fixture", layer:"stack",
      defaultEnabled:false, dependencies:[$d], paths:{}}' > "$CLONE/plugins/$dir/plugin.json"
done
cycle=$(mkproject cycle '{"version":1,"enabled":["devkit-cycle-a"]}')
set +e
bash "$CLONE/bin/devkit-resolve" --project="$cycle" >/dev/null 2>"$TMP_DIR/err"
cycle_status=$?
set -e
[ "$cycle_status" != "0" ] || fail "a dependency cycle must not resolve successfully"
grep -q "^ERROR: Dependency cycle: " "$TMP_DIR/err" \
  || fail "the cycle error is missing or still raw jq output: $(cat "$TMP_DIR/err")"

# --- --validate ---------------------------------------------------------------

resolve --validate --project="$laravel" >/dev/null || fail "--validate rejected a valid config"

for bad in '{"version":1,"enabled":["devkit-laravel"],"bogusKey":true}' \
           '{"version":1}' \
           '{"version":1,"enabled":["Not-A-Plugin"]}' \
           '{"version":1,"enabled":["devkit-laravel","devkit-laravel"]}'; do
  p=$(mkproject "invalid-$RANDOM" "$bad")
  resolve --validate --project="$p" >/dev/null && fail "--validate accepted: $bad"
  grep -q "^ERROR: " "$TMP_DIR/err" || fail "--validate gave no error for: $bad"
done

# Every manifest devkit ships must satisfy its own schema. Captured rather than piped
# into grep -q: under `set -o pipefail` the early close would kill the producer with
# SIGPIPE and the assertion would fail on a matching line.
validate_out=$(resolve --validate --project="$laravel") || fail "--validate failed on a valid project"
printf '%s\n' "$validate_out" | grep -q "plugin manifest(s) match schemas/" \
  || fail "--validate does not report manifest validation"

# --- ensure_gitignore_entry normalisation -------------------------------------

source "$ROOT/adapters/_lib/resolve.sh"

gitignore_case() {
  local name="$1" seed="$2" runs="$3"
  local dir="$TMP_DIR/gi-$name"
  local i
  mkdir -p "$dir"
  git -C "$dir" init -q
  if [ -n "$seed" ]; then
    printf '%s\n' "$seed" > "$dir/.gitignore"
  fi
  for ((i = 0; i < runs; i++)); do
    PROJECT_ROOT="$dir" ensure_gitignore_entry '.codex/' >/dev/null
  done
  grep -cxF '.codex/' "$dir/.gitignore" || true
}

[ "$(gitignore_case fresh '' 3)" = "1" ] || fail "repeated runs appended duplicate .codex/ entries"
[ "$(gitignore_case leading-slash '/.codex' 2)" = "0" ] \
  || fail "'/.codex' was not recognised as the same entry"
[ "$(gitignore_case trailing-slash '.codex/' 2)" = "1" ] \
  || fail "an exact existing entry was duplicated"
[ "$(gitignore_case commented '.codex/ # generated' 2)" = "0" ] \
  || fail "a commented entry was not recognised"
[ "$(gitignore_case substring-only '.codex/skills' 1)" = "1" ] \
  || fail "a longer line containing the entry wrongly suppressed the write"

# A file with no trailing newline must not get its last line joined.
nonl="$TMP_DIR/gi-nonl"
mkdir -p "$nonl"
git -C "$nonl" init -q
printf 'node_modules' > "$nonl/.gitignore"
PROJECT_ROOT="$nonl" ensure_gitignore_entry '.codex/' >/dev/null
grep -qx 'node_modules' "$nonl/.gitignore" || fail "the unterminated last line was corrupted"
grep -qx '.codex/' "$nonl/.gitignore" || fail "the entry was not appended after an unterminated line"

# Outside a git work tree the function is a no-op.
notgit="$TMP_DIR/gi-notgit"
mkdir -p "$notgit"
PROJECT_ROOT="$notgit" ensure_gitignore_entry '.codex/' >/dev/null
[ -e "$notgit/.gitignore" ] && fail "a .gitignore was created outside a git work tree"

echo "resolve tests passed"
