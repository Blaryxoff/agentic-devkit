---
name: devkit-babysit
description: >-
  supervise selected running agent sessions in agterm: spot stalls, give technical direction and
  park owner decisions. Manual trigger ONLY: "babysit these sessions", "supervise the
  sessions", "присмотри за сессиями", "poll them every 30 min". Not devkit-pair (talk inside one
  split) nor devkit-task (drive one spec).
---

# Babysit

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this
> skill's symlink target), not the project root. `scripts/` and `references/` are relative to this skill's directory.

You are the supervisor of sessions that already work on their own. Provide decisions and unblockers while keeping
supervised checkouts unchanged.

## Gate

1. The user asked this turn for sessions to be supervised, or the prompt is a tick this skill scheduled
   (`/babysit poll <state-dir>`). A tick skips Setup and runs Poll.
2. Run in a top-level agterm session with `agtermctl` available. Use a recurring scheduler only when the harness
   exposes one; otherwise poll during the active turn and state that supervision ends when the turn ends.
3. Pin each selected primary by live session UUID, pane/pane ID and foreground command, regardless of harness or
   model. Use [references/sessions.md](references/sessions.md) for native steering and non-Claude targets. Never
   mistake its peer or another task in the same checkout for the owner. Stop only an unsupported delivery, not observation
   or the whole roster.

## Setup

Apply [agterm observation](../../conduct/agterm.md#observe-workers-and-collect-decisions) for capability checks,
bounded events/waits and owner questions. Activate the installed agterm skill for exact command flags.

1. `S=<scratchpad>/babysit`; `mkdir -p "$S"`.
2. Inventory: `scripts/roster.py > "$S/candidates.txt"`, one non-shell foreground per pane:
   `<full-id> <label> <transcript|-> <left|right> <command>`. This is an inventory, not authority to supervise every row.
   Copy only the user-selected endpoints into `$S/sessions.txt`; when selection is ambiguous, ask. Match each task by
   recent pane output and pin its pane ID from the live tree. Resolve a missing transcript only with that harness's
   parser and matching recent content; `-` is valid when the pane/native thread supplies evidence. Never use the
   supervisor's transcript or parse another harness's records as Claude.
3. Pin the goal and the stop condition from the request ("use the budget before the weekly reset", "until the specs
   are done"). Ask only when neither is stated.
4. Preserve the owner's power settings. Start a bounded `caffeinate` only when unattended supervision requires it and
   the owner authorized that window; report its duration and that a closed lid still sleeps.
5. Waker, only for Claude targets when a usage-limit reset falls inside the window: pass a Claude-only roster to
   `scripts/waker.sh --dry-run <HH:MM> <own-id> <claude-roster>`; never pass the mixed/Codex roster. The dry run
   must print no `WOULD WAKE` for a working pane (your own pane matches while a poll report quotes a limit message);
   then arm it with `nohup … & disown` without `--dry-run`. It wakes each limited Claude pane once — `continue`, or a
   resume prompt for your own — over four passes, logs every `send.sh` exit to `$S/waker.log`, then exits.
6. Run Poll once now.
7. When available, use `CronCreate`, recurring, at the user's interval (default 30 min) on minutes off :00/:30, prompt
   `/babysit poll <absolute $S>`. State the scheduler's lifetime. Without it, use active-turn polls and make no unattended
   monitoring claim. During a production write pause, use its agreed pause budget rather than the 30-minute default.
8. `agtermctl session context 'supervising N sessions: <goal>' --target "$AGTERM_SESSION_ID"`.

## Poll

1. Use `scripts/poll.sh "$S/sessions.txt"` for selected endpoints (`LN=`/`RN=` widen the selected/peer pane tails).
   Re-resolve each pinned pane ID to its current role/window before calling positional helpers; their roster fields
   do not follow swaps or window moves. Verify each foreground still matches the pinned endpoint. Observe the actual
   harness's usage indicator when the
   goal concerns a budget; `5h:`/`7d:` are examples, not a universal status format.
2. Classify each session: working · waiting on its peer (is the peer working?) · waiting on a background job ·
   blocked on a question or chooser · finished · limited · dead turn.
3. For a target not plainly working, read its selected pane and bounded native transcript/thread evidence. Use
   `scripts/tail.py <transcript> 3 3000` only for Claude records (timestamps are UTC). Match `references/stalls.md`
   only where the signal fits that harness; use `references/sessions.md` for delivery. Leave working sessions alone.
4. Report one bullet per session (see Report). With a scheduled tick, stop until the next tick. Without a scheduler,
   wait for the bounded poll interval in the active turn and repeat until the stop condition or explicit handoff.

Use bounded `events` subscriptions for status, session closure and tree changes to prompt an earlier targeted check.
Events and `statusChangedAt` do not prove useful work. Use `session wait` only after verifying status hooks and the
current run's active state; confirm completion in pane/transcript evidence. Keep periodic observations for silent stalls.

## Decision authority

| You decide | Owner keeps |
|---|---|
| Technical choices the spec leaves open; the order of remaining spec work; whether a spec-explicit requirement is a bug rather than a question; a chooser whose highlighted option is technical and right | Spending money; prod deploys, rollouts and infra; product scope beyond the spec; new third-party dependencies; purging or repairing data; permission, trust and approval prompts |

- Every decision you make must be reversible. Tell the session to record it in its plan as a supervisor decision the
  owner may overrule, and list it in the closing report.
- Never order a deploy or a merge to a shared branch that the session was not already authorised to do.
- An owner-kept item parks only that item: send the session the independent work around it.

## Sending

- Prefer native session/thread steering for any harness, including another session of your own. Pin the endpoint,
  preserve owner drafts and verify acknowledgement per `references/sessions.md`.
- For a verified Claude/Cursor/Codex UI protocol, reuse `../pair/scripts/peer-chat.py --supervisor --to <profile>
  --session <full-id> --pane <left|right> --target-command <command> --stdin`. Supply the direction on stdin, or use
  its private prepared-message file flow when required by the caller. This mode requires explicit endpoint selectors,
  adds a supervisor tag and preserves the same composer/draft guards; it also supports a standalone left pane.
- To a Claude pane: `scripts/send.sh <full-id> <transcript> "<message>"`. It checks that Claude is the pane's
  foreground and its composer box is the live bottom one, refuses on an owner draft, a chooser or a dialog, prefixes
  `[Supervisor HH:MM:SS]`, re-reads the composer before a separate CR (a trailing `\n` is Ctrl-J and never submits),
  then looks for the tag in the transcript bytes written after the send.

  | Exit | Meaning | Do |
  |---|---|---|
  | 0 | Delivered | Nothing |
  | 3 | Refused, nothing typed | Read the pane; the owner or a dialog holds it |
  | 4 | Submitted, not yet in the transcript | Check next tick; never resend |
  | 5 | Typed, outcome unclear | Read the pane now; never resend |
- Screen text cannot tell a draft from Claude's grey suggestion placeholder (`❯ ok deploy` may be either). Only the
  caret decides: `agtermctl surface cursor --target surface:<full-id>:left` prints `2` for an empty composer, more
  for a draft. Never report a composer's text as the owner's draft without that check.
- A real owner draft is the owner's. Never submit, clear or append to it; report it.
- Message shape: one paragraph — the decision and its reason, numbered next steps, guardrails (what not to touch, what
  stays with the owner). Make it self-contained; the session may have compacted.
- An unselected peer gets no text or keystrokes from you, regardless of harness. Report a half message or stuck
  composer to its selected owner; do not clear or submit it.
- Use `peer-chat.py` for supervision only with `--supervisor`; ordinary peer mode would mislabel the sender.

## Report

Per poll:

```markdown
Poll at HH:MM:
- **`<id>` <label>:** <state>. <what you did, or "no action">.
Waiting on you: <owner-kept items, one line each, only when the list changed>
```

## Stop

1. Stop when the goal is met (for a budget goal: the tracked window reset, visible as the `7d:` or `5h:` counter
   dropping), when every session is finished or parked on owner items, or when the user says so. Ask the owner before
   extending supervision into a new budget window.
2. Use `CronDelete` only for a job this supervisor scheduled; `kill "$(cat "$S/waker.pid")"` if its waker is still armed. Leave an authorized `caffeinate` running so live turns finish and
   state when it ends.
3. Closing report: each session's final state; decisions waiting on the owner; decisions you made on the owner's
   behalf; any failure that repeated across sessions (offer a fix or a backlog entry in one line).
4. `agtermctl session context --clear --target "$AGTERM_SESSION_ID"`.
