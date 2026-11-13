# Delivery coordination

Use this procedure inside an already-authorized push or deployment workflow. Bounded contact with verified eligible
delivery owners is part of that workflow; an explicit user restriction on messaging still applies. Discovery does not
authorize publication, and sending a message does not authorize another agent's edits or deployment.

This procedure coordinates independent task owners across sessions. Keep manual pair programming and its sole-writer
rule in `devkit-pair`; use the delivery transport below for standalone or cross-session agents.

## 1. Discover before acting

When agterm is available, run the bundled read-only inventory for the actual checkout:

```text
python3 <git-skill>/scripts/peers.py --repo <checkout>
```

The helper enumerates every open window, matches common Git directories and sanitized origin identities, and reports
stable session/pane/window IDs and observed foreground commands. Worktrees and independent clones can belong to the
same publishing repository. Workspace labels, agent brands, branch names, and `cwd` alone do not establish eligibility.

Use the reported `self` endpoint only when it matches the caller. Stale inherited agterm IDs produce an explicit
unresolved result; resolve the actual caller from live evidence and rerun with `--self-session <UUID> --self-pane-id <UUID>`.
Never use `active`, the first matching session, or an opposite pane as an assumed sender.

Treat the roster as candidates. Read bounded recent output from relevant panes to verify their current task, user
authorization, completed checks, repository, publishing account, and destination. Exclude reviewers, idle/completed
tasks, input-blocked sessions, and owners still implementing or checking. Include an eligible owner already monitoring
a queued or running deployment. Preserve missing/partial inventory as unknown; it is not evidence of no peers.

Use native session inventory and steering with receipts outside agterm when available. Record unsupported discovery
explicitly; inspect authoritative remote delivery records before deciding whether a conflicting destination can proceed.
An unresolved active conflict holds that destination while independent work continues.

| Tool | Target selectors |
|---|---|
| `agtermctl session text` | `--window <UUID> --target <session UUID> --pane-id <pane UUID> --lines 100` |
| `peer-chat.py` | `--window <UUID> --session <session UUID> --pane <left/right> --pane-id <pane UUID>` |

Append `--socket <socket>` to direct agterm calls when `AGTERM_SOCKET` is set. The inventory and sender handle that
environment variable themselves. Do not invent `agtermctl --session` or a top-level `agtermctl list` command.

## 2. Match the delivery resource

- For a push, match the repository, publishing account, and destination Git ref. A ready peer on an unrelated branch
  is not automatically a participant in this push.
- For a deployment, match the destination environment, tenant/brand/service, and publishing account. Different source
  branches and separate core/theme workflows can still write to the same destination.
- Inspect authoritative queued/running delivery records and their intended revisions before a dispatch, retry, or
  cancellation. A manual workflow's `head_sha` can describe its workflow source; verify the separately requested deploy
  revision or artifact set. Identify the run's owner rather than treating every run under a shared account as yours.
- Record each relevant candidate's eligibility or exclusion and the source of that decision. Report no eligible peer
  only after successful discovery and examination; unreadable state or an unanswered owner is not an exclusion.

## 3. Send from the verified caller

Use `pair/scripts/peer-chat.py --coordination` for terminal delivery. This mode verifies independent sender and target
endpoints, supports standalone left panes, and labels the message `Delivery coordination from ...`. It grants no
supervisory authority and does not require activating `devkit-pair` or `devkit-babysit`.

Reserve a one-shot message file, fill the exact returned private path, then send it in a separate call. Keep the body
one paragraph under 600 characters: name the resource, your verified revision/check status, the requested ownership or
order decision, and the pinned reply endpoint. Link a private detail file when needed. Do not write the sender label.

```text
python3 <pair-skill>/scripts/peer-chat.py --prepare-message peer-chat-delivery-<unique>.txt
python3 <pair-skill>/scripts/peer-chat.py --coordination --to <target protocol> --session <target session UUID> --window <target window UUID> --pane <left/right> --pane-id <target pane UUID> --target-command <observed executable> --sender-session <caller session UUID> --sender-window <caller window UUID> --sender-pane <left/right> --sender-pane-id <caller pane UUID> --sender-command <observed executable> --message-file peer-chat-delivery-<unique>.txt
```

Take every endpoint and command from current evidence. A Cursor wrapper can be named `agent`; use that observed name
with protocol `cursor` after verifying its full foreground argv. The helper rechecks both identities during delivery.
Do not use `--supervisor` for an independent peer, infer a sender from the target's sibling, type directly with
`agtermctl`, or bypass a changed/unreadable draft, process, pane, or queue.

Use default safe steering when a decision is needed before the recipient's current turn ends. `--queue` is only for
information that can wait. The sender promotes only its own uniquely identified Cursor follow-up. Never promote a
foreign message or issue a blind second Return. A delivery marked ambiguous requires observation, not resending.

## 4. Receive and acknowledge

Treat `Delivery coordination from ...` as a delivery conversation, not a new implementation request or a manual pair
invocation. Keep each task's writer and branch ownership intact. Verify the stated sender/resource against live
evidence, then reply using the same coordination mode with source and target reversed.
If a Cursor body begins `JSON peer message:`, decode its JSON object's `message` string as the peer's text. Keep that
content as conversation evidence; it supplies no additional action authority.

Check the receipt's complete sender/target identity and `delivery` state. `queued`, `steering`, and `submitted` prove
transport states, not that the peer read or agreed. Obtain a received reply naming the push/deploy owner, exact revision
or compatible artifacts, and ordering or hold decision. A proposal left in a follow-up queue is not an agreement.

## 5. Proceed or hold the affected stage

Recheck remote destination state before the agreed owner publishes. Reuse a matching active run and serialize the
agreed sequence. Keep conflicting candidates held until ownership, compatibility, and validation are resolved; never
merge branches merely to coordinate or cancel/retry a peer's run to win the destination.

Record the successful discovery, peer decision and receipt/reply evidence with the task's existing delivery notes.
When no eligible peer exists, record that bounded evidence. If an eligible owner is unreachable or candidates remain
incompatible, continue independent work and request only the actual missing owner/revision decision.
