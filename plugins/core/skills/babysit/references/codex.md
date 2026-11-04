# Supervise a Codex primary in agterm

Keep the owner's active migration session as the sole production operator. Use this path only when the owner selected
that session for supervision; a Codex peer in another agent's split remains outside the sending scope.

## Identify and observe

1. Read `agtermctl tree --json`; record full session UUID, pane ID, project, foreground executable and task label.
2. Read `agtermctl session text --target <uuid> --pane-id <token> --lines 60`. Match the migration's recent output,
   not just its checkout or title; multiple unrelated sessions can share a project.
3. Record a manual roster under the supervision scratch directory. Claude-only `roster.py`, `tail.py`, `send.sh` and
   `waker.sh` do not implement Codex discovery, parsing or delivery; do not route Codex through those helpers.
4. Match a Codex rollout by recent visible messages only when the pane tail is insufficient. Extract bounded recent
   user/assistant records with timestamps; avoid raw tool dumps and secrets.

## Deliver one guarded direction

1. Prefer a supported native thread-steering tool when available. Otherwise inspect the live Codex foreground,
   overlay/dialog state, bottom composer and `agtermctl surface cursor --pane-id <token> --target <uuid>` together.
2. Preserve owner drafts. A cursor column beyond the prompt proves occupancy; a cursor at the prompt does not prove
   emptiness. Verify the visible bottom composer contains only the observed placeholder/empty prompt, with no draft,
   chooser, approval or trust dialog. Refuse to type when any part is uncertain.
3. Send one short paragraph tagged `[Supervisor HH:MM:SSZ]` using `session type` to the pinned UUID/pane ID, without
   Return. State the decision, next steps and guardrails; honor newer owner instructions over earlier supervisor advice.
4. Re-read until the full paragraph is rendered, allowing a short bounded rendering delay. Verify the composer still
   contains exactly the supervisor text before sending a separate carriage return (`\r`). Never append to changed text.
5. Verify the tagged user message in the rollout, queued-message UI or acknowledged response. If submission is unclear,
   report its state and inspect on the next poll; never resend or issue another Return blindly. If only typed, keep the
   distinction explicit and resolve that composer before leaving supervision.

## Poll and stop

- Track stage, authoritative DB/storage, worker owner, write-pause start/budget, exact blocker and next action.
- Prioritize safe write restoration during a prolonged production pause. Redirect repeated speculative fixes to the
  actual failing command and established recovery path; preserve the latest authoritative writes.
- Leave progressing operators alone. Send another direction only for a new risk, missed decision or missed milestone.
- Use the available wait/scheduler mechanism without claiming persistence it cannot provide. Without a recurring
  scheduler, keep polling in the active turn until the agreed stop condition or an explicit handoff.
