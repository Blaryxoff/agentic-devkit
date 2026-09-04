---
name: devkit-learn
description: >-
  capture strategic, reusable project knowledge discovered this session into the current harness's native project
  instruction file or an established per-developer/per-checkout equivalent. Use when the user says "learn", "save
  knowledge", "update agents.md", "update claude.md", or "capture learnings", and when the top-level
  terminal learning-capture gate finds a durable candidate. Never trigger merely because a session was long. Never write
  without granular user confirmation.
---

# Learn

> Adapted from `umputun/cc-thingz` (MIT).

Review the session and capture strategic, reusable project knowledge into the current harness's native project
instruction file. This writes **team-shared project memory** committed to the repo. It is separate from harness-provided
personal auto-memory and global cross-repository instructions, which are not the target here.

The skill has two entry paths:

- **Explicit** — the user asks to learn or update project memory.
- **Terminal** — the top-level agent invokes it after candidates pass `plugins/core/conduct/learning-capture-gate.md`.

Terminal invocation is a candidate review, not permission to write. Keep the confirmation step below.

## What qualifies

Capture a discovery only when it gives a fresh agent or developer forward-looking project guidance before a different
future task. Good candidates are:

- stable architecture boundaries, ownership, and project structure
- intentional project conventions or invariants established across the codebase or confirmed by the team
- required integration, testing, build, deployment, or operational workflows not obvious from their canonical files
- non-obvious project-specific constraints that materially change how contributors should approach a class of work

Do not turn the completed task's debugging residue into project instructions. Reject:

- the bug cause, fix, failed approach, or defensive check from the task just completed, even when it affected several files
  or could recur
- framework, language, library, ORM, or serialization behaviour and other transferable technical gotchas
- implementation-level query, matching, parsing, payload, or comparison idioms better expressed by code, a helper, a type,
  or a focused regression test
- temporary state, workarounds, TODOs, historical narrative, speculative conclusions, and facts already documented at
  their canonical source

Apply all of these tests to each candidate:

1. **Different-task test** — would this guide work beyond repeating or revisiting the issue just solved?
2. **Project-contract test** — does it describe an intentional, durable project decision or invariant rather than a
   low-level technical lesson?
3. **Established-evidence test** — is it supported beyond one failure path by multiple project locations, an existing
   workflow, or a confirmed team decision?
4. **Fresh-reader test** — is it actionable without the current session's incident history?
5. **Placement test** — is a project instruction file the best enforcement point, rather than code, tests, types, or
   canonical technical documentation?

If any answer is no, do not propose the candidate. Recurrence prevention alone is insufficient.

## Destinations

- **Native project instruction file** (committed, team-shared) — use the file loaded by the active harness for
  architecture, conventions, integration, and operational knowledge. Project placement guidance and established files
  take precedence. When the project has no established file, use `AGENTS.md` for Codex, `CLAUDE.md` for Claude Code, and
  the documented native project instruction file for another harness.
- **Established local instruction file** (gitignored, personal) — use only when **both** hold: (1) the active harness
  already loads that file in this project, and (2) the discovery is genuinely per-developer or per-checkout state, not a
  team convention that merely mentions a personal path. `CLAUDE.local.md` is one example, not a universal filename.

**Default for ambiguous cases: the active harness's team-shared project instruction file.** Never create or update
another harness's file merely because the skill named it as an example. Leaking personal config into a committed file is
a loud error reviewers catch; hiding project knowledge in a gitignored file rots silently.

This project-memory skill never writes global instructions or personal auto-memory. If the user asks to save a
cross-repository preference, identify the active harness's native global instruction mechanism and explain that it is
outside this skill's scope. Never write memory for the active harness into another harness's global file.

## Workflow

1. **Identify the active harness and placement guidance.** Inspect only its loaded project instruction files, documented
   local equivalents, and native global instruction source. If the project defines a placement decision tree or specific
   destination, follow it instead of the defaults below.
2. **Read existing active-harness memory content** in those locations to avoid duplication. Do not scan or edit another
   harness's files unless the project explicitly declares them canonical for all agents.
3. **Early exit** — if no new strategic knowledge was found, stop without asking the user. For explicit invocation,
   report "no new strategic knowledge to capture"; for terminal invocation, exit silently.
4. **Classify each discovery** to its destination per the rules above.
5. **Limit and consolidate** — keep at most three high-value discoveries. Prefer merging or replacing an existing entry over appending overlapping text.
6. **Present** the discoveries, each tagged with its inferred destination:
   ```markdown
   ## [Section] → project AGENTS.md
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
