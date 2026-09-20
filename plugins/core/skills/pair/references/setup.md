# Pair setup — two-agent chat

Vendored from the `two-agent-chat` cookbook recipe in [`umputun/agterm`](https://github.com/umputun/agterm/tree/master/cookbook/two-agent-chat), MIT.
`scripts/peer-chat.py` is upstream's file unmodified; `scripts/LICENSE-agterm.txt` is its licence.
Re-vendor by copying the newer `peer-chat.py` over ours and re-reading upstream's README for rule changes.

## Requirements

| Need | Why |
|---|---|
| agterm **0.24.0+** | Added `surface cursor`; the script refuses to type without it |
| Python **3.10+** | Script runtime |
| Both agents already installed and running, one per pane | The recipe never starts an agent |
| `AGTERMCTL` set to a full path | Only if `agtermctl` is not on `PATH` under that name |

## Layout is fixed

**Claude Code left, Codex right.** The panes are fixed in the script's profiles, so a split arranged
the other way sends every message to the wrong pane. A session with no split is refused outright.

## Put the script on PATH

The Claude side can call it through `$DEVKIT_HOME`, but **the Codex side cannot**: its approval rules
match a literal argv, and a variable or substitution makes Codex evaluate the whole request as a shell
wrapper that no prefix rule can match. So Codex needs a bare `peer-chat.py`:

```bash
ln -sf "$DEVKIT_HOME/plugins/core/skills/pair/scripts/peer-chat.py" ~/.local/bin/peer-chat.py
```

Any directory already on `PATH` works. Keep the executable bit.

## Codex, once per machine

Add both rules to `~/.codex/rules/default.rules`, creating the file if needed, so Codex can reserve and
send file-backed messages without a separate approval each time:

```python
prefix_rule(pattern=["peer-chat.py", "--prepare-message"], decision="allow")
prefix_rule(pattern=["peer-chat.py", "--to", "claude", "--message-file"], decision="allow")
```

Start Codex so it can tell which pane it is in — it strips `AGTERM_SESSION_ID` from tool subprocesses,
and nothing inside its sandbox recovers the value:

```bash
codex -c "shell_environment_policy.set.AGTERM_SESSION_ID=\"$AGTERM_SESSION_ID\""
```

Put the flag in your launcher wrapper and it applies to every pane. Without it the script falls back to
matching the git checkout, and **refuses when several sessions share one checkout** — every worktree of
a repository maps to the same checkout. That refusal is correct behaviour, not a bug.

## Wrapper-launched agents

The script reads the pane's command from agterm and looks for `claude` / `codex`. A wrapper's name is
what agterm sees instead, so pass `--target-command <name>` (a path works; only the last component is
compared), or set `PEER_CHAT_CLAUDE_COMMAND` / `PEER_CHAT_CODEX_COMMAND`. Only the pane being sent *to*
is checked. An agent whose launcher leaves no stable name in the pane's command line cannot be targeted
at all.

## Limits worth knowing

- **Do not leave half-written input in a pane about to receive a message.** The pre-write gate checks
  the caret at column 2; any draft sitting at column 2 passes. Codex also requires its
  `Ask Codex to do anything` placeholder, which a draft matching that string can imitate.
- **Do not type in the receiving pane during a send.** Cleanup verifies it owns every visible row
  before each backspace batch, but a keystroke arriving after that check can still be erased.
- **A dialog on screen stops the send**, but a chooser appearing between the final check and the
  separate Return can still receive that key — agterm has no conditional type operation.
- **The first exchange may look like a hang.** An agent may raise its own approval prompt before
  running the script, and neither side will answer it; it sits until the user approves in that pane.
- **A busy pane costs about forty seconds** — five pre-write retries at ten-second intervals, then
  exit 1 having typed nothing.
- **A multi-row Codex shortcut overlay reads as busy** and blocks the send until it closes.
- **Rendered text is not a byte-level receipt.** agterm exposes plain screen text, which omits an ASCII
  space consumed at a line wrap, so a correct wrap and a missing space look identical.
- **No transcript is kept.** The conversation lives in the two panes and is gone when the session ends.
