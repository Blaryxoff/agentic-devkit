# agterm in development workflows

Load the installed `agterm` skill for exact commands and return shapes. Keep upstream CLI documentation there;
use this document to choose a capability for the task. Outside agterm, use the harness's normal tools.

## Resolve capabilities and ownership

- Read `agtermctl version --json` against `--socket "$AGTERM_SOCKET"` when set. Gate commands on the serving
  `result.app`, not `result.installed` or the client binary: an upgrade can leave the old app serving the socket.
- Resolve the conversation's live window, session and `surfaces[].paneID` from `window list` and `tree`. Inherited
  IDs can be stale after restoration; `active` names the user's selected session, not necessarily this agent's.
  Match the task, foreground command and pane identity; ask when the owner remains ambiguous.
- Pass the resolved socket, window and session explicitly. Use stable pane IDs where the command supports them;
  re-resolve a positional `--pane left|right` immediately before use. A pane swap can change a role's occupant.
- Inspect `restore mode` and each pane's `backedByZmx` before proposing a restart. Installing a bundle does not
  activate its new server commands. A Fresh shells restart ends current processes; changing restore mode cannot
  wrap an existing process in live backing. Obtain approval before interrupting running work.

## Show an artifact beside the conversation

1. Inspect the owner's sibling pane, foreground process, scratch and overlay slots. Preserve existing work and
   hidden overlays; an occupied slot remains occupied when hidden. Create a vertical split only when needed.
2. Show the artifact in that safe sibling with `--pane`, leaving the conversation visible. Use the format below
   rather than building HTML solely to display an existing document.
3. When no safe sibling is available, use a dedicated named preview session/tab or window according to the user's
   layout preference. On 0.42+, HTML/URL `--page` creates a persistent page row without a shell; `--companion`
   keeps it under its task. These are sidebar rows, not simultaneous split panels. Do not cover the conversation
   with a session-wide overlay to obtain a preview.
4. Read `tree` back for the expected file/URL, owner and pane, and `htmlOverlays[].state: loaded` where reported.
   Check the rendered content with the available inspection tool; a successful open does not establish layout,
   image loading or interaction. Leave the final preview open; close only task-owned superseded previews.

For a user connected through a remote web/mobile client, establish whether they can see and control the host's
preview. Use a client-visible artifact or question when they cannot; do not block on a host-only overlay. Keep the
normal separate-panel policy when the user is viewing agterm directly.

| Artifact | Capability | Minimum serving app |
|---|---|---|
| HTML report, gallery or interactive explainer | `session overlay open --html FILE`; add `--js` for required interaction | Check installed skill/help |
| Development site or authenticated preview | `--url URL --js`; `--persistent` when saved login is wanted | Check installed skill/help |
| Screenshot or image | `--image FILE` | 0.40 |
| Plan, specification or handoff | `--markdown FILE`; `--navigation` for local document links on 0.42+ | 0.40 |
| Source/config at a finding | `--text FILE --line N` | 0.41 |
| Growing verification/server log | `--text FILE --tail N --follow-file` | 0.41 |
| Saved `.diff` or `.patch` | `--text FILE`; change navigation on 0.41.1+, wrapping on 0.42+ | 0.41 |

Use native text search and follow controls for logs. Scrolling up pauses following. Text pages are read-only
evidence viewers; keep file editing and review annotations in the selected editor/review workflow. Preserve the
project's canonical server and authorized login path for URL previews; a preview does not replace runtime QA.
Use the upstream image helper only when native image pages are unsupported. Use agterm theme variables in custom
HTML without redefining `--agterm-*`.

Route explicit annotation or explanation requests to the existing `revdiff` skill (or the requested review tool).
It handles standalone files and arbitrary text as well as diffs; `??` notes request explanations. Native pages
do not collect those notes. For an explicitly chosen rendered-document annotation recipe, adapt its placement
to the preview policy and persist submitted notes to a file before closing; app-held results are temporary.
See the [upstream audit](../../../howto/agterm-workflows.md#second-pass--14-november-2026) for sources and optional recipes.

## Select communication and progress tools

- Prefer native thread steering with a pinned endpoint and receipt. For an authorized peer exchange on 0.40+,
  prefer pane mailboxes only when a receiver is configured and verified; `msg send` alone queues text and does
  not wake an agent. Read the installed cookbook's `two-agent-mailbox-chat` recipe before configuring it.
- Pin mailbox addresses as `SESSION:PANE-ID`. Check recipient delivery and receiver availability; queue acceptance
  does not prove processing. Acknowledge handled messages deliberately and preserve delivery evidence outside
  the mailbox: restart or pane closure discards mail. Never broadcast to unselected agents.
- Keep the existing guarded composer transport for supported UIs without a verified mailbox receiver, including
  Cursor unless an adapter has been established. Preserve pair's manual gate and sole-writer rule. Mail delivery
  changes neither scope nor approval authority. Do not consume a mailbox owned by another receiver hook.
- Require the mailbox recipe's Codex launch with `--no-daemon`, a completed first prompt and matching hooks.
  A shared daemon can inherit another pane's identity; missing receiver or stale registration is a setup blocker.
  Installing skills alone does not authorize enabling global receiver hooks or broad sandbox permissions.
- Launch authorized helpers with `session new --command ... --no-select`, optionally `--parent` for a task
  companion, and verify their foreground process. `session type` injects input into a shared composer; use the
  owning workflow's guarded sender for existing agents. Never launch a program by typing a shell line there.
- Use `session context` for the task label and, on 0.40+, `session info` for a short phase or count under its row.
  Keep detailed progress in the conversation. Prefer the existing agent-status hooks for active/blocked/completed;
  a helper must not overwrite another pane's blocked state. Use a HUD only when a passive panel is useful and its
  slot is free; use notifications for an exceptional nudge, not every successful tool call.
  Assign one publisher to a shared info line: a combined Git/status recipe must merge both pane updates rather
  than race independent phase writers. Preserve an existing publisher instead of overwriting its line.

## Observe workers and collect decisions

- Use bounded event subscriptions for status, lifecycle and tree changes to trigger targeted observations of the
  selected roster. Events do not stream terminal output. `statusChangedAt` measures the last status write, not
  useful work; inspect the selected pane/transcript before declaring progress, a stall or completion.
- Use `session wait --until completed --until blocked --timeout N` only with verified status hooks. When reusing
  a session, observe the new run become active first so a previous completed state cannot satisfy the wait.
  Keep waits bounded by the harness's responsiveness rules; supervision ends with the turn unless scheduled.
- Offer `dashboard` when the user wants a visual overview of selected workers. It resizes their PTYs and can
  cause redraws; it is not a silent monitoring API. Do not open it automatically during background supervision.
- Prefer the harness's structured question tool for owner decisions. When unavailable, `ask --no-block` or
  `pick --no-block` permits independent work while the question is pending; pin its owning session/window and read
  the result later. On 0.42+, a session-bound picker and question timeouts can limit stale prompts. Inspect the
  selected answer ID: a successful command can mean No. Cancellation, dismissal and timeout are not approval.

## Keep remote persistence a separate infrastructure choice

Distinguish live process reattachment from restarting a conversation. Before adopting a resume recipe, verify its
key includes the intended pane/thread: a map keyed only by session UUID can collide when two agents share a split.
Keep single-agent tab recipes scoped to that layout until a pane-aware adaptation is verified. Do not replay a
session snapshot by typing saved commands into shell composers; use creation-bound launch and inspect its private
command/transcript content before storing or sharing it.

Consider the experimental 0.42+ `agterm-server` for explicitly requested work that must survive Mac sleep or a
network drop. It needs a compatible Linux host with a systemd user manager and currently supports one Mac per
server. Local Live sessions preserve processes through an app restart; they do not keep the Mac executing during
sleep. Assess the intended account/container and approve that installation separately. Preserve existing host
boundaries and the project's serving/database setup; a terminal update is not an infrastructure migration.

For an explicitly requested container preview, verify command execution, file paths/assets and forwarded URL ports
all resolve on the presenting Mac. A socket connection alone establishes none of these. Prefer a status-only bridge
when status is the missing capability; a broad unauthenticated control receiver needs a separate trust decision.
