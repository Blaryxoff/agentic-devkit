#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$ROOT/plugins/core/skills/babysit"
SCRIPTS="$SKILL_DIR/scripts"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for f in SKILL.md references/stalls.md scripts/roster.py scripts/poll.sh scripts/tail.py scripts/send.sh scripts/waker.sh; do
  [ -f "$SKILL_DIR/$f" ] || fail "babysit $f is missing"
done
for f in roster.py poll.sh tail.py send.sh waker.sh; do
  [ -x "$SCRIPTS/$f" ] || fail "babysit scripts/$f is not executable"
done
bash -n "$SCRIPTS/poll.sh" "$SCRIPTS/send.sh" "$SCRIPTS/waker.sh"

python3 - "$SKILL_DIR/SKILL.md" <<'PY'
from pathlib import Path
import sys
import yaml

content = Path(sys.argv[1]).read_text()
_, frontmatter, body = content.split("---\n", 2)
metadata = yaml.safe_load(frontmatter)
assert metadata["name"] == "devkit-babysit"
assert "claudeSubagent" not in metadata, "a subagent cannot own the poll loop or report each round"
description = " ".join(metadata["description"].lower().split())
for phrase in ("manual trigger only", "присмотри за сессиями", "devkit-pair", "devkit-task"):
    assert phrase in description, phrase
for rule in ("CronCreate", "CronDelete", "send.sh", "references/stalls.md", "Owner keeps"):
    assert rule in body, rule
PY

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"
cat >"$work/bin/agtermctl" <<'PY'
#!/usr/bin/env python3
import json, os, sys
d = os.environ["FAKE_DIR"]
def read(name, default=""):
    try:
        return open(f"{d}/{name}").read().strip()
    except FileNotFoundError:
        return default
def write(name, value):
    open(f"{d}/{name}", "w").write(value)
args = sys.argv[1:]
if args[:1] == ["tree"]:
    print(json.dumps({"result": {"tree": {"workspaces": [{"sessions": [
        {"id": "ABCD", "foreground": [read("fg", "claude")]}]}]}}}))
elif args[:2] == ["surface", "cursor"]:
    print(read("caret", "2"))
elif args[:2] == ["session", "text"]:
    mode = read("mode", "live")
    if mode == "dialog":
        print("  Do you trust the files in this folder?\n  1. Yes\n  2. No")
    else:
        print("  working output\n────────────\n❯ " + read("composer") + "\n────────────\n  Opus | main | 5h: 3%")
        if mode == "stale":
            print("$ ls\nREADME.md")
elif args[:2] == ["session", "type"]:
    text = args[2]
    with open(f"{d}/typed", "a") as log:
        log.write(repr(text) + "\n")
    if text == "\r":
        with open(f"{d}/transcript.jsonl", "a") as t:
            t.write(json.dumps({"type": "user", "message": {"content": read("composer")}}) + "\n")
        write("composer", "")
    elif read("drop") != "1":
        write("composer", text if read("caret", "2") == "2" else read("composer") + text)
PY
chmod +x "$work/bin/agtermctl"
export PATH="$work/bin:$PATH" FAKE_DIR="$work"

reset() {
  rm -f "$work/typed" "$work/drop" "$work/mode" "$work/fg"
  : >"$work/transcript.jsonl"
  printf '%s' "${1:-}" >"$work/composer"
  echo "${2:-2}" >"$work/caret"
}

send() {
  set +e
  "$SCRIPTS/send.sh" "$@" >/dev/null 2>&1
  code=$?
  set -e
}

reset
send ABCD "$work/transcript.jsonl" $'decide A\nthen B'
[ "$code" -eq 0 ] || fail "send.sh did not confirm delivery into an empty composer (exit $code)"
grep -q '\[Supervisor [0-9:]*\] decide A then B' "$work/transcript.jsonl" || fail "message was not tagged, collapsed and submitted"
[ "$(tail -1 "$work/typed")" = "'\\r'" ] || fail "send.sh did not submit with a separate carriage return"

reset "ok deploy" 2
send ABCD "$work/transcript.jsonl" "decide"
[ "$code" -eq 0 ] || fail "send.sh treated Claude's suggestion placeholder (caret at column 2) as an owner draft"

refused() {
  [ "$code" -eq 3 ] && [ ! -s "$work/typed" ] || fail "send.sh typed into: $1"
}
reset "merge it to dev" 19; send ABCD "$work/transcript.jsonl" "decide"; refused "an owner draft (caret past the prompt)"
reset "1. Yes, commit on the branch"; send ABCD "$work/transcript.jsonl" "decide"; refused "a chooser"
reset; echo dialog >"$work/mode"; send ABCD "$work/transcript.jsonl" "decide"; refused "a trust dialog"
reset; echo stale >"$work/mode"; send ABCD "$work/transcript.jsonl" "decide"; refused "a stale composer above shell output"
reset; echo zsh >"$work/fg"; send ABCD "$work/transcript.jsonl" "decide"; refused "a pane whose foreground is not claude"

reset; echo 1 >"$work/drop"
send ABCD "$work/transcript.jsonl" "decide"
[ "$code" -eq 5 ] || fail "send.sh did not stop when its text never reached the composer (exit $code)"
! grep -q "'\\r'" "$work/typed" || fail "send.sh pressed Return on a composer that does not hold its text"

printf 'ABCD label -\n' >"$work/sessions.txt"
reset; echo "You've hit your limit · resets at 2am" >"$work/composer"
out="$("$SCRIPTS/waker.sh" --dry-run 02:10 SUPERVISOR "$work/sessions.txt")"
grep -q 'WOULD WAKE ABCD' <<<"$out" || fail "waker did not recognise a usage-limit screen"
reset; echo "The rate limiter is saturated; the bucket rate-limits requests" >"$work/composer"
out="$("$SCRIPTS/waker.sh" --dry-run 02:10 SUPERVISOR "$work/sessions.txt")"
! grep -q 'WOULD WAKE' <<<"$out" || fail "waker matched ordinary rate-limit content"

cat >"$work/t.jsonl" <<'JSON'
{"type":"user","timestamp":"2026-01-01T10:00:00Z","message":{"content":"<system-reminder>skip</system-reminder>"}}
{"type":"assistant","timestamp":"2026-01-01T10:01:00Z","isSidechain":true,"message":{"content":[{"type":"text","text":"subagent noise"}]}}
{"type":"assistant","timestamp":"2026-01-01T10:02:00Z","message":{"content":[{"type":"text","text":"which option should I take?"}]}}
JSON
out="$("$SCRIPTS/tail.py" "$work/t.jsonl" 5)"
[ "$out" = $'[10:02Z] ASSISTANT: which option should I take?\n---' ] || fail "tail.py output: $out"

uuid=11111111-2222-3333-4444-555555555555
mkdir -p "$work/home/.claude/projects/-x"
: >"$work/home/.claude/projects/-x/$uuid.jsonl"
cat >"$work/bin/agtermctl" <<JSON
#!/usr/bin/env bash
echo '{"result":{"tree":{"workspaces":[{"sessions":[
 {"id":"AAAA-full","hasSplit":true,"context":"spec work","foreground":["claude","--resume","$uuid"],"splitForeground":["codex"]},
 {"id":"BBBB-full","foreground":["zsh"]},
 {"id":"SELF-full","foreground":["claude"]}]}]}}}'
JSON
out="$(HOME="$work/home" AGTERM_SESSION_ID=SELF-full "$SCRIPTS/roster.py" 2>/dev/null)"
[ "$out" = "AAAA-full spec-work $work/home/.claude/projects/-x/$uuid.jsonl" ] || fail "roster.py output: $out"

echo "babysit skill OK"
