---
name: wrapup
description: >-
  close out finished work — sweep this session's leftovers, verify, commit, push, deploy, clean up the worktree, and report evidence (SHAs, CI runs). Invoke on "wrapup", "/wrapup", "commit and push", "commit, push, deploy", "коммить и пушь", "выкати", "deploy", "remove worktree", or any request to finish/ship the current task. Do NOT invoke on a status question ("did you push?", "deployed?") — answer those from git/gh evidence without shipping anything. Does NOT review code — the user invokes a reviewer skill explicitly. Does NOT open PRs.
---

# Wrapup

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

Ship the finished task and prove it shipped. Every claim in the final report comes from a command you ran.

Invoking wrapup **is** the authorization to commit, push, and deploy — that is what satisfies `git-commit-workflow.md` §4's "do not push unless asked" default. A status question is not an invocation: when the user only asks whether something was pushed or deployed, answer from `git rev-parse`, `git status` and `gh run list`, and change nothing.

## Step 1 — Scope: this session's task, not the repository

The commit list comes from what **this session** changed. `git status` is a detector, never the source of truth.

1. List the paths you created or modified in this session, plus the artifacts your changes generated (migrations, lockfiles, generated clients).
2. Group them by repository — a session often spans backend + frontend, or a main checkout plus a worktree. Run `git worktree list` in each.
3. State the scope (repos + session paths) before touching git. Ask via `plugins/core/conduct/clarification-protocol.md` when a path's ownership is unclear.

## Step 2 — Sweep and triage (per repo)

```bash
git status --porcelain=v1 -unormal                          # modified, deleted, untracked, unmerged
git stash list
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
if [ -n "$upstream" ]; then git log --oneline "$upstream"..HEAD; else echo "no upstream — every local commit is unpushed"; fi
```

Every dirty path outside the session list gets triaged before anything is staged:

| Bucket     | Test                                                                                                     | Action                                                         |
|------------|----------------------------------------------------------------------------------------------------------|----------------------------------------------------------------|
| `session`  | In the session list                                                                                        | Commit (Step 4)                                                |
| `related`  | Not this session's, but same feature/module/branch — and no signal of a live owner                          | Report it, say why it looks related **and that its owner is unverified**, offer to include; commit only on an explicit yes |
| `parallel` | Any live-owner signal, or the user said another session is running here                                     | Inform only. Never offer to commit, never drop                 |
| `drop`     | Scratch, debug output, temp artifact this session produced                                                 | Ask, then remove                                               |

Ownership evidence, strongest first:

| Signal | Proves | Use |
|--------|--------|-----|
| Your own session list (files you wrote) | Session ownership | Commit |
| `git worktree list --porcelain` | Which paths and branches are checked out elsewhere | Another worktree's dirt is never yours — report that worktree, never sweep it |
| `test -e "$(git rev-parse --git-path index.lock)"` | A git process is mid-operation here | Stop; report contention, do not stage |
| File mtime, `pgrep claude/codex`, git author identity | Nothing about ownership — parallel agents share your identity and touch files for many reasons | Never use as commit evidence |

- **`parallel` wins ties.** A path outside the session list is `related` only when it is task-related and nothing suggests a live owner; anything else is `parallel`. Ownership cannot be proven for a path you did not write, so every `related` offer states that out loud — the user, not the skill, resolves it.
- **Never sweep on the user's behalf.** No `related` path is staged without a yes naming it.
- A path already dirty **before** this session and edited by it carries mixed hunks; path-level staging cannot separate them. Report the mix and let the user decide.
- Deleted and unmerged paths are leftovers too. Resolve or report them; never resolve a conflict blind.
- Sweep debris inside the code you wrote: debug prints, commented-out code, TODO markers you introduced, disabled tests.
- Never drop anything without explicit confirmation.

## Step 3 — Verify

Run `plugins/core/conduct/verification-loop.md` (lint → typecheck → test → security) **before** the push, not after.

Skip only for docs-only or config-only changes, and say that you skipped it.

## Step 4 — Commit

Follow `plugins/core/conduct/git-commit-workflow.md` for commit mechanics — safety protocol (§1), amend rules (§2), ordered steps (§3), scope discipline (§4: literal pathspecs, never a bare `git commit`), HEREDOC message. §4's "do not push unless asked" default is lifted by the wrapup request itself; every other rule applies unchanged.

Commit the `session` bucket plus any `related` paths the user approved. Split into logical commits when the groups are unrelated. Never stage a `parallel` path.

## Step 5 — Push

- Push the current branch. With no upstream, push with `-u` (`git push -u origin HEAD`) so the tracking ref exists; then verify `git rev-parse HEAD` equals `git rev-parse @{u}`.
- Never open a PR/MR unless the user asked. Push to the branch directly.
- Merge into another branch (`dev`, `master`, a downstream repo) only when the user asked or the project's documented flow requires it. Never invent a branch flow.
- Force-push only on an explicit request in this turn.

## Step 6 — Deploy

1. **Discover, never invent.** Read the project's `CLAUDE.md` / `AGENTS.md` / `README.md`, `.github/workflows/*`, `bin/deploy*`, `Makefile`, `docs/`. Run the documented command verbatim, with the absolute path it documents — a relative path can resolve to the wrong checkout and silently no-op.
2. **Push-triggered CI**: when the push itself deploys, watch the run for the commit you pushed — never "the latest run on the branch":

   ```bash
   sha=$(git rev-parse HEAD)
   gh run list -b "$(git branch --show-current)" -L 20 --json databaseId,headSha,workflowName,status \
     | jq -r --arg sha "$sha" '.[] | select(.headSha == $sha) | "\(.databaseId) \(.workflowName) \(.status)"'
   gh run watch <id> --exit-status
   ```

   No run for that SHA yet → wait and re-list; do not report a run whose `headSha` differs. A push is not a deploy until that run concludes green.
3. **Target**: deploy the project's default target and name it in the report. When several targets exist (brands, hosts, environments) and the user named none, ask which — do not fan out.
4. **Red CI**: fix small scoped failures and re-watch; escalate anything ambiguous. Use `devkit-babysit` when the target is a PR under review.
5. **No deploy mechanism found**: say so, stop, do not improvise one.

## Step 7 — Worktree cleanup

Remove the session's worktree with `git worktree remove <path>` when its branch is merged or the user asked. Delete the branch only on request. Step 2 should have emptied the worktree; confirm before removing one that still holds content.

## Step 8 — Report (the deliverable)

One row per repo, every cell taken from a command:

| Repo | Branch | Commits | HEAD | Remote | Verify | Deploy | Leftovers |
|------|--------|---------|------|--------|--------|--------|-----------|
| `api-x` | `feature/y` | 2 | `a1b2c3d` | `a1b2c3d` ✅ | tests 42 ✅ | run #163 green → prod | none |

Then list: leftovers left behind and why, steps skipped, actions the user must take.

Never write "pushed" or "deployed" without the SHA match or the run conclusion beside it. Apply `plugins/core/conduct/readiness-gate.md` before handoff.

## Hard rules

- Do not run reviewer skills, browser QA, or refactors here. Wrapup ships what exists.
- Do not fix unrelated defects found mid-sweep. Report them.
- Do not commit secrets (`.env`, credentials, tokens) or machine-local artifacts.
- Do not run `reset --hard`, `clean -fd`, or `push --force` without an explicit request in this turn.
- Stop and ask when the branch target, the deploy target, or a leftover's owner is ambiguous.
