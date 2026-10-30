---
name: devkit-estimate
description: >-
  estimate agent-led development elapsed time through handoff for testing, ready for direct paste. Use for "estimate this
  task", "how long will development take", agent-first, agent-only or vibe-coding estimates. Separate attended developer
  hours when requested. Does not manage sprint workbooks or capacity allocation.
---

# Agent-Led Development Estimator

Default to elapsed time for an agent-led implementation from the start of work through focused self-checks and handoff
for testing. Include agent execution, attended review, corrections, and the critical-path test runtime. Track the
developer's occupied hours as a separate metric when requested; agent runtime and passive test runtime cost zero
developer hours. Do not turn the implementation estimate into a date for launch. External QA, fixes found after handoff,
deployment, approvals, and waiting for another party are separate work unless the user asks to estimate them.

## Boundaries

1. Stay read-only unless the user asks for a report file or tracker/workbook update.
2. Keep sprint workbooks, capacity allocation, executor assignment, and numeric task-cell edits outside this workflow.
3. Inspect each repository affected by the requested contract and apply its own instructions.
4. Estimate the literal requested scope. A planned prerequisite owned by another task is a dependency, not hours in this
   estimate. State it briefly when it affects whether development can start.
5. Do not add extra brands, clients, backfills, migrations of existing records, or reusable infrastructure that the task
   does not require. Quote an expansion only when the user asks for it.
6. Treat an explicit stage such as P0 or P1 as its own scope. For a total covering both, count the shared work once and
   show the later stage's incremental hours only when useful.
7. If the user asks for attended developer hours, report them separately from agent-led elapsed time. If the user asks
   for a launch date or broader delivery estimate, keep implementation distinct from later delivery work.

## Workflow

### 1. Fix the development target

Record the requested feature, affected repositories, roles and surfaces, the implementation handoff point, and any
explicit exclusions. Choose the requested metric: agent-led elapsed by default, attended developer hours when explicitly
requested, or both when the comparison matters. Resolve one material ambiguity with scenarios when needed; do not
silently choose a larger scope.
If the user provides an earlier estimate or task link, read its latest scoped figure and later scope decisions before
calculating. A revised figure supersedes earlier comments; never average them.

### 2. Check what exists

Inspect the smallest source and test slices that establish existing behavior, contracts, and the missing change. Check
all refs for recoverable work when history could materially reduce the estimate. Classify each requirement as exact,
continuation, foundation, adjacent, or absent:

- Exact and continuation behavior already delivered costs zero.
- A working foundation reduces setup, but does not prove the new behavior exists.
- Adjacent code proves familiarity, not completion.
- A foundation promised by a separately estimated predecessor is a stated dependency. Do not charge it again.

Do not infer duration from file counts, lines of code, or a single commit timestamp. Use focused checks only when they
change reuse confidence.

### 3. Calibrate against local evidence

Prefer current code, a high-context maintainer's scoped statement, exact prior estimates, and completed local agent-run
analogues over generic productivity claims. A prior estimate is a planning anchor, not measured duration. Use measured
duration only when the record reports comparable scope and start/end points. Keep initial implementation, later defect
fixes, and deployment separate when the record distinguishes them.

Compare the remaining scope with the closest anchor. If a smaller follow-on task takes longer, name the genuinely new
domain rule or integration responsible and recalculate. If no such work exists, remove duplicate time. An analogue's
delivered span is not a floor or an additive allowance. Read the optional
[agent-first calibration](references/agent-first-calibration.md) only when no credible local analogue exists or the user
asks for external evidence.

### 4. Schedule the agent-led critical path

Use one connected implementation lane by default, even when it changes backend, UI, and tests together. Split lanes
only for genuinely independent work with separate human review. Build a small internal ledger of elapsed intervals:

- Clarifying the contract and briefing the coding agent when those steps delay implementation.
- Agent implementation, including tool execution and waits on the critical path.
- Reviewing the result and correcting defects found before handoff.
- Focused automated checks, targeted smoke checks, and preparing the handoff.

Count an interval once when it covers several screens, layers, tests, or agents. For concurrent agents, count the
longest dependency path plus integration, not the sum of their runtimes. Do not add a review or acceptance session per
endpoint, component, role, or requirement. Exclude generic risk buffers, release hardening, deployment, external QA,
and hypothetical fixes after handoff unless requested.

For a separate attended-hours quote, count only the developer's briefing, decisions, active review, correction, and
manual checks. Exclude unattended agent and test runtime from that metric; never substitute it for elapsed time.

Estimate low, likely, and high internally from the elapsed ledger. Default to one likely elapsed-hour figure in the
answer. Show a range only when the user requests it or the uncertainty changes a decision.

### 5. Recheck the number

Verify that every interval belongs to the requested implementation before handoff. Compare with the earlier estimate
and the delivered analogue. When a comparable agent-run anchor exists, use its observed elapsed stages instead of
reconstructing manual coding effort. Without such an anchor, a traditional coding estimate divided by eight is only a
low-confidence starting point for the agent implementation interval; add review, integration, and focused checks from
the actual execution path, and never scale the entire delivery estimate. Recalculate when a user challenges the figure;
identify the duplicated or missing interval and issue corrected figures. Keep confidence at medium or below without a
comparable measured agent-run anchor.

## Chat-ready output

Return only a self-contained message in the user's language, ready to paste to its intended audience. Assume the
recipient has not seen this conversation. Do not start with "I revised the estimate", refer to an earlier answer, or
explain the estimation method unless the user explicitly asks for that context.

Default shape:

Оценка разработки [функции] с агентом до передачи на тестирование:
• P0 — N часов по времени от начала работы до готового результата.
• P0 + P1 — M часов суммарно (P1 добавляет D часов).

Include only stages that the task actually contains. State one material prerequisite on a short final line when needed.
If the recipient needs the scope, add one short sentence describing the user-facing result. Label attended developer
hours separately when requested. Say "до передачи на тестирование", not "до запуска". Do not add calendar days,
deployment, QA cycles, rollout, or a release date by default.
When those activities are explicitly excluded or owned elsewhere, name the boundary once without assigning them
hours. Use no Markdown table, investigation notes, source paths, or links unless the user requests an audit trail or a
destination that needs them. Do not create a report file unless asked.

## Final checks

- The quote stops at implementation with focused self-checks and handoff for testing.
- Agent execution and critical-path waits are included in elapsed time; attended human time is a distinct metric.
- Each review or check is counted once for the connected change.
- Existing work and separately owned prerequisites cost zero in this estimate.
- The number is reconciled with a prior scoped estimate when one exists.
- Any total across stages equals shared work plus incremental stage work, with no duplicate foundation.
- The text can be pasted into a fresh chat without knowledge of this conversation.
- Apply [readiness gate](../../conduct/readiness-gate.md) internally; do not append its table to the answer.
