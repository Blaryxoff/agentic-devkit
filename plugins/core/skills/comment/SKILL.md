---
name: devkit-comment
description: >-
  write updates on verified task fixes. Use for "comment on the task", "отпишись по замечаниям QA", or
  /comment; not release notes.
---

# Comment

Continue a task discussion with a brief Russian update about fixes completed in the latest development session.
Use the task's language when the user requests it. Read history to understand the conversation and avoid repetition.
Report only concrete work completed in the selected session; do not recap earlier fixes or reconfirmations.
Report existing work; do not implement fixes, run a new QA pass, or deploy while composing the update.
Write only to the tasks the user named or unambiguously selected from the current task context. Keep unrelated CI,
deployment and investigation diagnostics in the user conversation. Reading linked tasks or resolving feature owners
does not expand posting authorization. Generic requests to hand off blockers do not authorize tracker comments,
new tickets or mentions; require a separate tracker request naming the destination and intended content.

## Workflow

1. **Resolve the task and mode.** Take the task link/key from the request or current development context. Discover the
   available tracker MCP tools or connector and inspect their schemas before use. Resolve human-facing keys to the
   returned internal task IDs; they need not match. If searching "my tasks", resolve the current user first. Use an
   explicit project/status filter when supplied; never assume a particular tracker, project, Testing status, or user.
   Ask only when the target remains ambiguous. A request to comment authorizes posting to that task; draft, preview,
   and planning requests produce text only. A bare invocation with a clear task uses posting mode. If a required
   tracker capability is unavailable, explain the limitation; deliver a draft only when the available evidence
   supports it, and never claim it was posted.
2. **Read the discussion.** Read the task and its full discussion, following every comment page and long-text chunk
   until complete. Read relevant parent or linked QA tasks when the target refers to their findings. Inspect relevant
   attachments when needed to understand a reported issue. Keep source IDs privately for matching. Follow later
   clarifications, accepted requirements, reopened findings, and decisions about scope; an old report is not the current
   status. If relevant content is inaccessible, report the gap and resolve it before making a claim that depends on it.
3. **Bound the development session.** Use the current conversation's development work by default. For an explicit
   previous session, or a standalone invocation with no development work in context, locate the latest matching
   development session using [Session sources](#session-sources). In posting mode, state the selected scope briefly in
   a progress update; keep draft output limited to the comment itself.
   Keep only work tied to this task and session. Ask for the session when the match is ambiguous; never replace a
   missing session with an arbitrary git date range or all historical work.
4. **Match completed work to its source.** Use existing QA remarks when present. If the complete discussion contains no
   QA remarks, treat the task description and acceptance criteria as the report to address, applying later scope decisions.
   Resolved or already answered QA remarks do not trigger this fallback. Privately match each completed session fix or
   requirement to its source, the expected behavior, and evidence of the resulting behavior. Use session results and focused
   diffs or checks when needed. Include a fix to an old QA report if the fix happened this session. Exclude plans,
   attempted or reverted fixes, other people's work, earlier fixes merely rechecked this session, and the same
   resolution already reported in the discussion. Include a new session fix after a bug was reopened; describe the
   corrected behavior without recapping the earlier fix. Identify the actual symptom fixed and resulting behavior;
   a summary saying only "additional fixes were made" is insufficient evidence for a comment. Keep implementation,
   verification, and deployment evidence distinct. Branch membership does not prove deployment to a server, and
   passing tests does not establish availability on staging or production. Never invent a check, deployment,
   resolution, or fixed count.
5. **Resolve recipients.** Mention the authors/testers whose remarks this update addresses. Add the task owner or
   decision maker only when they need the update or must answer a question. Resolve native mention syntax and identities
   through actual discussion mentions, tracker user records, or supported user lookup. Do not derive handles from email
   addresses or copy a fixed recipient list from an example. Ask about an unresolved necessary recipient rather than
   tagging a guessed person; do not notify every watcher by default. Do not tag the requesting user merely because
   they are the task's assignee, or use mentions to relay unrelated technical blockers.
6. **Compose the continuation.** Apply [Comment style](#comment-style) and the project's task-comment policy.
   Use the same format for replies to QA remarks and reports on description requirements: a bold descriptive name and
   the concrete completed behavior for each item. Describe the concrete fixes or other completed task work from this session.
   Keep a limitation only when needed to describe the scope of that completed work accurately.
   Omit task-wide status reports, outstanding QA acknowledgments, open-issue lists, recommendations,
   and instructions about testing, releasing, or closing the task. Include a question only when the user explicitly
   asks for one. If no concrete new work can be established, explain the evidence gap to the user and do not post a
   generic status update or invent completed work.
7. **Check and deliver.** Confirm every claim is supported, every issue name is understandable without hidden IDs,
   mentions resolve to the intended people, and each item describes completed work rather than a task status or
   instruction to the team. Verify that the destination is in the authorized task set and every paragraph addresses
   that task's selected report or its required deployment evidence. Verify that branch names and inferred server
   availability are absent; preserve exact artifact/version identifiers required by the project even when they contain
   a branch-like prefix. Refresh the latest
   discussion before posting to catch intervening replies or duplicate updates. Reconcile any relevant changes before
   sending. Submit one comment with the tracker's native formatting and mention support. Use an idempotency/request key
   when supported; after a timeout or uncertain result, read the discussion to establish whether it posted before
   retrying. If the outcome remains unknown, stop and report the uncertainty instead of sending again. Read back
   the saved comment and verify text, bold formatting, and mentions through the returned
   representation or rendered UI when necessary. Return the task/comment link; state any unverified rendering plainly.
   In draft mode, return only the ready-to-paste comment. Leave task status, assignments, and other fields unchanged
   unless separately requested.

## Comment style

- Write concise Russian prose that follows the conversation. Start with relevant native mentions on a separate line.
- Lead each fix with a **short descriptive name**, then one or two sentences explaining the corrected behavior and
  the conditions under which it applies. Combine related fixes when they share a scenario; keep materially different outcomes
  separate. Prefer user-visible outcomes and exact UI labels over code internals.
- Use descriptive names such as **Вход гостя во внешнюю встречу**, rather than bug abbreviations or comment numbers.
  Omit internal comment IDs and shorthand bug codes from the posted text. Keep a visible task link only when it helps
  the reader find an actual dependency or follow-up.
- Bold issue names, any section titles, and complete questions requiring an answer. Use the tracker's equivalent of
  Markdown bold and native mentions; do not assume raw `**text**` or `@handle` works everywhere.
- Use sections only when they make several concrete completed outcomes easier to scan. A short comment needs no
  introduction, fixed template, completion totals, sign-off, or summary. Name the actual fix instead of using generic
  headings such as "Состояние реализации" or "Доступность для проверки". Never recap previously confirmed fixes.
- Mention environment availability only when supported by deployment or server evidence. Refer to staging or production
  servers, using their established names or URLs when useful. Never mention git branches, including `master`, `main`,
  or `dev`, and never translate a branch name into a server name. If deployment is unverified, omit availability claims
  and generic uncertainty paragraphs; report the completed fix without implying it is already on a server.
  For updates from `devkit-followup`, explicitly state that the reported fixes were deployed to production when the supplied
  evidence confirms production deployment; staging deployment alone does not support that statement.
- Describe corrected behavior in language the task's readers understand. Keep internal verification tools and process
  out of the comment: omit LunaQA, PHPUnit, Vitest, CI jobs, routine test results/counts, commit hashes, and logs.
  When project instructions require deployment or verification details, include the required fields in their requested
  format using existing deployment/runtime evidence, including checked scenarios, observed results and actual roles
  when requested. Distinguish source fixes from deployed artifacts; report missing evidence to the user without
  inventing identifiers, deployment times or checks.
  Include a checked scenario only when it clarifies the resulting behavior; describe it without naming the tools.
- End after reporting the completed work. Omit "Перед закрытием задачи нужно…", retest/release requests, closing
  checklists, advice, and reminders of the team's responsibilities. Do not add a missing QA confirmation as a caveat
  or imply an entire task is complete because this session's fixes are complete.

Example body after resolved mentions, assuming these fixes are verified on the test environment:

```markdown
**Календарь ученика** — теперь показывает доступные общие и персональные встречи вместе с событиями продукта.
Календарь доступен и без активного продукта.

**Звук по умолчанию** — исправлены старые настройки браузера, из-за которых звук оставался включённым.
Явное включение пользователем сохраняется после перезагрузки.
```

## Session sources

Prefer native session search when available. Otherwise locate candidates by repository/worktree metadata and time
before reading their contents; do not scan unrelated transcript histories. Read the latest matching development
session's request, completion summary, and only the tool results needed to support claims.

| Harness | Default local source | Matching evidence |
|---|---|---|
| Claude Code | `$HOME/.claude/projects/<encoded-root>/*.jsonl` | `cwd`, timestamps, task link/key, affected behavior |
| Codex | `${CODEX_HOME:-$HOME/.codex}/sessions/YYYY/MM/DD/*.jsonl` | session `cwd`, timestamps, task link/key, affected behavior |
| Cursor | `${CURSOR_HOME:-$HOME/.cursor}/projects/<encoded-root>/agent-transcripts/` | project/worktree association, timestamps, task link/key, affected behavior |

Confirm the association using the task and session content, not timing alone. Use current diffs to corroborate a known
session's work; a current diff by itself cannot prove which session made the change. Keep raw session paths and
technical evidence out of the posted comment.
