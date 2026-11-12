# Agent feedback queue

The Jev prompt hook writes untriaged agent-workflow feedback candidates here. It skips `Chat from <sender>:` relays,
timestamped `[Supervisor HH:MM:SSZ]` messages, task notifications,
and one-off or unknown-cause `other` classifications; question replies are screened using only the user's answer.
These records are leads to investigate, not accepted deferred work. Each points to a private JSON ticket with the
redacted prompt and session context. By default, tickets live under `~/.local/state/devkit/feedback/tickets/`;
`XDG_STATE_HOME` changes that path.
For an eligible prompt, `wtf` triggers the reusable-workflow check even when the initial Jev feedback score is low;
it does not guarantee a queue entry.

Use `devkit-feedback` to triage the queue, or list candidates with
`rg --files --no-ignore docs/feedback-queue -g 'agent-feedback-*.md'`. For each one, read its `Private evidence`
JSON and verify the session context. Then fix the skill or workflow, drop the candidate, or move an accepted deferred
finding to `docs/backlog/` through the backlog workflow. Set the private ticket's `status` to `fixed`, `dropped`, or
`deferred` **before** removing the queue entry. The hook recreates a missing entry only while its ticket is `untriaged`.

The hook never commits queue entries automatically. Entries and their private evidence are local to the clone that
created them; a Git pull does not collect candidates from other machines.

## Complete a triage round

- Snapshot the candidate IDs. Group repeated causes and separate reusable feedback from one-off requests in mixed prompts.
- Check the resource the complaint actually concerns, including installed harness rules and project instructions. Use
  existing fixes and focused reproduction evidence; a missing transcript blocks a decision only when that context is essential.
- Record each candidate's disposition, reason and evidence. For a project-specific request, record its owning repository
  and next action before dropping it from this workflow queue; that does not claim the project work is complete.
- Continue uncertain investigations during the round. Leave an entry open only with a concrete missing prerequisite and
  next action, or defer accepted work through the backlog workflow. Report those blockers and separately count new arrivals.
