# Parallel Sessions

Run independent concurrent AI tasks on the same repo in isolated git worktrees so edits never collide. A worktree is a second working directory on its own branch sharing one `.git` — cheaper and safer than cloning the repo.

## Continue an existing branch

- Apply requested fixes and follow-up work to the existing branch in its current checkout. Create or switch to another branch, worktree, or clone only when the user explicitly requests it; parallel-session isolation does not override this rule.
- Preserve unrelated changes in that checkout and edit only the requested scope. Unrelated changes alone do not justify moving the fixes elsewhere; if concurrent edits prevent safe work in place, explain the conflict and ask how to proceed.

## When to parallelize

- Independent features or fixes that touch disjoint files.
- A long task (research, large refactor) in one worktree while routine work continues in another.
- Spiking two approaches to the same problem on separate branches.

## When NOT to parallelize

- Changes that share migrations, lockfiles, or generated artifacts — concurrent edits produce conflicting schema/state.
- A single task split across worktrees that must share in-progress context.
- Work that is faster done sequentially than the overhead of managing multiple branches.

## Worktree discipline

- For a separate task that needs isolation, create one worktree per branch: `git worktree add ../<repo>-<feature> -b feature/<id>-<slug>` (Claude Code: `claude --worktree <feature>`). For follow-up work, apply the existing-branch rule above.
- Record the path and owning repository of every worktree or temporary clone this task creates. Never treat another session's checkout or the main repository as task-owned.
- Name the directory after the feature; keep it a sibling of the main checkout, not nested inside it.
- A worktree needing runtime QA follows [runtime-configuration.md](./runtime-configuration.md#canonical-local-servers) → **Canonical local servers**: an explicitly canonical setup allocates its own registered checkout/profile through that manager; other environments use existing project runtime commands and a dedicated worktree port. Record the task owner and stop task-started runtimes at task end; do not reuse another checkout's runtime.
- Run `devkit-verify` (lint, typecheck, test per project policy) inside a worktree before merging its branch.
- Merge back through the normal branch flow per `git-commit-workflow.md`; resolve conflicts on merge, not by editing across worktrees.
- Before the task's final handoff, inspect each task-created worktree with `git -C <path> status --porcelain`. Remove a clean one from its main repository with `git -C <main-repo> worktree remove <path>`, then verify it is absent from `git worktree list`. Do this when the task ends even if the branch is unmerged or unpushed; removing the worktree retains the branch and commits.
- Keep the branch unless the user asks to delete it. Report an unpushed branch and its commit SHA. Never force-remove a dirty, locked, or ambiguously owned worktree; report its path and state and resolve how to preserve its contents before calling the task closed.
- Remove a task-created temporary clone only after confirming it has no dirty files or commits that exist only there. Report any blocked cleanup. Scripts that create temporary clones must use an exit trap with the same safety checks; do not delete persistent project checkouts.
