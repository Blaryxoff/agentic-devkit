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
- Use a non-interactive flag (`--yes`, `--no-input`, `--batch`, or an explicit preset) whenever one is available.
  When a tool offers no such flag, fix the tool or invocation instead of supplying a guessed keystroke.
- Redirect long-running command output to a file and read it as needed. `tail` buffers until EOF, so a blocked run looks identical to
  a slow one and the line naming the cause never arrives. `head -n N` does exit early, but it then SIGPIPEs the
  producer mid-run. Redirect to a file and read the file.
- Keep commands non-interactive: pass `--no-pager`, or set `GIT_PAGER=cat`, `PAGER=cat`,
  and `GIT_EDITOR=true` when a command might launch an editor, pager, or REPL.
- Build portable workflows without relying on `timeout`, which stock macOS does not ship.
- Launch a peer CLI with stdin closed: `codex exec … "$(cat <prompt-file>)" < /dev/null`, `claude -p … < /dev/null`. Both read stdin even when the prompt is a positional argument. Write the prompt file in a separate call; a heredoc in the same compound command as the launch is the usual cause. `plugins/core/hooks/peer-cli-gate.sh` refuses the launch when the redirect is missing, so a hang here never means the prompt failed to arrive.
- A script this repository ships follows the same rule: when it needs a terminal it does not have, it exits with
  a message naming the non-interactive flag. Guard with `[ -t 0 ]` and use an explicit flag for non-interactive
  operation. A caller piping answers in still needs the flag because a menu's numbering is not a contract.

## Diagnosing one that is already stuck

`lsof -p <pid> -a -d 0` prints the process's stdin. A `/dev/null` character device rules this failure out; a
`unix` socket is consistent with it but does not prove it, because a healthy process can hold one. Confirm with
near-zero CPU (`ps -o time=`) against minutes of elapsed time. Killing a process confirmed that way lets the
detached task complete immediately.
