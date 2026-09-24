---
name: devkit-babysit
description: >-
  supervise several running agterm split sessions (Claude Code with a Codex peer, each working its
  own spec) on a timed poll: spot stalls, decide technical questions, break peer deadlocks, park owner
  decisions, report every round. Manual trigger ONLY: "babysit these sessions", "supervise the
  sessions", "присмотри за сессиями", "poll them every 30 min". Not devkit-pair (talk inside one
  split) nor devkit-task (drive one spec).
---

# Babysit

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this
> skill's symlink target), not the project root. `scripts/` and `references/` are relative to this skill's directory.

You are the supervisor of sessions that already work on their own. Your output is decisions and unblocking; never
write code in a supervised checkout.

## Gate

1. The user asked this turn for sessions to be supervised, or the prompt is a tick this skill scheduled
   (`/babysit poll <state-dir>`). A tick skips Setup and runs Poll.
2. Top-level Claude Code session inside agterm (`AGTERM_ENABLED=1`, `agtermctl` on PATH). Codex has no recurring
   scheduler: there, run one Poll and say the loop is unavailable.
3. Each supervised session runs Claude Code in its left pane. A Codex peer, when present, sits in the right pane (the
   `devkit-pair` layout) or runs as a background `codex exec` (see it with `ps -axo pid,etime,command | grep
   '[c]odex exec'`). Another layout: say so and stop.

## Setup

1. `S=<scratchpad>/babysit`; `mkdir -p "$S"`.
2. Roster: `scripts/roster.py > "$S/sessions.txt"`, one line per Claude session: `<full-id> <label> <transcript|->`. Keep only the
   sessions the user meant; when more splits run than the user named, ask. Resolve every `-` by content: the newest
   transcript in that project's dir whose tail matches the left pane. Never your own transcript; it shares the dir.
3. Pin the goal and the stop condition from the request ("use the budget before the weekly reset", "until the specs
   are done"). Ask only when neither is stated.
4. macOS: `nohup caffeinate -ims -t <seconds in the window> >/dev/null 2>&1 & disown`. A sleeping Mac freezes every
   session. Tell the user a closed lid still sleeps.
5. Waker, only when a usage-limit reset falls inside the window: `scripts/waker.sh --dry-run <HH:MM> <own-id> "$S/sessions.txt"`
   must print no `WOULD WAKE` for a working pane (your own pane matches while a poll report quotes a limit message);
   then arm it with `nohup … & disown` without `--dry-run`. It wakes each limited Claude pane once — `continue`, or a
   resume prompt for your own — over four passes, logs every `send.sh` exit to `$S/waker.log`, then exits.
6. Run Poll once now.
7. `CronCreate`, recurring, the user's interval (default 30 min) on minutes off :00/:30, prompt
   `/babysit poll <absolute $S>`. Tell the user the loop lives only while this session is open and expires in 7 days.
8. `agtermctl session context 'supervising N sessions: <goal>' --target "$AGTERM_SESSION_ID"`.

## Poll

1. `scripts/poll.sh "$S/sessions.txt"` (`LN=`/`RN=` widen the pane tails). The status line in each tail shows usage
   windows (`5h:`, `7d:`); watch them against the goal.
2. Classify each session: working · waiting on its peer (is the peer working?) · waiting on a background job ·
   blocked on a question or chooser · finished · limited · dead turn.
3. For anything not plainly working, read `scripts/tail.py <transcript> 3 3000` (timestamps are UTC) and the peer
   pane. Match `references/stalls.md` and act. Leave working sessions alone.
4. Report one bullet per session (see Report), then stop until the next tick.

## Decision authority

| You decide | Owner keeps |
|---|---|
| Technical choices the spec leaves open; the order of remaining spec work; whether a spec-explicit requirement is a bug rather than a question; a chooser whose highlighted option is technical and right | Spending money; prod deploys, rollouts and infra; product scope beyond the spec; new third-party dependencies; purging or repairing data; permission, trust and approval prompts |

- Every decision you make must be reversible. Tell the session to record it in its plan as a supervisor decision the
  owner may overrule, and list it in the closing report.
- Never order a deploy or a merge to a shared branch that the session was not already authorised to do.
- An owner-kept item parks only that item: send the session the independent work around it.

## Sending

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
- The Codex pane gets no text from you. The only allowed keystroke there is the single `Ctrl-C` in
  `references/stalls.md` for a stuck half message.
- `peer-chat.py` is not a supervisor channel: it labels every message as coming from the peer.

## Report

Per poll:

```markdown
Poll at HH:MM:
- **`<id>` <label>:** <state>. <what you did, or "no action">.
Waiting on you: <owner-kept items, one line each, only when the list changed>
```

## Stop

1. Stop when the goal is met (for a budget goal: the tracked window reset, visible as the `7d:` or `5h:` counter
   dropping), when every session is finished or parked on owner items, or when the user says so. Do not burn a new
   budget window without asking.
2. `CronDelete` the job; `kill "$(cat "$S/waker.pid")"` if the waker is still armed. Leave `caffeinate` running so live turns finish and
   state when it ends.
3. Closing report: each session's final state; decisions waiting on the owner; decisions you made on the owner's
   behalf; any failure that repeated across sessions (offer a fix or a backlog entry in one line).
4. `agtermctl session context --clear --target "$AGTERM_SESSION_ID"`.
