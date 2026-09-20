#!/usr/bin/env bash
# Covers adapters/_lib/resolve.sh and bin/devkit-resolve: the resolution core every
# adapter depends on. Nothing else in the suite exercises its error paths, its
# multi-root union, or the schema validation behind --validate.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
# BG_PID holds any child this script backgrounds. A test that asserts a process does
# NOT block must not leak one itself when an assertion fails before it is reaped.
BG_PID=""
trap 'rm -rf "$TMP_DIR"; [ -n "$BG_PID" ] && kill -9 "$BG_PID" 2>/dev/null; :' EXIT

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
  # stdin closed on purpose: any path that falls through to an interactive prompt
  # must fail the test rather than hang it.
  bash "$ROOT/bin/devkit-resolve" "$@" < /dev/null 2>"$TMP_DIR/err"
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

# --- non-interactive --init ----------------------------------------------------
# --init reads choices from `read -rp`; --preset and --enable are the scriptable path.

# Without a terminal the prompts can never be answered. A fifo opened read-write is
# the shape an agent harness hands a backgrounded call: never EOF, never a writer, so
# `read` blocks forever and the harness detaches rather than kills it. Assert that it
# exits, not merely that it complains — a blocking --init would otherwise hang the suite.
init_tty="$TMP_DIR/init-no-tty"
mkdir -p "$init_tty"
fifo="$TMP_DIR/init-no-tty.fifo"
mkfifo "$fifo"
exec 3<> "$fifo"
bash "$ROOT/bin/devkit-resolve" --init --project="$init_tty" <&3 >"$TMP_DIR/init-tty.out" 2>&1 &
init_pid=$!
BG_PID=$init_pid
waited=0
while kill -0 "$init_pid" 2>/dev/null && [ "$waited" -lt 50 ]; do
  sleep 0.1
  waited=$((waited + 1))
done
if kill -0 "$init_pid" 2>/dev/null; then
  kill -9 "$init_pid" 2>/dev/null
  exec 3>&-
  fail "--init blocked on a terminal-less stdin instead of exiting"
fi
set +e
wait "$init_pid"
status=$?
set -e
BG_PID=""
exec 3>&-
rm -f "$fifo"
out=$(cat "$TMP_DIR/init-tty.out")
[ "$status" -eq 0 ] && fail "--init without a terminal must exit non-zero"
case "$out" in
  *"needs a terminal"*) ;;
  *) fail "--init without a terminal gave no usable error: $out" ;;
esac
[ -e "$init_tty/.devkit/toolkit.json" ] && fail "--init without a terminal still wrote a config"

init_a="$TMP_DIR/init-preset"
mkdir -p "$init_a"
resolve --preset=laravel-only --project="$init_a" >/dev/null || fail "--preset failed"
[ -f "$init_a/.devkit/toolkit.json" ] || fail "--preset wrote no config"
[ "$(jq -r '.enabled | index("devkit-laravel")' "$init_a/.devkit/toolkit.json")" != "null" ] \
  || fail "--preset did not carry the preset's plugins"
resolve --validate --project="$init_a" >/dev/null || fail "--preset produced a config that fails --validate"

init_b="$TMP_DIR/init-enable"
mkdir -p "$init_b"
resolve --enable=devkit-laravel,devkit-vue --project="$init_b" >/dev/null || fail "--enable failed"
[ "$(jq -c '.enabled' "$init_b/.devkit/toolkit.json")" = '["devkit-laravel","devkit-vue"]' ] \
  || fail "--enable wrote the wrong list: $(jq -c '.enabled' "$init_b/.devkit/toolkit.json")"
resolve --validate --project="$init_b" >/dev/null || fail "--enable produced a config that fails --validate"

resolve --preset=no-such-preset --project="$TMP_DIR/init-bad" >/dev/null \
  && fail "an unknown preset must exit non-zero"
[ -e "$TMP_DIR/init-bad/.devkit/toolkit.json" ] && fail "a failed --preset still wrote a config"

resolve --enable=devkit-laravel --project="$init_b" >/dev/null \
  && fail "--enable must refuse to overwrite an existing config"

# A rejected list must leave nothing behind. A config written before it is checked
# is worse than no config: --init then refuses to replace it, so a typo can only be
# undone by deleting the file by hand.
init_reject() {
  local dir="$TMP_DIR/init-reject-$1"
  mkdir -p "$dir"
  resolve "$2" --project="$dir" >/dev/null && fail "$2 should have been rejected"
  [ -e "$dir/.devkit/toolkit.json" ] && fail "$2 was rejected but still wrote a config"
  return 0
}
init_reject unknown --enable=devkit-bogus
init_reject badname --enable=Foo
init_reject commas --enable=,,

# An empty flag value must not fall back to the interactive prompts — stdin is closed
# in `resolve`, so a fall-through would read EOF instead of reporting the mistake, and
# each flag has to name itself.
init_reject empty --enable=
grep -q "^ERROR: --enable needs at least one plugin name" "$TMP_DIR/err" \
  || fail "an empty --enable did not report its own error: $(cat "$TMP_DIR/err")"
init_reject nopreset --preset=
grep -q "^ERROR: --preset needs a name" "$TMP_DIR/err" \
  || fail "an empty --preset did not report its own error: $(cat "$TMP_DIR/err")"

# --- write_json ----------------------------------------------------------------
# Every JSON write in the installer and the adapters goes through this. A plain
# `producer > dest` truncates on setup, so the destination must survive a refusal.

wj="$TMP_DIR/wj.json"
printf '{"keep":1}\n' > "$wj"
chmod 600 "$wj"

write_json "$wj" "not json at all" 2>/dev/null && fail "invalid JSON was written"
[ "$(jq -r .keep "$wj")" = "1" ] || fail "a rejected invalid write damaged the destination"

write_json "$wj" "" 2>/dev/null && fail "an empty producer was allowed to truncate the destination"
[ "$(jq -r .keep "$wj")" = "1" ] || fail "a rejected empty write damaged the destination"

write_json "$wj" '{}' || fail "an empty object is valid JSON and must be written"
[ "$(jq -c . "$wj")" = "{}" ] || fail "the empty object was not written"

printf '{"keep":1}\n' > "$wj"
ln -s "$wj" "$TMP_DIR/wj-link.json"
write_json "$TMP_DIR/wj-link.json" '{"keep":2}' || fail "writing through a symlink failed"
[ -L "$TMP_DIR/wj-link.json" ] || fail "the symlinked destination was replaced by a regular file"
[ "$(jq -r .keep "$wj")" = "2" ] || fail "the symlink target was not updated"
[ "$(stat -f %Lp "$wj" 2>/dev/null || stat -c %a "$wj")" = "600" ] \
  || fail "the destination's mode was widened by the write"
ls "$TMP_DIR"/*.devkit.tmp.* >/dev/null 2>&1 && fail "write_json left a temp file behind"

echo "resolve tests passed"
