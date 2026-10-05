# Agent feedback queue

The Jev prompt hook writes untriaged agent-workflow feedback candidates here. These records are leads to investigate,
not accepted deferred work. Each points to a private JSON ticket with the redacted prompt and session context. By
default, tickets live under `~/.local/state/devkit/feedback/tickets/`; `XDG_STATE_HOME` changes that path.
For an eligible prompt, `wtf` triggers the reusable-workflow check even when the initial Jev feedback score is low;
it does not guarantee a queue entry.

Use `devkit-feedback` to triage the queue, or list candidates with
`rg --files docs/feedback-queue -g 'agent-feedback-*.md'`. For each one, read its `Private evidence`
JSON and verify the session context. Then fix the skill or workflow, drop the candidate, or move an accepted deferred
finding to `docs/backlog/` through the backlog workflow. Set the private ticket's `status` to `fixed`, `dropped`, or
`deferred` **before** removing the queue entry. The hook recreates a missing entry only while its ticket is `untriaged`.

The hook never commits queue entries automatically. Entries and their private evidence are local to the clone that
created them; a Git pull does not collect candidates from other machines.
