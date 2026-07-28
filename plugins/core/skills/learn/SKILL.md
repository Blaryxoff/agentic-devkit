---
name: devkit-learn
description: >-
  capture strategic, reusable project knowledge discovered this session into project CLAUDE.md (or CLAUDE.local.md for
  existing per-developer/per-checkout memory). Use when the user says "learn", "save knowledge", "update claude.md", or
  "capture learnings", and when the top-level terminal learning-capture gate finds a durable candidate. Never trigger
  merely because a session was long. Never write without granular user confirmation.
---

# Learn

> Adapted from `umputun/cc-thingz` (MIT).

Review the session and capture strategic, reusable project knowledge into the project's `CLAUDE.md`. This writes **team-shared project memory** committed to the repo — it is a separate mechanism from your personal `MEMORY.md` auto-memory (which captures per-user cross-session facts and is not the target here).

The skill has two entry paths:

- **Explicit** — the user asks to learn or update project memory.
- **Terminal** — the top-level agent invokes it after candidates pass `plugins/core/conduct/learning-capture-gate.md`.

Terminal invocation is a candidate review, not permission to write. Keep the confirmation step below.

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
- ordinary framework/tool knowledge and facts already documented at their canonical source
- speculative conclusions or unconfirmed environment state

Decision test for each discovery: *Will this help understand the project in 6 months? Does it appear multiple times? Is it a project-wide convention? Would it save future debugging time?*

## Destinations

- **`CLAUDE.md`** (committed, team-shared) — the default for architecture, conventions, integration, operational knowledge.
- **`CLAUDE.local.md`** (gitignored, personal) — only when **both** hold: (1) the file already exists, and (2) the discovery is genuinely per-developer / per-checkout state, not a team convention that merely mentions a personal path.

**Default for ambiguous cases: project `CLAUDE.md`.** Leaking personal config into a committed file is a loud error reviewers catch; hiding project knowledge in a gitignored file rots silently.

This skill never writes to the user's global `~/.claude/CLAUDE.md` and never writes to `MEMORY.md` — it only reads them to avoid duplicating already-captured knowledge.

## Workflow

1. **Check for project memory-placement guidance.** Scan the project `CLAUDE.md`, any `.claude/rules/*.md`, and global `~/.claude/CLAUDE.md` for documented placement rules (a decision tree, a triage command, specific destinations). If found, defer to it instead of the defaults below.
2. **Read existing memory content** (`CLAUDE.md`, `CLAUDE.local.md` if present, global `~/.claude/CLAUDE.md`, and `MEMORY.md`) to avoid duplication.
3. **Early exit** — if no new strategic knowledge was found, stop without asking the user. For explicit invocation,
   report "no new strategic knowledge to capture"; for terminal invocation, exit silently.
4. **Classify each discovery** to its destination per the rules above.
5. **Limit and consolidate** — keep at most three high-value discoveries. Prefer merging or replacing an existing entry over appending overlapping text.
6. **Present** the discoveries, each tagged with its inferred destination:
   ```markdown
   ## [Section] → project CLAUDE.md
   - Discovery 1
   ```
7. **Confirm with the user** — use the environment's structured question tool when available; otherwise ask a concise
   confirmation question and wait. Offer granular selection: first option "All", last "None", and middle options for the
   2–3 most significant items, each labelled with its destination. Save only the selected items. A free-form response may
   select items, but never redirects their destinations.

## Guidelines

- Capture only genuinely new discoveries; don't duplicate existing memory.
- Focus on patterns observed, not specific code written.
- Keep entries concise and actionable.
- Never treat terminal invocation as permission to write; confirmation is mandatory.
- Defer to any project/user memory-placement guidance found in step 1.
