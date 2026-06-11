---
name: devkit-changelog-generator
description: turn git history into concise human-facing changelogs or release notes for the current project. Use when asked for "what changed", release notes, weekly/monthly update summaries, PR/MR summaries, or customer-readable changelog entries. Reads real git commits/diffs/tags; filters internal noise; does not invent product impact.
---

# Changelog Generator

You are converting **real repository history** into a useful changelog. Your job is not to dump commits; your job is to explain what changed in language a maintainer, teammate, or customer can act on.

## Workflow

1. **Resolve the range.** Prefer an explicit user range (`v1.2.0..HEAD`, dates, branch comparison). If absent, inspect tags and recent history, then state the chosen range.
2. **Collect evidence.** Use `git log`, `git diff --stat`, and targeted diffs for unclear commits. Do not rely on commit titles alone.
3. **Group changes.** Use only categories that have real content:
   - Features
   - Improvements
   - Fixes
   - Security / privacy
   - Breaking changes / migrations
   - Internal only
4. **Translate carefully.** Convert technical commits into user-facing impact, but keep uncertainty visible. If the impact is not clear from code/history, say so instead of making it up.
5. **Filter noise.** Collapse dependency bumps, formatting, generated files, lockfile churn, test-only changes, and refactors unless they matter to users or release risk.
6. **Call out risk.** Mention migrations, config changes, env changes, permissions, queues, cron, external APIs, and deployment notes.

## Commands

Use a narrow range when possible:

```bash
git status --short --branch
git tag --sort=-creatordate | head -20
git log --oneline --decorate --no-merges <range>
git diff --stat <range>
git diff --name-only <range>
```

For suspicious commits:

```bash
git show --stat --oneline <sha>
git show --name-only --format=fuller <sha>
```

## Output format

```markdown
# Changelog: <range or dates>

## Summary
<2-4 bullets with the actual product/project impact.>

## Added
- ...

## Changed
- ...

## Fixed
- ...

## Deployment notes
- ...

## Internal / omitted noise
- <briefly list collapsed internal-only work, if relevant>

## Evidence
- Range: `<range>`
- Commits reviewed: <N>
- Files touched: <N or short stat>
```

Keep it concise. If the user asked for customer-facing release notes, omit internal evidence unless they ask for it.

## Hard rules

- Never fabricate features from vague commit messages.
- Never include raw SHA spam unless the user asks for audit detail.
- Do not claim a bug is fixed unless the diff or tests support it.
- If the repo is dirty, separate committed history from uncommitted work.
- If tags are missing or weird, say which fallback range you used.
