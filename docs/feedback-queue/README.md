# Agent feedback queue

The Jev prompt hook writes untriaged agent-workflow feedback candidates here. These records are leads to investigate,
not accepted deferred work. Each points to a private JSON ticket under `~/.local/state/devkit/feedback/tickets/` with
the redacted prompt and session context.

After checking the evidence, fix the relevant skill or workflow, discard the candidate, or move an accepted deferred
finding to `docs/backlog/` through the backlog workflow. The hook never commits queue entries automatically.
