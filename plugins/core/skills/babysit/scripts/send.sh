#!/usr/bin/env bash
set -uo pipefail

plain=0
if [ "${1:-}" = "--plain" ]; then plain=1; shift; fi
sid="${1:?usage: send.sh [--plain] <session-uuid> <transcript|-> <message>}"
transcript_file="${2:?missing transcript path or -}"
message="${3:?missing message}"

claude_in_front() {
  agtermctl tree --json 2>/dev/null | python3 -c '
import json, os, sys
sid = sys.argv[1]
def walk(node):
    for ws in node.get("workspaces", []):
        yield from ws.get("sessions", [])
tree = json.load(sys.stdin)["result"]["tree"]
left = next((s.get("foreground") or [] for s in walk(tree) if s["id"] == sid), [])
sys.exit(0 if left and os.path.basename(left[0]) == "claude" else 1)
' "$sid"
}

composer() {
  agtermctl session text --target "$sid" --pane left --lines 30 2>/dev/null | python3 -c '
import re, sys
needle = sys.argv[1].replace(" ", "")
lines = [l for l in sys.stdin.read().splitlines() if l.strip()]
rule = re.compile(r"^\s*─{10,}")
prompt = max((i for i, l in enumerate(lines) if l.lstrip().startswith("❯")), default=None)
close = next((i for i in range(prompt + 1, len(lines)) if rule.match(lines[i])), None) if prompt else None
if prompt is None or close is None or not rule.match(lines[prompt - 1]):
    print("missing"); sys.exit()
footer = lines[close + 1:]
if len(footer) > 6 or any(not l.startswith("  ") for l in footer):
    print("missing"); sys.exit()
body = " ".join([lines[prompt].lstrip()[1:]] + lines[prompt + 1:close]).strip()
if re.match(r"\d+\.\s", body):
    print("chooser")
elif needle:
    print("ours" if needle in body.replace(" ", "") else "changed")
else:
    print("prompt")
' "${1:-}"
}

state="missing"
if claude_in_front; then state="$(composer)"; fi
if [ "$state" = "prompt" ]; then
  [ "$(agtermctl surface cursor --target "surface:${sid}:left" 2>/dev/null)" = "2" ] && state="empty" || state="occupied"
fi
if [ "$state" != "empty" ]; then
  echo "refused: composer is $state - nothing typed" >&2
  exit 3
fi

tag="[Supervisor $(date +%H:%M:%S)]"
text="$(printf '%s' "$message" | tr '\n' ' ')"
[ "$plain" -eq 1 ] || text="$tag $text"
offset=0
[ -f "$transcript_file" ] && offset=$(stat -f %z "$transcript_file")

if ! agtermctl session type "$text" --target "$sid" --pane left >/dev/null; then
  echo "typing failed midway - read the pane, do not resend" >&2
  exit 5
fi
sleep 1
if [ "$(composer "${text:0:40}")" != "ours" ]; then
  echo "composer changed before Return - nothing submitted; read the pane, do not resend" >&2
  exit 5
fi
if ! agtermctl session type $'\r' --target "$sid" --pane left >/dev/null; then
  echo "Return failed - read the pane, do not resend" >&2
  exit 5
fi
sleep 5

if [ "$plain" -eq 0 ] && [ -f "$transcript_file" ] && tail -c +$((offset + 1)) "$transcript_file" | grep -qF "$tag"; then
  echo "delivered: $tag"
  exit 0
fi
if [ "$(composer)" = "prompt" ]; then
  echo "submitted, not yet in transcript (queued behind a running turn?) - do not resend"
  exit 4
fi
echo "submitted state unclear - read the pane, do not resend" >&2
exit 5
