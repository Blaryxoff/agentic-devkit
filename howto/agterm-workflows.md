# agterm workflow audit — 13 November 2026

The Mac had agterm 0.39.1 and standalone agterm skills from 30 October. Homebrew's current release is 0.42.1.
The app bundle and Claude, Codex and Cursor skill copies were updated to 0.42.1; activating the new server requires
an app restart. The inspected app was using Fresh shells, with no live backing on the inspected panes, so the
update deliberately preserved the running app. A restart must be coordinated with the running tasks.

## What should be explicit in skills

| Workflow problem | Useful existing/new capability | Where it belongs |
|---|---|---|
| A preview hides the conversation, or an occupied sibling forces a browser fallback | Existing pane-scoped overlays; 0.42 HTML/URL page rows when no spare pane is available | Demo: preserve occupied panes, open a named preview session, verify loaded state |
| Each plan or screenshot needs custom presentation code | 0.40 native Markdown and image pages; 0.42 linked Markdown navigation | Shared agterm conduct, reached from coder/demo; use native format viewers |
| A finding lacks source context, or logs need repeated terminal tails | 0.41 source-at-line, searchable following log pages; 0.41.1 diff change navigation; 0.42 wrapping | Verify: show requested evidence beside chat; retain command exit results |
| Peer messages merge with a draft or break after a composer update | 0.40 pane mailboxes; upstream mailbox receiver recipe | Pair: prefer a verified receiver after native steering; retain guarded UI delivery for unconfigured peers |
| A background agent inherits another pane's identity | Existing stable pane IDs; recipe requires Codex `--no-daemon` | Pair setup and shared conduct: verify live endpoints, receiver and first prompt |
| Too many sessions make progress hard to follow | Existing context/status/flagged views; 0.40 sidebar `session info` | Coder: short task/phase labels through shared conduct; keep detailed updates in chat |
| Supervision repeatedly polls unchanged text or mistakes a stale status for completion | Existing events/status waits, improved follower CPU in 0.42 | Babysit: bounded events plus periodic evidence checks; observe the current run become active |
| Owner choices stall independent work | Existing nonblocking ask/pick; 0.42 session-bound pickers/timeouts | Babysit/shared conduct: harness question first, explicit result IDs, cancellation is not approval |
| Related helper programs clutter unrelated sessions | Existing companions and creation-bound `--command`; 0.42 page rows and Convert to Companion | Shared conduct: bind helpers at creation; preserve pair's no-launch gate |
| Work must continue when the Mac sleeps | Existing local Live mode covers app restarts; experimental 0.42 Linux `agterm-server` covers Mac disconnection | Separate infrastructure decision, not an automatic terminal/skill update |

## Apply now versus configure separately

Use format-native previews, explicit ownership/version checks and bounded observation immediately when the serving
app supports them. Keep CLI syntax in the official agterm skill and task-specific choices in
[shared conduct](../plugins/core/conduct/agterm.md); avoid copying the upstream command catalog into every skill.

Configure mailbox chat separately before replacing existing terminal delivery. Its 0.42.1 recipe supports Claude
and Codex in a local split, needs receiver hooks, and rejects Codex's shared daemon. Cursor continues through native
steering or the existing guarded sender. Sending to a mailbox alone does not start a recipient turn. Do not install
a second overlapping pair skill just to obtain its transport.

Coordinate enabling Live sessions with a clean restart; it cannot preserve already-running unbacked processes.
Assess Linux server support against the actual target account/container and systemd user-manager availability.
Do not deploy it to hosts or service containers implicitly. Leave Herd/DBngin and project runtime ownership intact.

## Capabilities to leave on demand

Keep dashboard, sidebar density/tints, theme/font controls, remote attach, clipboard routing and terminfo repair in
the official agterm skill. They solve explicit layout, remote or terminal problems, but do not justify steps in every
coding task. Dashboard can redraw worker TUIs because it resizes their PTYs. HUDs share an overlay slot; use the
sidebar info line for routine phase updates and a HUD for a deliberate passive panel. Keep rich review annotations
in the chosen review workflow rather than treating native diff pages as an annotation replacement.

Do not enable every cookbook recipe. The relevant optional recipes are `two-agent-mailbox-chat` for peer transport,
`multi-agent-git-info` for a shared sidebar line, `subagent-status` when subagent activity is otherwise invisible,
and container overlay/status recipes only when that exact boundary is requested. Review each recipe's hooks and
dependencies before installation; a skill refresh does not enable them.

## Sources and verification limits

The installed official skills were byte-compared with the app bundle and the six files at tag `v0.42.1`.
Workflow changes use documented capabilities, with serving-version gates. New server features were not exercised
against the still-running 0.39.1 app. No peer messages or receiver hooks were installed by this audit.

- [0.40.0 release: mailboxes, sidebar info, native image/Markdown pages](https://github.com/umputun/agterm/releases/tag/v0.40.0)
- [0.41.0 release: text/log pages and mailbox recipe](https://github.com/umputun/agterm/releases/tag/v0.41.0)
- [0.41.1 release: diff navigation](https://github.com/umputun/agterm/releases/tag/v0.41.1)
- [0.42.0 release: Linux server, page rows, Markdown links, timeout controls](https://github.com/umputun/agterm/releases/tag/v0.42.0)
- [0.42.1 release: remote log controls and mailbox shared-daemon check](https://github.com/umputun/agterm/releases/tag/v0.42.1)
- [Pinned official agterm skill/reference](https://github.com/umputun/agterm/tree/v0.42.1/plugins/agterm/skills/agterm)
- [Pinned mailbox setup and limitations](https://github.com/umputun/agterm/tree/v0.42.1/cookbook/two-agent-mailbox-chat)

## Second pass — 14 November 2026

Reviewed cc-thingz at `68d29a4b`, the relevant agterm cookbook recipes at `v0.42.1`, and revdiff, revmux, ralphex,
fya, sys-agent and dkll. The scoped cookbook index/READMEs matched master at the time of this check. The user
explicitly deferred restarting agterm; the findings below do not require changing that choice.

| Additional know-how | Decision and placement |
|---|---|
| Updates can be hidden by project/user overrides or generated agent snapshots | Added effective-copy verification to skill-creator. Verify loaded paths and generated bodies; preserve intentional customizations. cc-thingz's planning override chain demonstrates why replacing a bundle is insufficient. |
| Host-only review dialogs can strand a remote web/mobile user | Added a client-visibility check to agterm preview conduct. Use an accessible artifact/question instead of waiting on an unseen overlay. Keep the local separate-panel default. |
| Reports/logs can take questions and annotations without a source-code diff | Route explicit requests to the existing revdiff skill: standalone files, scratch text and `??` questions. Avoid a second annotation skill with overlapping triggers. |
| Rendered document annotations can return original source-line ranges | The optional annotate-document recipe offers this and recoverable output files. Adapt its placement and Claude-specific skill metadata first; persist results before app exit. |
| Conversation restore is different from live process restore | Added a pane/thread identity check. The Claude/Codex resume recipes use a tab UUID; do not install them unchanged for two same-harness agents sharing a split. |
| Multiple agents overwrite one sidebar activity line | Added one-publisher ownership. The combined Git-info recipe merges pane state; ordinary phase updates must not race it. |
| Container HTML/commands/URLs name different files, runtimes and ports | Added a boundary check and narrower status-bridge preference. A reachable control socket does not make a container path visible on the Mac. |
| Scheduled preparation can be separate from supervision | Optional scheduled-jobs can prepare recaps/changelogs in background sessions. It installs a persistent cronn LaunchAgent; sleep skips runs, and agterm must already run. Do not enable it implicitly. |
| Project navigation should distinguish a fresh task from returning to one | project-launcher opens new work; project-session-picker reuses a matching session. Neither replaces devkit-projects runtime ownership or pinned peer identity. Keep both optional. |
| Review quality can be improved from actual run archives | Existing revmux self/stats already covers evidence-based profile tuning. Use it on explicit request; adding another checklist would duplicate installed behavior. |
| A long ralphex run can be corrected at a task boundary | Its Ctrl+\\ pauses the task and resumes it with a fresh session after plan edits; during external review the same key ends that loop. This is ralphex-specific, not a devkit-task keybinding. |

Keep fya as an optional compatibility investigation: its PTY print adapter is not a multi-turn peer protocol, and
resumed/concurrent calls can select the wrong transcript. Do not replace `claude` on PATH. sys-agent is a possible
monitoring component when HTTP success does not establish application health; inspect body fields as well as status
codes. dkll introduces log collectors and a central server/MongoDB stack, so it is a separate infrastructure choice.

No additional plugins, receiver hooks, daemons or services were installed. Existing devkit review, planning and
analysis workflows already cover much of cc-thingz; its automatic commits, finalize actions and broad autonomous
decision policy were not imported. The useful transfers are effective-source checks, visible interaction, durable
feedback and precise identity boundaries.

### Second-pass sources

- [cc-thingz: planning overrides and remote-client review behavior](https://github.com/umputun/cc-thingz/blob/68d29a4b7734a004a067c3c5869884d2269b0a17/README.md#planning)
- [Rendered document annotations](https://github.com/umputun/agterm/tree/v0.42.1/cookbook/annotate-document)
- [Claude conversation resume](https://github.com/umputun/agterm/tree/v0.42.1/cookbook/claude-session-resume), [Codex conversation resume](https://github.com/umputun/agterm/tree/v0.42.1/cookbook/codex-session-resume)
- [Combined Git-info publisher](https://github.com/umputun/agterm/tree/v0.42.1/cookbook/multi-agent-git-info)
- [Container overlays](https://github.com/umputun/agterm/tree/v0.42.1/cookbook/container-overlays), [status-only bridge](https://github.com/umputun/agterm/tree/v0.42.1/cookbook/container-agent-status)
- [Scheduled jobs](https://github.com/umputun/agterm/tree/v0.42.1/cookbook/scheduled-jobs)
- [New project launcher](https://github.com/umputun/agterm/tree/v0.42.1/cookbook/project-launcher), [existing session picker](https://github.com/umputun/agterm/tree/v0.42.1/cookbook/project-session-picker)
- [revdiff file/text review and questions](https://github.com/umputun/revdiff/blob/97a5fa7aac255b0a6cfe272cc2a0d588f901f6ee/README.md#features)
- [revmux audit archives](https://github.com/umputun/revmux/blob/83ddcfe24739c0a986bd86c19d83d50be352b7bf/README.md#task-rounds)
- [ralphex task steering](https://github.com/umputun/ralphex/blob/51f4921e9233527b50caef47292a358b4be082b1/README.md#phase-1-task-execution)
- [fya transcript limits](https://github.com/umputun/fya/blob/6dbc9d3ea2270a7cfa6003cbed06430825678535/README.md#known-limitations)
- [sys-agent checks](https://github.com/umputun/sys-agent/blob/8b91897e605102657d2c58e1fd1528eba63a5f37/README.md#configuration-file), [dkll architecture](https://github.com/umputun/dkll/blob/de162bb69e2d888c4f071ce8f090e9834c945b50/README.md)
