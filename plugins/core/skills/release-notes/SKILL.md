---
name: devkit-release-notes
description: >-
  compose a chat-ready release notes post in Russian from real git history since a given date, across one or several project repos. Use for "релиз-ноуты", "что вошло в релиз", "собери релиз с 10.06", "мини-релиз", "release notes since <date>" — anything meant to be pasted into a product/stakeholder chat. Groups changes into emoji-headed product sections, drops internal noise, and always writes Russian regardless of the prompt language. For an English, tag-range, CHANGELOG.md-style document use devkit-changelog-generator instead.
---

# Release Notes (RU)

Turn commits since a date into a short Russian post a product owner can read and paste into a team chat. Group by
product area — not by repo, not by commit.

## Inputs

| Input | Required | Default |
|---|---|---|
| cutoff date | yes | ask if absent; never guess |
| repo roots | no | cwd + every other accessible repo of the same product |
| release branch | no | `origin/HEAD` of each root (`master` / `main` / `production`) |
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
4. **Resolve opaque commits.** Any subject that does not state user-visible impact (`fix`, `wip`, `правки`, a bare
   ticket id) gets a `git show --stat` and, if still unclear, a real diff read. A commit you cannot explain is dropped,
   never guessed.
5. **Filter noise.** Drop dependency bumps, lint/format, CI config, test-only commits, reverts that cancel out, and
   refactors with no behaviour change. Keep infra work only when it changed reliability, deploy, or performance the team
   will notice.
6. **Ask for the non-code part of the release.** Content and data imports, reference-book updates on prod, third-party
   account or config changes, manual prod actions — these ship in the release and leave no commit. Ask once; git cannot
   show them.
7. **Cluster into product sections.** One section per product area (vocabulary and ordering: `references/style.md`). A
   feature that landed in two repos is one line.
8. **Write the post** per `references/style.md`. Russian only.
9. **Flag ops follow-ups.** Anything needing a manual step after deploy — API keys, env vars, migrations, seeders, cron,
   catalog import, third-party account — gets a `⚠️ Важно:` line inside its section.
10. **Verify before delivering.** Every line traceable to a commit, diff, or a non-code item the user confirmed; no SHAs,
    paths or ticket ids leaked; fix-flavoured sections last; Russian throughout. State the roots and range you actually
    read, outside the post.

## Commands

```bash
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
- **Never invent.** No feature the diff does not support. Uncertain → drop it or ask.
- **No engineering residue** in the post: SHAs, file paths, branch names, PR/ticket numbers, class names. Product nouns
  the team already uses (admin section names, URLs, integration names) are fine.
- **One change per line.** No paragraphs, no multi-clause sentences.
- **No preamble, no summary, no «Итого», no evidence block.** The date line and the sections are the whole post.
- **Never group by repo.** The reader neither knows nor cares which repo shipped what.
- Report what you dropped as noise in one line *outside* the post, so the user can object.

## Output

Deliver the post in chat as plain text ready to paste into a messenger. Write a file only when the user asks for one.

Format, section vocabulary, emoji set, and verb forms: `references/style.md`.
