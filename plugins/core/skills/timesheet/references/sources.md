# Evidence sources

Every source: where it lives, what counts as the person's own activity, and what breaks silently.

## Agent logs

### Claude Code

- Transcripts: `~/.claude/projects/<encoded-cwd>/<session>.jsonl`, subagents under `<session>/subagents/` (skip them).
- Human prompt = `type: user`, not `isSidechain`, and `turnOrigin == human` or `promptSource` in
  `typed | queued | suggestion_accepted`; accept legacy unlabelled user text after machine filtering. Reject
  `isCompactSummary`, `isMeta` and `auto_continuation` even when the record claims a human origin. Drop `turnOrigin`
  `peer | scheduled | task_notification | sdk` and
  `promptSource` `system | sdk`, then text starting with `<command-`, `<task-notification`, `Chat from`,
  `[Artifact comment`, `<system-reminder`, `Caveat:`.
- Agent actions (`type: assistant` content incl. tool inputs) carry file paths and hosts → project hints.
- **Retention**: transcripts are deleted after `cleanupPeriodDays` (default ~30). Check the oldest file per project
  before trusting a month. A month with commits and no transcripts is a hole.
- **`~/.claude/history.jsonl` survives retention**: every typed prompt with `timestamp` (ms), `sessionId`, `project`,
  `display`, `pastedContents`. Merge it with partial transcripts too. `project` is the launch directory only — a
  session started in repo A may have worked on client B, so route those sessions by prompt content
  (`other_client_rx` vs `target_mention_rx`).

### Codex

- Read `$CODEX_HOME/sessions/YYYY/MM/DD/rollout-*.jsonl` and archived rollouts (default root `~/.codex`).
  First-line `session_meta` identifies the session, cwd, originator, source, thread_source and git branch.
- Always merge `$CODEX_HOME/history.jsonl`: `{session_id, ts, text}`, with Unix-second input timestamps. It can survive
  deleted or truncated rollouts. Group by the actual session UUID, not the rollout filename.
- Open the latest `state_*.sqlite` in `mode=ro`; `threads` maps IDs to cwd, branch and provenance. Compare its
  rollout paths with surviving files. `has_user_event=0` is not reliable evidence that user inputs are absent.
  Never count `created_at`, `updated_at` or a cached first message without its actual input timestamp as activity.
- Query the latest `thread_history_*.sqlite` read-only for `thread_items` with the eligible `thread_id`,
  `item_type='userMessage'` and period bounds on `created_at_ms`; parse `item_json.content`. Use indexed per-thread
  queries, never copy or scan the multi-GB database. This source also supplements incomplete input history.
- Exclude `codex_exec`, subagent source objects, `thread_source=subagent | guardian_review | agent_created_thread`
  and attached agent children from human activity, even if their originator is `codex-tui` or their text looks human.
- `codex-tui` / `Codex Desktop` user text is in `response_item` `message` `role: user` (older: `event_msg`
  `user_message`). Filter injected content: `# AGENTS.md`, `<environment_context`, `<user_instructions`,
  `<recommended_plugins>`, peer-chat `Chat from …`, `>>REQ` / `<<RPY` protocol lines, `<turn_aborted`, automatic retries
  and generated continuation summaries. Structured question replies are human answers; normalize their JSON content.
- Reconcile history, rollout and cached events one-to-one by stable identity or matching text/time. Keep legitimate
  repeated prompts and messages sharing a long prefix. Source coverage counts may exceed unique normalized prompts.
- Use first-line metadata to skip delegated rollouts early. A timestamp prefix is only a fast path: if it is absent
  from the header of a long record, parse the record before deciding it is outside the period.
- The extractor writes `<out>.coverage.json` with aggregate source dates/weeks, missing rollout files and unmapped
  history counts. Resolve or disclose gaps before finalizing hours. `--home` / `--codex-home` select explicit source roots.

### Cursor

- IDE chats: `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (Linux `~/.config/Cursor/...`),
  table `cursorDiskKV`. `composerData:<id>` = chat header (`createdAt`, `lastUpdatedAt`, name); messages are
  `bubbleId:<composerId>:<bubbleId>` with `type` 1 = user, `createdAt`, `text`.
- The file is multi-GB: open `file:…?immutable=1`, never copy. Query bubbles by key range
  (`key >= 'bubbleId:<cid>:' AND key < 'bubbleId:<cid>;'`) — a `LIKE` per composer scans the whole table and looks hung.
- Workspace mapping in `workspaceStorage/*/state.vscdb` covers few chats; infer the repo from absolute paths inside
  composer and bubble JSON instead.
- Subagent chats open with a machine brief (`Act as …`, `Run exhaustive …`, `Review the latest commit …`,
  `<system_notification>`): drop the whole chat when its first prompt is one.
- CLI agent: `~/.cursor/chats/<hash>/<id>/{meta.json,store.db}`; `meta.json` has `cwd` and created/updated ms.
  Chats whose cwd is a scratchpad were delegated by another agent.
- `~/.cursor/ai-tracking/ai-code-tracking.db` holds commit scoring, not conversations.

### Telegram bots (Hermes-style)

- `state.db` with `sessions(source, user_id, started_at)` and `messages(role, content, timestamp)`; one per bot,
  often inside a container or Incus instance on another host. Run `scripts/hermes_dump.py` there
  (`docker cp` + `docker exec`, or `incus file push` + `incus exec`), read-only.
- Keep only `role: user` rows of the person's `user_id` from `source: telegram`. Other users of a shared bot are not
  the person; `cron`, `subagent`, `webhook`, `kanban`, `tool` sessions are machines. Drop injected
  `[IMPORTANT: Background process…]`, `[Cron delivery…]`, `[CONTEXT COMPACTION…]`.
- Bots mix personal life with work: count a message for the target only when it names the target
  (`target_mention_rx`).

## Git

- `git log --all --since --until --author=<each identity> --name-only --format='@@%H|%aI|%s'` per repo; worktrees
  share one repo, so dedupe by SHA.
- Commit times anchor only days/periods without surviving human logs; commit counts never convert to hours.
- Conventional-commit scopes (`fix(brand)`) and changed paths (`Pages/<Brand>/`) are strong project hints.
- Backlog directories (e.g. `docs/backlog/`): items closed = files deleted by the person in the period; check that
  closed ⊂ added before writing "closed X of Y".

## Browser history

- Chrome/Chromium `…/<Profile>/History` (SQLite, locked while the browser runs → copy first). `visits.visit_time`
  and `visit_duration` are µs since 1601-01-01 UTC; `urls.url`, `urls.title`.
- Inventory available profiles and measure each history's first/last surviving date and period coverage read-only.
  Distinguish absent databases, access denied and retention gaps. An empty period result does not establish no
  browser work or calls; the first surviving visit alone does not prove when or why earlier history was deleted.
- If coverage is incomplete, establish the work browser from existing evidence or ask the user. Record the missing
  period and affected calls, browser work and manual browser testing in the report's separate coverage section.
- Work visits: stands, admin panels, brand sites, the tracker, the repo on GitHub. Exclude other clients' tracker
  queues by URL/title and personal VPN/edge hosts.
- Only the listed work domains are read; never dump the whole history into the conversation.

## Calls

- Browser call tabs: Telemost `/j/<id>`, Zoom `/j/<id>`, Meet codes, Jitsi rooms, tracker voice rooms. Group visits
  per (day, room); duration = min(sum of `visit_duration`, first→last span). A forgotten tab inflates
  `visit_duration` — flag calls over ~2 h.
- Participants are not recoverable locally. To attribute a call, show the user what was open ±20 min around it
  only for the target (domains, tracker queues, stand hosts) and let them confirm. Keep unrelated-client context
  invisible; for an uncertain call, ask using its date, room and duration without naming unrelated work.
- Tracker calendars (e.g. ghostflow `/api/scheduled-calls?from&to`) give titles and invitees but usually cover a
  fraction of real calls. Telegram/phone calls are invisible — ask for a figure or leave them to the overhead factor.

## Trackers

- **ghostflow**: log in via the chrome-devtools browser window (the user types credentials), then `fetch` from
  `evaluate_script`: `/api/auth/me`, `/api/projects`, `/api/tasks` (`assignees[]`, `projects[]`),
  `/api/tasks/<id>`, `/api/tasks/<id>/activity` (`status_changed`, `comment_added`, `userName`, `createdAt`).
  `evaluate_script(filePath)` must write inside the workspace root; move the file to the scratchpad afterwards.
- **Imported tasks**: descriptions like "Импорт из Яндекс Трекера / Оригинальный ключ: PROJECT-NNN" mean `createdAt`
  is the import date and bulk status flips right after import are bookkeeping. Resolve the real closing date from
  the source tracker.
- **Yandex Tracker**: `POST https://api.tracker.yandex.net/v2/issues/_search` with `{"keys": [...]}` or
  `{"query": "Queue: X Assignee: \"Name\" Updated: >= date"}`; IAM token + `X-Cloud-Org-ID`. Closed date is
  `statusStartTime` when `status.key == closed` (`resolvedAt` is often empty).
- Brand work often sits in a generic "platform" project with the brand only in the title.

## Coverage checklist to report

Per source: present / absent / partial (retention date), rows extracted, share of the period covered.
