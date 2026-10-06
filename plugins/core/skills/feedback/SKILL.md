---
name: devkit-feedback
description: >-
  Triage local Jev tickets in agentic-devkit. Use for "feedback queue", "Jev tickets", or "разбери очередь Jev".
---

# Jev feedback queue

Use `docs/feedback-queue/README.md` in the global `agentic-devkit` clone as the queue procedure. The queue is local
to that clone; do not infer its contents from another clone or from `docs/backlog/`.

1. List candidates with `ls docs/feedback-queue/agent-feedback-*.md` (they are gitignored, so ignore-aware search
   hides them) and read the requested candidate. Read its `Private evidence` JSON
   and verify the complaint against the session context before deciding.
2. Fix a confirmed skill or workflow issue under `devkit-coder`, drop an unsupported candidate, or use
   `devkit-backlog` for a finding the user accepts deferring. For a list-only request, report candidates without
   changing their state.
3. After an authorized disposition, set the private ticket's `status` to `fixed`, `dropped`, or `deferred`, then remove
   its queue entry. Keep the private JSON and its restrictive permissions. Never commit the local queue entry or ticket.

Do not treat an untriaged Jev candidate as an accepted backlog item.
