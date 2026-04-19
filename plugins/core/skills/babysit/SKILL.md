---
name: devkit-babysit
description: keep a PR merge-ready by triaging comments, resolving clear conflicts, and fixing CI in a loop
---

# Babysit PR

Your job is to get this PR to a merge-ready state.

Check PR status, comments, and latest CI and resolve any issues until the PR is ready to merge.

1. **Comments**: review every comment (including automated reviewers) before acting. Fix only comments you agree with; explain when you disagree or are unsure.
2. **Merge conflicts**: when there are conflicts, sync with the base branch. Resolve merge conflicts only when intent is clearly the same; otherwise stop and ask for clarification.
3. **CI**: fix CI issues that come up with small, scoped fixes. Push them and re-watch CI until the PR is mergeable, green, and all comments are triaged.

## Shared protocols

- Report comment triage and CI failures using `plugins/core/conduct/review-findings-format.md` (severity buckets).
- When a comment, conflict, or failure is ambiguous, stop and ask via `plugins/core/conduct/clarification-protocol.md`.
