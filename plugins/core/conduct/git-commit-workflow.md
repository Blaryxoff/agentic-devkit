# Git Commit Workflow

Only create commits when the user explicitly asks. If the request is ambiguous, ask first — never commit proactively. The user must request a commit in the current query or in a standing user rule; otherwise do not commit.

## 1. Safety protocol

- Never update the git config.
- Never run destructive or irreversible git commands (`push --force`, `reset --hard`, etc.) unless the user explicitly requests them in the query or a standing user rule.
- Never skip hooks (`--no-verify`, `--no-gpg-sign`, etc.) unless the user explicitly requests it.
- Never force-push to `main`/`master`; warn the user if they request it.
- Use non-interactive git commands with explicit targets; `git rebase -i` and `git add -i` require input this environment cannot provide.
- Never commit files that likely contain secrets (`.env`, `credentials.json`, tokens). Warn the user if they specifically request committing those.

## 2. Amend rules

Avoid `git commit --amend`. Use `--amend` only when ALL of these hold:

1. The user explicitly requested amend, OR the commit SUCCEEDED but a pre-commit hook auto-modified files that must be included.
2. HEAD was created by you in this conversation (verify: `git log -1 --format='%an %ae'`).
3. The commit has NOT been pushed (verify: `git status` shows "Your branch is ahead").

- If a commit FAILED or was REJECTED by a hook, never amend — fix the issue and create a NEW commit.
- If the commit was already pushed, never amend unless the user explicitly requests it (it requires a force push).

## 3. Steps when asked to commit

1. Run in parallel: `git status` (untracked files and the pre-existing index), `git diff` (staged + unstaged changes), `git log` (match this repo's message style).
2. Draft the message from the intended commit scope:
   - Classify the change: `add` = wholly new feature, `update` = enhancement to existing feature, `fix` = bug fix; also `refactor`, `test`, `docs`.
   - Keep it concise (1–2 sentences) and focus on the **why**, not the **what**.
   - Ensure it accurately reflects the changes and their purpose.
3. Run sequentially: stage only the intended paths → commit only those paths → inspect the committed path list → run `git status` to verify success and preserve unrelated staged work.
4. If the commit fails on a pre-commit hook, stop. Fix the issue and create a NEW commit (see §2); never let the next commit carry the rejected commit's staged files.
5. If there is nothing to commit (no untracked files, no modifications), do not create an empty commit.

## 4. Scope discipline

- Run the executable discovery and guarded cross-session transport in the owning Git skill's
  [delivery coordination procedure](../skills/git/references/coordination.md) when its delivery gate applies.
- Treat every path staged before the current task as foreign work unless the user explicitly includes it.
- Pass intended paths to both `git add --` and `git commit --`. A bare `git commit` sweeps the whole index, including unrelated work staged before this task.
- Pass file names as literal pathspecs (`:(literal)path`) when constructing commands. Reject empty path arguments; an empty pathspec can match the whole current directory.
- After any hook runs, inspect `git show --name-status --format= HEAD` and `git status --short`. Hooks can modify or stage files; never discard, unstage, or absorb unexpected paths without inspecting them.
- Limit commit-phase commands to git commands and use their output for inspection; conduct code exploration before the commit phase.
- Do not push to the remote unless the user explicitly asks.
- After the session's own required local checks pass and its delivery is authorized, discover possible same-host peers
  through read-only session inventory and recent task output. Before sending any message, verify that each recipient is
  currently preparing an authorized push to the same repository and Git target under the same publishing account, with
  implementation complete and required local checks passed.
- Exclude idle sessions, completed tasks, sessions awaiting user input, read-only tasks, and peers still implementing
  or running local checks. Treat missing, stale, or ambiguous activity or delivery evidence as ineligible. A shared cwd,
  session title, running agent process, or UI selection (`active`) does not establish delivery readiness.
- Contact only eligible peers individually to confirm readiness. Never broadcast readiness probes, type into idle
  composers, or submit queued text to discover whether a session wants to participate. Recheck eligibility before sending
  a follow-up or Enter; a previous probe does not authorize waking an excluded session.
- Treat bounded contact with verified eligible delivery peers as part of the user-invoked publishing workflow. Honor
  explicit user restrictions; do not ask for a second messaging approval within that authorized scope. Manual pairing
  and supervision are separate workflows and are not prerequisites for this contact.
- Use native steering with identity and delivery receipts, or the verified sender's `--coordination` mode with both
  sender and target endpoints pinned. Preserve drafts and queue ownership; do not improvise terminal typing. Verify a
  received reply before treating transport delivery as an ownership agreement.
- Include only peers that explicitly confirm readiness; agree one push owner and verify the combined candidate within
  the authorized branch flow, preserving each session's commit ownership. Proceed independently when no eligible peer
  is evident or promptly confirms; do not poll or remind excluded peers. The current session's required checks and
  verification of any combined candidate remain mandatory. Participants confirm inclusion instead of pushing duplicates.
- Apply §6 separately when deployment is authorized; shared deployment destinations can collide across Git targets.
- Pass every commit message via a HEREDOC to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
Commit message here.

EOF
)" -- ':(literal)path/to/file'
```

## 5. Release tag safety

- Before preparing a release or deployment, compare Git refs and the target's existing builds, releases and deployed revision. Reuse matching published artifacts and perform only the remaining authorized steps; a matching version label alone does not prove matching contents.
- Publish tags or forge releases only when the user explicitly asks.
- Abort the release workflow on any failed prerequisite or helper command. Never continue with an empty version, platform, notes value, or target revision.
- Verify the proposed tag is absent both locally and on the remote before creating it. An existing tag on another history line is still a collision.
- Preview the exact target commit SHA before confirmation. Create the tag at that reviewed commit and pass the existing tag or explicit target to the forge CLI; never rely on the forge's default-branch target.
- Verify the final tag resolves to the intended commit before reporting the release as complete.

## 6. Shared deployment destinations

- Apply this gate before an authorized deployment dispatch, retry, cancellation, or replacement. A commit/push request
  does not authorize deployment or peer messages about deployment.
- Follow the [delivery coordination procedure](../skills/git/references/coordination.md) to discover candidates,
  verify eligibility, contact independent owners and obtain their acknowledgments. The authorized deployment workflow
  includes that bounded contact; the transport mode itself grants no deployment or supervisory authority.
- Pin the repository, publishing account, destination environment, tenant/brand or service, and intended immutable
  revision. Different source branches or commit SHAs can still collide at that destination.
- Inspect queued/running deployment records and recent same-host session output read-only. Match the destination,
  not just a branch or workflow name; independent core/theme workflows can write to the same environment. Record run
  IDs, intended revisions, and verified live session/pane owners before acting.
- Contact only peers whose recent output establishes an authorized delivery to that destination under the same
  publishing account, with implementation complete and required local checks passed. Include owners already monitoring a queued or running delivery;
  exclude idle/completed sessions, sessions awaiting input, read-only work, and peers still implementing or checking.
  Apply §4's pinned sender, empty-composer, separate Return, submission verification, and recheck rules to every message.
- Agree one deploy owner, exact revision or compatible artifact set, and rollout order with each confirmed participant.
  Reuse a matching active run; serialize different candidates through the project's deployment mechanism and recheck
  destination state before each dispatch. Never merge source branches merely to coordinate deployment.
- Hold the affected destination when an active delivery conflicts and its owner, authorization, or intended order is
  unresolved. Continue independent work; ask the user to settle incompatible target revisions when peers cannot.
  Never cancel, replace, or repeatedly redispatch another session's run to make your candidate win. A cancellation or
  replacement requires authorization covering that action and agreement with the verified active owner, or an explicit
  user decision resolving the conflict.
- Proceed independently when no conflicting delivery or eligible peer is evident. Report the owner/order or the
  no-conflict evidence, then verify the final deployed revision and required remote checks before claiming delivery.
