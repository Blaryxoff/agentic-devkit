# Git Commit Workflow

Only create commits when the user explicitly asks. If the request is ambiguous, ask first — never commit proactively. The user must request a commit in the current query or in a standing user rule; otherwise do not commit.

## 1. Safety protocol

- Never update the git config.
- Never run destructive or irreversible git commands (`push --force`, `reset --hard`, etc.) unless the user explicitly requests them in the query or a standing user rule.
- Never skip hooks (`--no-verify`, `--no-gpg-sign`, etc.) unless the user explicitly requests it.
- Never force-push to `main`/`master`; warn the user if they request it.
- Never use interactive flags (`git rebase -i`, `git add -i`) — they require input this environment cannot provide.
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

- Treat every path staged before the current task as foreign work unless the user explicitly includes it.
- Pass intended paths to both `git add --` and `git commit --`. A bare `git commit` sweeps the whole index, including unrelated work staged before this task.
- Pass file names as literal pathspecs (`:(literal)path`) when constructing commands. Reject empty path arguments; an empty pathspec can match the whole current directory.
- After any hook runs, inspect `git show --name-status --format= HEAD` and `git status --short`. Hooks can modify or stage files; never discard, unstage, or absorb unexpected paths without inspecting them.
- Run only git shell commands during a commit — do not read or explore code beyond git output.
- Do not push to the remote unless the user explicitly asks.
- Pass every commit message via a HEREDOC to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
Commit message here.

EOF
)" -- ':(literal)path/to/file'
```

## 5. Release tag safety

- Publish tags or forge releases only when the user explicitly asks.
- Abort the release workflow on any failed prerequisite or helper command. Never continue with an empty version, platform, notes value, or target revision.
- Verify the proposed tag is absent both locally and on the remote before creating it. An existing tag on another history line is still a collision.
- Preview the exact target commit SHA before confirmation. Create the tag at that reviewed commit and pass the existing tag or explicit target to the forge CLI; never rely on the forge's default-branch target.
- Verify the final tag resolves to the intended commit before reporting the release as complete.
