# Supervise a selected agent session

Use the same endpoint and ownership rules for Claude, Cursor, Grok, Gemini, Codex and other agents, including a second
session of the caller's harness. Keep the selected task owner as the sole production operator.

## Identify and observe

1. Read `agtermctl tree --json`; record the full session UUID, pane ID, foreground executable, project and task label.
2. Match recent visible output to the user-selected task. Several unrelated sessions may share a checkout or title.
3. Keep only selected session/pane pairs in the supervision roster. The roster helper inventories non-shell foreground
   processes; it does not decide which are agents or grant authority over them. Inspect unknown commands before selection.
4. Observe `agtermctl session text --target <uuid> --pane-id <token> --lines 60`. Use a harness-specific transcript or
   native thread API only when the pane tail is insufficient; read bounded recent user/assistant records and timestamps.
5. Recheck the selected foreground before each direction. A changed process or task invalidates the endpoint until
   it is matched again; do not redirect a message to a different pane merely because its agent name matches.

## Deliver one guarded direction

1. Prefer an available native thread-steering API. Resolve the exact selected thread from recent matching messages,
   send one short paragraph tagged `[Supervisor HH:MM:SSZ]`, and require a queued-message receipt or acknowledged response.
2. For a known UI protocol, use `../pair/scripts/peer-chat.py --supervisor --to <claude|cursor|codex> --session <uuid>
   --pane <left|right> --target-command <command> --stdin`, or its prepared-message file flow. It pins the target,
   preserves drafts, adds the supervisor tag, verifies each body write and submits separately. Match the protocol
   against the live UI, independently of the executable's brand/model. `scripts/send.sh` remains a compatible helper
   for its Claude left-pane format only; do not route another harness through that parser.
3. For another terminal UI, inspect its live foreground, overlays/dialogs, bottom composer and caret together. Verify
   the composer contains only the observed empty placeholder and no draft, chooser, trust or approval prompt. An empty
   caret position alone is insufficient. Use a verified native transport or a tested supervisor delivery adapter.
4. Keep an unknown terminal UI observation-only when no transport can preserve drafts and confirm delivery. Report the
   missing capability for that endpoint, continue other selected endpoints, and request the owner's direction only when
   that blocked delivery is necessary. Never reuse Claude's prompt parser or keyboard shortcuts for an unknown UI.
5. Distinguish refused, typed, submitted and acknowledged messages. If delivery is unclear, inspect on the next poll;
   never resend, send Return again or clear input blindly. Never claim a report from the peer as verification of its work.

## Poll and stop

- Track each task's stage, blocker, next action, authoritative data and current write owner when relevant.
- Prioritize the agreed restoration path and pause budget during a production write pause.
- Leave progressing operators alone; send another direction only for a new risk, missed decision or missed milestone.
- Use the available wait/scheduler mechanism without claiming persistence it cannot provide. Without a recurring
  scheduler, poll in the active turn until the agreed stop condition or an explicit handoff.
- Keep automatic usage-limit waking restricted to the tested Claude adapter and an explicitly selected Claude roster.
  For another harness, observe its actual limit/reset signal and use its verified delivery transport after reset.
