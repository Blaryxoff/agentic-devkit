# Pair setup — two-agent chat

Vendored from the `two-agent-chat` cookbook recipe in [`umputun/agterm`](https://github.com/umputun/agterm/tree/master/cookbook/two-agent-chat), MIT.
`scripts/peer-chat.py` is a maintained fork with Cursor support; `scripts/LICENSE-agterm.txt` is its licence.
Merge upstream updates while preserving the Cursor profile, input parser, focus reports, sender labels and regression tests.

## Requirements

| Need | Why |
|---|---|
| agterm **0.24.0+** | Added `surface cursor`; the script refuses to type without it |
| Python **3.10+** | Script runtime |
| Both agents already installed and running, one per pane | The recipe never starts an agent |
| `AGTERMCTL` set to a full path | Only if `agtermctl` is not on `PATH` under that name |

## Layout is fixed

**Claude Code or Cursor left, Codex right.** The panes are fixed in the script's profiles, so a split arranged
the other way sends every message to the wrong pane. A session with no split is refused outright.

## Put the script on PATH

Both sides call the bare `peer-chat.py` from `PATH`. Codex's approval rules match a literal argv;
a variable or substitution makes Codex evaluate the request as a shell wrapper that no prefix rule
can match. Cursor also needs this path because its shell need not export `DEVKIT_HOME`:

```bash
ln -sf "$DEVKIT_HOME/plugins/core/skills/pair/scripts/peer-chat.py" ~/.local/bin/peer-chat.py
```

Any directory already on `PATH` works. Keep the executable bit.

## Codex, once per machine

Add these rules to `~/.codex/rules/default.rules`, creating the file if needed, so Codex can reserve and
send file-backed messages without a separate approval each time:

```python
prefix_rule(pattern=["peer-chat.py", "--prepare-message"], decision="allow")
prefix_rule(pattern=["peer-chat.py", "--to", "claude", "--message-file"], decision="allow")
prefix_rule(pattern=["peer-chat.py", "--to", "cursor", "--message-file"], decision="allow")
```

Keep the rule for the left agent you use, or both when you use both layouts.

Start Codex so it can tell which pane it is in — it strips `AGTERM_SESSION_ID` from tool subprocesses,
and nothing inside its sandbox recovers the value:

```bash
codex -c "shell_environment_policy.set.AGTERM_SESSION_ID=\"$AGTERM_SESSION_ID\""
```

Put the flag in your launcher wrapper and it applies to every pane. Without it the script falls back to
matching the git checkout, and **refuses when several sessions share one checkout** — every worktree of
a repository maps to the same checkout. That refusal is correct behaviour, not a bug.

## Wrapper-launched agents

The script reads the pane's command from agterm and looks for `claude` / `cursor-agent` / `codex`. A wrapper's name is
what agterm sees instead, so pass `--target-command <name>` (a path works; only the last component is
compared), or set `PEER_CHAT_CLAUDE_COMMAND` / `PEER_CHAT_CURSOR_COMMAND` / `PEER_CHAT_CODEX_COMMAND`.
When sending to Codex, the left peer must also be recognisable to choose its sender label; set its
command environment variable in that pane's tool environment if it uses a wrapper. An agent whose
launcher leaves no stable name in the pane's command line cannot be targeted at all.

## Cursor left pane

Start `cursor-agent` in the same checkout as Codex. Use `--model auto` if your account cannot use the
configured named model. Core skills, including pair, are linked by `bin/devkit-install` into
`~/.cursor/skills/<frontmatter-name>` (for example, `~/.cursor/skills/devkit-coder`).

Cursor sends to Codex with `--to codex --stdin`; Codex replies with `--to cursor --message-file NAME`.
The script recognises Cursor's boxed `→` input and model/path footer, with a mode row in Ask/Plan.
Unknown layouts, menus and trailing dialogs block delivery. Cursor renders its caret itself and reports terminal cursor column
zero; a stable empty placeholder and visible body checks establish input ownership.

The script sends a temporary terminal focus-in report so Cursor scrolls long input to the caret even
when its pane is in the background. It restores the focus report after delivery or cleanup using the
current agterm session/window selection and, on macOS, `/usr/bin/lsappinfo` to check the foreground app.
This changes Cursor's reported focus during the send without selecting a tab or activating a window.
Backspaces are sent as separate events because Cursor can misread batched backspaces.

Messages with emoji, wide glyphs or combining characters use an ASCII JSON envelope after the sender
label: `JSON peer message: {"message": "..."}`. The receiving skill decodes `message` before replying.
This preserves the text while avoiding broken Unicode in Cursor's rendered input. Ordinary Latin and
Cyrillic messages keep the plain-text form.

## Limits worth knowing

- **Do not leave half-written input in a pane about to receive a message.** The pre-write gate checks
  the caret at column 2 for Claude/Codex and column 0 for Cursor. Claude drafts sitting at column 2
  can pass. Codex and Cursor also require their known placeholders, which a matching draft can imitate.
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
