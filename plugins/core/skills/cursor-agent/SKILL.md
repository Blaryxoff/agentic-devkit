---
name: devkit-cursor-agent
description: >-
  delegate a task to the Cursor CLI (`cursor-agent`) as a working agent that edits the repo, or consult it read-only.
  Invoke whenever the user names Cursor for the work — "run cursor on X", "запусти курсор", "delegate this to cursor",
  "let cursor do it", "ask cursor", "cursor review X", "have cursor review", "поревьюй курсором", "cursor-agent",
  "спроси курсор". Naming Cursor authorizes the delegation itself, so
  never ask permission to hand the task over; the user's verb then picks write mode or read-only. Never self-invoke on a
  heuristic such as "this task is large" — an explicit user mention is the only trigger. No-op when the current harness
  is already Cursor. Peer-prompt rules:
  plugins/core/conduct/cross-agent-review.md.
---

# Cursor Agent

`cursor-agent` is a full coding agent with shell and write access, not a second opinion. The default path is
**delegate and let it work**.

## Gate

1. The user named Cursor in the current turn. That is the only trigger — never infer one from task size or difficulty.
2. The current harness is **not** Cursor. If it is, do the work natively; delegating to yourself burns a context for nothing.
3. `command -v cursor-agent` succeeds and `cursor-agent status` shows a logged-in account.

**Naming Cursor is the approval to delegate.** Never ask "may I let Cursor edit files?" and never narrow the task to
something safer than what was asked. Approval to delegate is not a choice of mode — pick that from the user's verb
below, and once a verb asks for changes, run write mode without a further confirmation step.

## Two paths

Run every command from inside the target repository. `cursor-agent` takes its workspace from the current working
directory; a repo path named only inside the prompt does not move it. Use `--workspace <path>` when you cannot `cd`.

| User's verb | Mode | Command |
|---|---|---|
| implement, fix, refactor, "run cursor on X", "let cursor do it" | write | `cursor-agent -p -f --output-format json "<prompt>" < /dev/null` |
| explain, analyze, review, "ask cursor", "what does cursor think" | read-only | `cursor-agent -p --trust --mode plan --output-format json "<prompt>" < /dev/null` |

`--mode ask` instead of `--mode plan` for pure Q&A with no plan output. `-f` implies trust; `--trust` alone leaves the
edit tools gated.

`-f` is not a sandbox. It grants unrestricted shell on the real working tree, so the `preToolUse` gates below constrain
only Cursor's edit tools — a shell command writes straight past them. That is what the user authorizes by naming Cursor,
and it is why the repo state, not Cursor's report, is the source of truth after a run.

## Invocation rules

- **Always `--output-format json`**, then read `.result` with `jq -r '.result'`. Text mode interleaves the trace with
  the answer.
- **Exit code is not a success signal.** A run whose edits were refused still exits 0 and reports the refusal only in
  prose. Judge every run by `.result` text plus the actual repo state.
- **Always append `< /dev/null`** so an inherited pipe can never leave the process waiting on stdin.
- **Raise the shell timeout to ~10 minutes** using the current harness's mechanism, or run the command in the
  background and poll. Trivial prompts take ~10s, a one-file fix ~40s, and real tasks run minutes — the usual
  two-minute default kills them mid-edit.
- **First run in an untrusted directory exits 1** with a workspace-trust banner and does no work. `-f` or `--trust`
  clears it.
- Use `cursor-agent`, never the `agent` alias.

## The coder-gate is on Cursor's edit tools

devkit installs `~/.cursor/hooks/hooks.json` with `coder-gate` + `comment-gate` on `preToolUse`, matching
`Write|StrReplace|Edit|MultiEdit|Delete|EditNotebook|apply_patch`. `coder-gate` refuses all of them until the session
transcript shows the coder skill was read. `-f` does **not** bypass it — it is a hook, not a permission. A blocked run
reports "an edit hook blocked it", still exits 0, and changes nothing.

Open every write-mode prompt with:

```text
Activate the devkit-core--coder skill first (read ~/.cursor/skills/devkit-core--coder/SKILL.md), then <task>.
```

**That line does not currently clear the gate.** `coder-gate.sh` looks for a transcript entry whose tool is `Read`;
Cursor writes `ReadFile` in `~/.cursor/projects/<slug>/agent-transcripts/<sid>/<sid>.jsonl`, so the match never fires
and edits are refused however faithfully Cursor reads the skill. Runs that appear to succeed fail open instead —
`coder-gate.sh` exits 0 when the transcript is not yet readable. Until the hook matches `ReadFile`, treat a refused
delegation as expected: verify the repo state, then repair the hook or do the work natively.

## Prompt construction

Follow `plugins/core/conduct/cross-agent-review.md` → "Prompt requirements": self-contained, exact scope, explicit
output shape, and **no further delegation** — the prompt never tells Cursor to invoke another CLI or a cross-check.

Add for write-mode prompts:

- the absolute repo path and the exact files or feature in scope;
- what must not change (adjacent modules, migrations, config);
- the verification Cursor should run itself (test command, lint) and report;
- "report every file you changed".

## Options worth using

| Need | Flag |
|---|---|
| Keep editing the repo yourself while Cursor runs | `-w [name]` — isolated worktree at `~/.cursor/worktrees/<repo>/<name>` |
| Base that worktree on a specific ref | `--worktree-base <branch>` |
| Pick the model | `--model <id>`; enumerate with `cursor-agent --list-models` |
| Follow-up turn with context intact | `--resume <session_id>` — take the id from the previous run's JSON |
| Extra repo root (multi-repo project) | `--add-dir <path>` |

Without `-w`, Cursor edits the working tree in place — correct when you are handing the repo over and waiting. With
`-w`, every change lands in the worktree instead: verify there, and merge or cherry-pick it back yourself. `-w` is worth
the extra step only when you keep editing the same repo while Cursor runs.

## After the run

1. **Verify against the repo, not the report.** `git status --short` and `git diff` in the tree Cursor actually wrote to
   — a run that claims success while a hook silently refused its edits looks identical in prose to one that worked.
2. Run the verification the change warrants per `plugins/core/conduct/verification-loop.md`. Cursor's own test run is a
   claim until you reproduce it.
3. Report to the user: what Cursor changed, what you verified, and anything it reported as blocked or skipped.

On failure — missing binary, not logged in, empty `.result`, refused edits — retry at most once, then state
`Cursor: failed — <reason>` in one line and either do the work natively or ask. Never widen permissions past `-f` to
force a run through.

## When not to use

- The user did not name Cursor. Do the work yourself.
- You are running inside Cursor already.
- The task is a Claude↔Codex second opinion — that is `devkit-crosscheck`, a different mechanism with a read-only peer.
- A review request that does **not** name Cursor — code, branch, and plan reviews route per
  `plugins/core/conduct/review-routing.md`. Naming Cursor as the reviewer overrides that routing: run the review here in
  read-only mode, then verify its findings against the cited files before reporting any of them.
