# Parallel Sessions

Run concurrent AI sessions on the same repo in isolated git worktrees so edits never collide. A worktree is a second working directory on its own branch sharing one `.git` — cheaper and safer than cloning the repo.

## When to parallelize

- Independent features or fixes that touch disjoint files.
- A long task (research, large refactor) in one worktree while routine work continues in another.
- Spiking two approaches to the same problem on separate branches.

## When NOT to parallelize

- Changes that share migrations, lockfiles, or generated artifacts — concurrent edits produce conflicting schema/state.
- A single task split across worktrees that must share in-progress context.
- Work that is faster done sequentially than the overhead of managing multiple branches.

## Worktree discipline

- Create one worktree per branch: `git worktree add ../<repo>-<feature> -b feature/<id>-<slug>` (Claude Code: `claude --worktree <feature>`).
- Name the directory after the feature; keep it a sibling of the main checkout, not nested inside it.
- Each worktree gets its own dev server / port if one is needed — do not share a single server across worktrees.
- Run `devkit-verify` (lint, typecheck, test per project policy) inside a worktree before merging its branch.
- Merge back through the normal branch flow per `git-commit-workflow.md`; resolve conflicts on merge, not by editing across worktrees.
- Remove a finished worktree with `git worktree remove <path>` once its branch is merged.
