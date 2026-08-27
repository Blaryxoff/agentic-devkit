---
name: devkit-release-notes
description: >-
  compose a chat-ready release notes post in Russian from git history plus local Claude, Codex, and Cursor sessions since a given date, across one or several project repos. Use for "релиз-ноуты", "что вошло в релиз", "собери релиз с 10.06", "мини-релиз", "release notes since <date>" — anything meant to be pasted into a product/stakeholder chat. Groups changes into emoji-headed product sections, drops internal noise, and always writes Russian regardless of the prompt language. For an English, tag-range, CHANGELOG.md-style document use devkit-changelog-generator instead.
---

# Release Notes (RU)

Turn shipped work since a date into a short Russian post a product owner can read and paste into a team chat. Use git
to establish the released code change set and agent sessions to recover intent, user-visible impact, and non-code
release work. Group by product area — not by repo, commit, or agent.

## Inputs

| Input | Required | Default |
|---|---|---|
| cutoff date | yes | ask if absent; never guess |
| repo roots | no | cwd + every other accessible repo of the same product |
| release branch | no | `origin/HEAD` of each root (`master` / `main` / `production`) |
| agent sessions | no | matching local Claude, Codex, and Cursor transcript stores |
| scale | no | infer: few sections → `Мини-релиз`, otherwise a dated full release |

Accept `DD.MM.YYYY`, `YYYY-MM-DD`, `с 10 июня`, `за последнюю неделю`. Normalise to `YYYY-MM-DD` and state the
normalised value before collecting.

## Workflow

1. **Enumerate repo roots.** cwd plus any other accessible directory belonging to the same product (backend + frontend
   are one release, not two). Keep roots containing `.git`. If only one root is visible, list it and ask the user to
   confirm the set before collecting — a single-repo post silently omits half the release.
2. **Sync and pick the branch.** `git fetch --prune` per root, then read `origin/<branch>` — the local ref can lag
   behind what was actually released.
3. **Collect the change set.** Run both command shapes below per root and de-duplicate: squash-merge repos yield direct
   commits, merge-commit repos yield PR titles.
4. **Collect matching agent sessions.** Use [Agent session sources](#agent-session-sources). Restrict by cutoff and repo
   root/worktree before reading content. Start with user requests and final assistant summaries; inspect tool events
   only when needed to verify completion or release.
5. **Build an evidence ledger.** De-duplicate the same work across agents and repos. Git confirms code reached the
   release branch; sessions explain why it matters. Include session-only work only when a dated record after the cutoff
   proves the target production action succeeded, or the user confirms it shipped. Planned, attempted, failed,
   reverted, and merely local work is dropped.
6. **Resolve opaque commits.** Map a commit to a session using an explicit SHA, changed paths, or task details supported
   by the diff — never timing alone. If still unclear, read `git show --stat` and then the real diff. A commit you cannot
   explain is dropped, never guessed.
7. **Filter noise.** Drop dependency bumps, lint/format, CI config, test-only commits, reverts that cancel out, and
   refactors with no behaviour change. Keep infra work only when it changed reliability, deploy, or performance the team
   will notice.
8. **Resolve non-code and session-only candidates once.** In one question, list unverified completed session work and
   ask about other content/data imports, production reference updates, third-party account/config changes, or manual
   production actions. Include only the items the user confirms shipped.
9. **Cluster into product sections.** One section per product area (vocabulary and ordering: `references/style.md`). A
   feature that landed in two repos is one line.
10. **Write the post** per `references/style.md`. Russian only.
11. **Flag ops follow-ups.** Anything needing a manual step after deploy — API keys, env vars, migrations, seeders, cron,
   catalog import, third-party account — gets a `⚠️ Важно:` line inside its section.
12. **Verify before delivering.** Every line traceable to git, dated session evidence of a successful production action,
    or a user-confirmed item; no SHAs, paths, ticket/session ids, prompt text, or secrets leaked; fix-flavoured sections
    last; Russian throughout. Outside the post, state the roots/range and which of Claude, Codex, and Cursor were
    available.

## Agent session sources

Use these defaults when readable; also accept explicit transcript roots or a harness-provided session search. Encoded
project directories replace path separators with `-`; Claude keeps the leading separator as `-`, while Cursor drops it.
Confirm association from transcript `cwd` metadata where present; accept the repo root and its git worktrees only.

| Agent | Default store | Scope and time signal |
|---|---|---|
| Claude | `$HOME/.claude/projects/<encoded-root>/*.jsonl` | message `timestamp`; record `cwd` |
| Codex | `$CODEX_HOME/sessions/YYYY/MM/DD/*.jsonl`, or `$HOME/.codex/sessions/...` when unset | `session_meta` / `turn_context` `cwd`; record `timestamp` |
| Cursor | `$HOME/.cursor/projects/<encoded-root>/agent-transcripts/<session>/<session>.jsonl` | project directory; file mtime is only a shortlist when records lack timestamps |

- Shortlist files by cutoff before reading them; do not crawl unrelated project stores or the whole home directory.
- Read top-level sessions first. Skip subagent transcripts when their parent summary already covers the work.
- Extract user/assistant natural-language messages first. Ignore system/developer prompts, hidden reasoning, and bulk tool
  output. Inspect the smallest relevant tool result only to prove a claimed deploy, release, import, or manual action.
- Treat final summaries as claims, not proof. `implemented`, `fixed`, or `tests pass` does not mean released.
- When records lack timestamps, use the transcript only to explain git-confirmed work. Session-only work then requires
  dated production evidence inside the transcript or user confirmation; file mtime does not prove when an action ran.
- Never quote raw transcripts or expose credentials, environment values, personal data, prompts, or session ids. Use
  session evidence only to write the product-level release line and the private evidence ledger.
- If a store is absent or unreadable, continue with the available sources and report the missing agent outside the post.

## Commands

```bash
# shortlist transcript files inside one already-scoped agent store; filter records by their own timestamps afterwards
find <scoped-agent-store> -type f -name '*.jsonl' -newermt <YYYY-MM-DD>

git -C <root> fetch --prune
git -C <root> symbolic-ref --short refs/remotes/origin/HEAD          # release branch

# squash / rebase workflow — direct commits on the release branch
git -C <root> log --since=<YYYY-MM-DD> --first-parent --no-merges \
    --date=short --pretty='%h %ad %s' origin/<branch>

# merge-commit workflow — merged PR titles
git -C <root> log --since=<YYYY-MM-DD> --merges \
    --date=short --pretty='%h %ad %s' origin/<branch>

# scope of the whole range
git -C <root> diff --stat <first-sha>^..origin/<branch>

# opaque commit
git -C <root> show --stat <sha>
```

If a release tag was cut after the cutoff date, prefer `<tag>..origin/<branch>` and say which range you used.

## Hard rules

- **Russian always.** English prompt, English commits, English repo — the post is still Russian.
- **Impact, not commit text.** `Добавлен фильтр «В ближайшие 2 часа»`, not `feat(catalog): add nearest-slot filter`.
- **Never invent.** No release line without supporting git, dated production evidence, or user confirmation. Uncertain →
  drop it or ask.
- **Sessions supplement git.** A plan or completion claim is not release evidence. Session-only work needs an explicit
  dated successful production action in the transcript or user confirmation.
- **No engineering residue** in the post: SHAs, file paths, branch names, PR/ticket numbers, class names. Product nouns
  the team already uses (admin section names, URLs, integration names) are fine.
- **One change per line.** No paragraphs, no multi-clause sentences.
- **No preamble, no summary, no «Итого», no evidence block.** The date line and the sections are the whole post.
- **Never group by repo.** The reader neither knows nor cares which repo shipped what.
- Report what you dropped as noise or unverified session-only work in one line *outside* the post, so the user can
  object.

## Output

Deliver the post in chat as plain text ready to paste into a messenger. Write a file only when the user asks for one.

Format, section vocabulary, emoji set, and verb forms: `references/style.md`.
