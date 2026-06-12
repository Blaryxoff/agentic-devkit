---
name: devkit-learn
description: capture strategic, reusable project knowledge discovered this session into the project CLAUDE.md (or CLAUDE.local.md when the discovery is per-developer/per-checkout and that file already exists). Use when the user says "learn", "save knowledge", "update claude.md", "capture learnings", or at the end of a significant work session. Writes team-shared project memory — distinct from your personal cross-session auto-memory (MEMORY.md), which it never touches.
---

# Learn

> Adapted from `umputun/cc-thingz` (MIT).

Review the session and capture strategic, reusable project knowledge into the project's `CLAUDE.md`. This writes **team-shared project memory** committed to the repo — it is a separate mechanism from your personal `MEMORY.md` auto-memory (which captures per-user cross-session facts and is not the target here).

## What qualifies

**INCLUDE** — strategic, reusable discoveries:
- architecture patterns and project structure insights gained while navigating
- conventions noticed across multiple files
- integration patterns, configuration approaches, testing strategies
- build/deployment processes, performance/security implementations
- operational knowledge: env-specific quirks, useful debugging queries, log/monitoring locations, deployment commands

**EXCLUDE** — session-specific tactical work:
- the specific bug fixed or feature implemented
- temporary workarounds, one-off changes, TODOs
- historical context about the changes themselves

Decision test for each discovery: *Will this help understand the project in 6 months? Does it appear multiple times? Is it a project-wide convention? Would it save future debugging time?*

## Destinations

- **`CLAUDE.md`** (committed, team-shared) — the default for architecture, conventions, integration, operational knowledge.
- **`CLAUDE.local.md`** (gitignored, personal) — only when **both** hold: (1) the file already exists, and (2) the discovery is genuinely per-developer / per-checkout state, not a team convention that merely mentions a personal path.

**Default for ambiguous cases: project `CLAUDE.md`.** Leaking personal config into a committed file is a loud error reviewers catch; hiding project knowledge in a gitignored file rots silently.

This skill never writes to the user's global `~/.claude/CLAUDE.md` and never writes to `MEMORY.md` — it only reads them to avoid duplicating already-captured knowledge.

## Workflow

1. **Check for project memory-placement guidance.** Scan the project `CLAUDE.md`, any `.claude/rules/*.md`, and global `~/.claude/CLAUDE.md` for documented placement rules (a decision tree, a triage command, specific destinations). If found, defer to it instead of the defaults below.
2. **Read existing memory content** (`CLAUDE.md`, `CLAUDE.local.md` if present, global `~/.claude/CLAUDE.md`, and `MEMORY.md`) to avoid duplication.
3. **Early exit** — if no new strategic knowledge was found, report "no new strategic knowledge to capture" and stop. Do not call `AskUserQuestion`.
4. **Classify each discovery** to its destination per the rules above.
5. **Present** the discoveries, each tagged with its inferred destination:
   ```markdown
   ## [Section] → project CLAUDE.md
   - Discovery 1
   ```
6. **Confirm via `AskUserQuestion`** — granular selection: first option "All", last "None", middle options the 2–3 most significant items (each labelled with its destination). Save per the selection; "Other" lets the user pick which items, but does not redirect destinations.

## Guidelines

- Capture only genuinely new discoveries; don't duplicate existing memory.
- Focus on patterns observed, not specific code written.
- Keep entries concise and actionable.
- Defer to any project/user memory-placement guidance found in step 1.
