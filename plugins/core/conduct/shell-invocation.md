# Shell Invocation

Make every command an agent runs through a shell tool unable to block on stdin. Blocking on stdin is the most
common way a session, a subagent, or a whole turn stops making progress.

## Why a shell hangs

An agent harness does not guarantee a shell call's stdin. It is sometimes `/dev/null` and sometimes a live
socket back to the harness that never sends a byte and never closes, and children inherit it. Any `read`, any
prompt, any CLI that appends stdin to its own input then blocks forever.

A tool timeout typically **detaches** the process rather than killing it: the turn moves on, the blocked
process survives holding whatever lock, port, or worktree it took, and nothing reaps it. Assume no timeout
will rescue a command. Make it unable to block instead.

## Rules

- Redirect stdin for any command that can read it — `cmd … < /dev/null`. The only exception is a command you
  are deliberately feeding.
- Prefer a non-interactive flag over an interactive prompt (`--yes`, `--no-input`, `--batch`, an explicit
  preset). A tool that offers none is the thing to fix, not to work around with a guessed keystroke.
- Never watch a long-running command through `tail`. It buffers until EOF, so a blocked run looks identical to
  a slow one and the line naming the cause never arrives. `head -n N` does exit early, but it then SIGPIPEs the
  producer mid-run. Redirect to a file and read the file.
- Never launch an editor, pager, or REPL. Pass `--no-pager`, or set `GIT_PAGER=cat`, `PAGER=cat`,
  `GIT_EDITOR=true` when a command might reach for one.
- Do not build a workflow on `timeout`; stock macOS does not ship it.
- Launch a peer CLI with stdin closed: `codex exec … "$(cat <prompt-file>)" < /dev/null`, `claude -p … < /dev/null`. Both read stdin even when the prompt is a positional argument. Write the prompt file in a separate call; a heredoc in the same compound command as the launch is the usual cause. `plugins/core/hooks/peer-cli-gate.sh` refuses the launch when the redirect is missing, so a hang here never means the prompt failed to arrive.
- A script this repository ships obeys the same rule: when it needs a terminal it does not have, it exits with
  a message naming the non-interactive flag. Guard with `[ -t 0 ]`; never prompt into the void. That refusal
  stands even for a caller piping answers in — a menu's numbering is not a contract, the flag is.

## Diagnosing one that is already stuck

`lsof -p <pid> -a -d 0` prints the process's stdin. A `/dev/null` character device rules this failure out; a
`unix` socket is consistent with it but does not prove it, because a healthy process can hold one. Confirm with
near-zero CPU (`ps -o time=`) against minutes of elapsed time. Killing a process confirmed that way lets the
detached task complete immediately.
