---
name: devkit-backlog
description: >-
  read, triage, work, or append a Git repository's deferred-work items in docs/backlog/. Use when the user says
  "backlog", "check backlog", "work the backlog", "add to backlog", or when real findings from the current task should
  be deferred instead of fixed now. Supports a slug and --all; verifies stale anchors before recommendations.
---

# Backlog

> Adapted from `umputun/cc-thingz` (MIT).

Follow `plugins/core/conduct/deferred-work-backlog.md` and `plugins/core/conduct/git-commit-workflow.md`. Operate only in
a Git repository. Outside one, report that the workflow requires Git and stop.

## Route the request

Check modes in this order:

1. `--all` — walk every item to a disposition.
2. `<slug>` — inspect and decide one `docs/backlog/<slug>.md` item.
3. Explicit add/defer intent — append accepted findings.
4. No argument — list the backlog and offer one concrete next action.

Reject unknown option syntax beginning with `-`. Treat `all` as an ordinary slug; only `--all` selects the all-items
mode.

## Read or list

1. Glob `docs/backlog/*.md`. If none exist, report that the backlog is empty; do not create an empty directory.
2. Read the requested files and verify every `where` per conduct §4.
3. For a list, print one line per item in the required order. Include `worth`, title, `where` when present, and `stale`
   when verification failed.
4. Use the environment's structured question tool when available; otherwise ask one concise question. Recommend a named
   action first: fix one item, drop one item, or leave the backlog unchanged. Do not start work without that choice.

## One slug

1. Read only `docs/backlog/<slug>.md` and verify its anchor.
2. If it does not exist, report the exact missing slug and list the available slugs. Do not guess a nearest match.
3. Print the four-part briefing from conduct §5.
4. Ask whether to fix it, drop it, or leave it. Apply the answer before any broader backlog work.

## All items

1. Read every item in full. Verify all anchors and map dependencies before asking the first question.
2. Order real prerequisites before their dependents; otherwise retain conduct §4 ordering.
3. Process one item at a time. Print `item N of M`, then its four-part briefing, then ask about that item alone.
4. Carry out the answer before moving on. Immediately before a fix or drop, re-read the item and re-verify `where`; if
   earlier work changed the evidence materially, brief and ask again.
5. On a fix, run the applicable verification and `git rm` the item in the same proposed commit scope.
6. Continue until every item has a disposition. Never auto-commit.

## Append accepted findings

1. Present each proposed item and ask which findings to retain. Silence is not authorization.
2. Run the default-branch gate in conduct §3 before creating the directory or writing files.
3. Dedupe per conduct §6. Update an existing item when the defect matches; do not create a parallel account.
4. Write exact frontmatter and body per conduct §1. Use today's ISO date for `added`.
5. Inspect the pre-existing index before staging or offering a commit. If anything is already staged, report it and stop.
6. Offer the next Git action, but do not commit or push without explicit authorization.

## Mutation rules

- Treat reading, listing, and briefing as read-only.
- Apply normal tests, formatters, and linters to any accepted fix.
- Delete fixed or dropped items with `git rm`; never mark them complete in place.
- Keep backlog notes out of contributor discussions unless the user explicitly asks.