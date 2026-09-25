# Evidence sources

Every source: where it lives, what counts as the person's own activity, and what breaks silently.

## Agent logs

### Claude Code

- Transcripts: `~/.claude/projects/<encoded-cwd>/<session>.jsonl`, subagents under `<session>/subagents/` (skip them).
- Human prompt = `type: user`, not `isSidechain`, and `turnOrigin == human` or `promptSource` in
  `typed | queued | suggestion_accepted`. Drop `turnOrigin` `peer | scheduled | task_notification | sdk` and
  `promptSource` `system | sdk`, then text starting with `<command-`, `<task-notification`, `Chat from`,
  `[Artifact comment`, `<system-reminder`, `Caveat:`.
- Agent actions (`type: assistant` content incl. tool inputs) carry file paths and hosts → project hints.
- **Retention**: transcripts are deleted after `cleanupPeriodDays` (default ~30). Check the oldest file per project
  before trusting a month. A month with commits and no transcripts is a hole.
- **`~/.claude/history.jsonl` survives retention**: every typed prompt with `timestamp` (ms), `sessionId`, `project`,
  `display`, `pastedContents`. Use it for sessions without a transcript. `project` is the launch directory only — a
  session started in repo A may have worked on client B, so route those sessions by prompt content
  (`other_client_rx` vs `target_mention_rx`).

### Codex

- `$CODEX_HOME/sessions/YYYY/MM/DD/rollout-*.jsonl` (default `~/.codex`). First line `session_meta` has `cwd`,
  `originator`, `git.branch`.
- `originator: codex_exec` = spawned by another agent (reviews, QA, pair checks) → not human; use its start time
  only as a low-confidence anchor for days with no surviving human log.
- `codex-tui` / `Codex Desktop` user text is in `response_item` `message` `role: user` (older: `event_msg`
  `user_message`). Filter injected content: `# AGENTS.md`, `<environment_context`, `<user_instructions`,
  `<recommended_plugins>`, peer-chat `Chat from …`, `>>REQ` / `<<RPY` protocol lines, `<turn_aborted`.
- Resumed/forked rollouts replay history with the original timestamps — harmless in a minute union, dedupe per file by text.
- Directory is large (tens of GB): parse `timestamp` from the first 600 chars with a regex and `json.loads` only
  lines that can matter.

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
- Work visits: stands, admin panels, brand sites, the tracker, the repo on GitHub. Exclude other clients' tracker
  queues by URL/title and personal VPN/edge hosts.
- Only the listed work domains are read; never dump the whole history into the conversation.

## Calls

- Browser call tabs: Telemost `/j/<id>`, Zoom `/j/<id>`, Meet codes, Jitsi rooms, tracker voice rooms. Group visits
  per (day, room); duration = min(sum of `visit_duration`, first→last span). A forgotten tab inflates
  `visit_duration` — flag calls over ~2 h.
- Participants are not recoverable locally. To attribute a call, show the user what was open ±20 min around it
  (domains, tracker queues, stand hosts) and let them confirm; recurring rooms often belong to another client.
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
