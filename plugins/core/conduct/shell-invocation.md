# Shell Invocation

Rules for every command an agent runs through a shell tool. A command that blocks on stdin is the most common
way a session, a subagent, or a whole turn stops making progress.

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
- Never pipe a long-running command through `tail` or `head`. They buffer until EOF, so a blocked run is
  indistinguishable from a slow one and the line naming the cause never appears. Redirect to a file.
- Never launch an editor, pager, or REPL. Pass `--no-pager`, or set `GIT_PAGER=cat`, `PAGER=cat`,
  `GIT_EDITOR=true` when a command might reach for one.
- Do not build a workflow on `timeout`; stock macOS does not ship it.
- A script this repository ships obeys the same rule: when it needs a terminal it does not have, it exits with
  a message naming the non-interactive flag. Guard with `[ -t 0 ]`; never prompt into the void.

## Diagnosing one that is already stuck

`lsof -p <pid> -a -d 0` prints the process's stdin. A `unix` socket is this failure; a `/dev/null` character
device is not. A blocked process burns no CPU — compare `ps -o time=` against elapsed time. Killing it lets
the detached task complete immediately.
