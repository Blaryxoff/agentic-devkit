# Pair wire protocol — verified command shapes

Every shape below was exercised against a live Claude Code TUI and a live Codex TUI inside agterm. Behaviour
notes are observations, not inferences.

## Resolve and verify a target

```bash
agtermctl tree --json | python3 -c '
import sys, json
t = json.load(sys.stdin)["result"]["tree"]
for w in t["workspaces"]:
    for s in w["sessions"]:
        print(s["id"], s.get("foreground"), s.get("status"), s["cwd"], "|", s["name"])'
```

Sample of a real tree — note that several sessions per CLI per repo is the normal case:

```
1A2B3C4D-…  primary  ['claude']              active   /Users/u/src/app-a     | App A
5E6F7A8B-…  primary  ['codex']               None     /Users/u/src/app-b     | App B
9C0D1E2F-…  split    ['claude']              None     /Users/u/src/app-b     | App B review
3A4B5C6D-…  primary  ['claude', '--resume']  None     /Users/u/src/app-c/…   | App C worktree
```

`foreground` is omitted when the pane sits at a bare shell prompt, so a session with no `foreground` is not
running an agent. `tree` reads the frontmost window unless given `--window`, and a peer can run in a split pane, so enumerate
windows with `window list` and read `splitForeground` alongside `foreground`.

Re-resolve immediately before each send and confirm the pane still carries the expected process and `cwd`. A
dead id fails with `notFound` and a shortened prefix can fail `ambiguous` — neither silently misdelivers, but
both mean stop rather than retry. Also read the last lines of the pane first: never send while the peer is
mid-turn or showing an approval prompt, a trust prompt, or a selection list, because the trailing newline
accepts the highlighted default.

## Send one message

Two calls: the text, then a bare newline.

```bash
agtermctl session type --window "$WIN" --target "$PEER" --pane "$PANE" ">>REQ $NONCE-7 <one line>"
printf '\n' | agtermctl session type --window "$WIN" --target "$PEER" --pane "$PANE" --stdin
```

- `session type` does **not** append Enter. Text alone sits in the composer unsent. Verified.
- Every `\n` in the text submits at that point. `printf 'a\nb\n' | session type --stdin` submitted `a`, then
  `b`, as two separate prompts — so a message carries no newline of its own.
- **Text and newline in one call does not submit in the Codex TUI.** Verified against a live Codex session:
  `printf 'Reply with exactly ATOMIC-A...\n' | session type --stdin` left the text in the composer at
  `0 in · 0 out`; a following bare-newline call submitted it and the model answered. A trailing `\r` in the
  same call behaved identically. The burst is treated as a paste, and the composer keeps the terminator.
- Claude Code **does** submit on the single-call form — verified, it answered `ATOMIC-CL`. That asymmetry is
  why an always-one-call recipe fails in the Claude → Codex direction only, and looks intermittent.
- A single call works against a plain **shell** (`printf 'echo X\n' | session type --stdin` ran the command).
  Do not generalize a shell result to a TUI; that is how the one-call recipe got in.

## Confirm the send landed

The empty-composer marker doubles as the pre-send idle check and the post-send submission check:

| Peer | Composer is empty when the pane shows |
|---|---|
| Codex | `Ask Codex to do anything` |
| Claude Code | a bare `❯` line with nothing after it |

```bash
agtermctl session text --window "$WIN" --target "$PEER" --pane "$PANE" --lines 14 \
  | grep -q "Ask Codex to do anything" && echo empty || echo occupied
```

Verified on both TUIs: `empty` at rest, `occupied` while text sits unsent, `empty` again after the newline
lands. Recover an `occupied` composer with one more bare newline — never with more text, which appends to the
same unsent buffer.

A prefix match on the composer marker is **not** a substitute: Codex renders submitted user messages in the
transcript with the same leading `›`, so matching `›` plus your text finds your own submitted message and
reports a false failure.
- Escape sequences pass through: `printf '\033[B' | agtermctl session type --target "$P" --stdin` moves the
  selection down a TUI menu. Use this only when the operator asked you to answer a specific prompt — never to
  accept an approval on the peer's behalf.

## Bootstrap line

The channel does not exist until the peer has been told it exists and that the operator authorized it. A cold
send of a protocol marker was refused outright:

```
I'm not going to emit the [PEER-REPLY] line — I have no verified peer channel to claude-a, and blindly
…
```

After a bootstrap line carrying the authorization, the same peer answered on the first try:

```
<<RPY boot status=ready
```

Codex, same bootstrap, answered `• <<RPY boot Acknowledged.` — the leading `•` is its own TUI chrome, which is
why the matcher takes a substring rather than an anchored line.

## Why the two prefixes differ

Your request is echoed into the peer's buffer before its answer is. A symmetric marker makes your own request
match the reply grep — observed: `grep -c 'PEER-REPLY id=boot'` returned 1 with no reply present, matching the
echo of a request that quoted the reply format.

So: request `>>REQ <id>`, reply `<<RPY <id>`, and the request **describes** the reply prefix without spelling
it. The wording that worked verbatim:

```
answer with ONE line starting with the five characters left-angle left-angle R P Y, then a space, then the
same id
```

## Poll for the reply

```bash
agtermctl session text --window "$WIN" --target "$PEER" --pane "$PANE" --all \
  | grep -F "<<RPY $NONCE-7"
```

`--all` includes scrollback, so every earlier round's reply is still in the match space. Snapshot the buffer
before sending and accept only a marker absent from that baseline; make request ids monotonic and never reuse
one.

Backoff, do not hammer: 2s, 5s, 10s, 20s, 30s. Readiness signals, in order of trust:

| Signal | Trust |
|---|---|
| `<<RPY <id>` present in the buffer | authoritative |
| `status` in `tree --json` moved `active` → `completed` | Claude peers only — observed working |
| `status` still `active` | says nothing — a Codex peer stayed `active` after erroring out |

`session text` returns rendered screen: a long line wraps at the pane width with leading padding on the
continuation. Keep replies short enough to land on one line; anything longer cites a path or a SHA instead.

## Closing

Leave the peer at its prompt. Do not `session close` a session you did not create — the operator's session and
its authenticated context belong to that launch, and a control-socket respawn inherits the GUI environment
instead (an observed Codex respawn died on `Missing environment variable: OPENAI_API_KEY`, which the operator's
login shell supplies).
