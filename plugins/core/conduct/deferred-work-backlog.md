# Deferred Work Backlog

> Adapted from `umputun/cc-thingz` (MIT).

Use `docs/backlog/` for real repository work intentionally deferred from the current task. Keep one Markdown file per
item. This is the maintainer's internal queue: it never gates a contributor and never belongs in a PR/MR or issue thread
unless the user explicitly asks.

## 1. Item format

Name each item `docs/backlog/<defect-slug>.md`. Name the defect, not the file that currently contains it.

```markdown
---
worth: later
where: internal/window/library.go:537
added: 2026-08-05
---
# reopen fallback ignores the last-frontmost window

`reopen` ignores the last-frontmost window when `frontmost` is nil. The fix touches restore ordering, so it was deferred
rather than expanded into the current change.
```

- Set `worth: yes` when the value is agreed even if scheduling or an external blocker remains.
- Set `worth: later` only when the value decision is unresolved. Name the condition or unknown that would settle it.
- Set `worth: no` only when retaining the rejection rationale prevents repeated rediscovery. Delete stale `no` items.
- Add `where: path:line` only when one location anchors the finding. Treat the line as a navigation hint, not identity.
- Set `added: YYYY-MM-DD` once. Never rewrite it; age is backlog information.
- Use the H1 as the title. Keep the body as short as the evidence allows, but record why the item exists and why it was
  deferred or rejected.

## 2. Lifecycle

- Create an item only after the user accepts deferral. Never write backlog findings silently.
- Remove an item with `git rm` in the same commit that lands its fix. Do not add checkboxes or in-progress fields.
- Remove a rejected item with `git rm` when its rationale no longer earns a permanent record.
- Never fix an item merely because the user asked to read or triage the backlog.
- Never auto-commit or auto-push backlog changes. Follow [git-commit-workflow.md](./git-commit-workflow.md) after explicit
  authorization and keep backlog-only filing separate from unrelated implementation work.

## 3. Branch safety before appending

Write a new item on the repository default branch unless the user explicitly accepts the current checkout.

1. Resolve the default branch from `refs/remotes/origin/HEAD`.
2. If unavailable, probe complete remote refs in order: `origin/master`, `origin/main`, `origin/trunk`.
3. Only if no remote candidate exists, probe local `master`, `main`, then `trunk`.
4. Compare the resolved branch with `git branch --show-current`.
5. On another branch or detached HEAD, report the checkout and ask before writing. Do not switch branches, create a
   worktree, or choose a destination without authorization.
6. Create `docs/backlog/` only after this branch gate passes.

## 4. Verification and ordering

- Read every item needed by the requested mode before reporting it.
- Verify each `where` against the current tree. Report a missing or mismatched anchor as stale, not as confirmed work.
- Order list output by `worth`: `yes`, `later`, `no`; then oldest `added` first.
- Keep every item visible. `worth` controls recommendation and ordering, not filtering.
- Identify dependencies between items before an all-items triage. Ask about prerequisites before dependents and carry the
  relationship into both briefings.

## 5. Item briefing

Brief an item against the repository as it exists now, not only against the item's potentially stale account:

- **Summary** — explain the defect and why it was filed in one or two sentences.
- **Effort** — name the files/call sites, test coverage, and whether the fix is mechanical or requires a design decision.
- **Blast radius** — name callers, generated artifacts, shared paths, and rollback difficulty.
- **Materiality** — name who is affected now, severity, and the cost of leaving it.

Keep effort, blast radius, and materiality to one evidence-bearing line each. Do not inflate items with no user-visible
symptom.

## 6. Dedupe and updates

- Use the slug and `where` path to find candidates; settle duplication by the defect each item claims.
- Do not treat a shared path as proof of duplication. One file can contain several unrelated defects.
- Do not treat a changed line number as a new item.
- Do not treat two items without `where` as duplicates merely because both omit it.
- Update the existing file when a new sighting sharpens the evidence or changes `worth`.
- Before staging, inspect `git diff --cached --name-only`. Treat every pre-existing staged path as foreign work and stop
  rather than sweeping it into a backlog commit.