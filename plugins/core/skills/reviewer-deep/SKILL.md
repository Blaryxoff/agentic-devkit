---
name: devkit-reviewer-deep
description: >-
  orchestrate deep code-quality review across the active stack (architecture, security, data correctness, performance) — dispatches to laravel and frontend variants and presents their reports sequentially. Use when the user asks to review code, a code change, or a whole branch ("поревьюй ветку/изменения", "review the branch/code"). Run TOGETHER with devkit-reviewer-business-logic for a full branch/code review. For changes under docs/plans/** use devkit-plan-reviewer; for a quick regression-only pass use devkit-reviewer-fast. Routing policy: plugins/core/conduct/review-routing.md.
---

# Deep reviewer (orchestrator)

You are dispatching a deep code-quality review across whatever stacks the project has enabled. This skill does not perform the review itself — it routes to the stack-specific variants.

Deep review covers architecture, security, data correctness, error handling, performance, and maintainability. For behavioural-completeness use `devkit-reviewer-business-logic`. For a faster, regression-focused pass use `devkit-reviewer-fast`.

**NEVER change code, ONLY review it.**

---

## Procedure

1. Read `.devkit/toolkit.json` to determine enabled plugins. If absent, detect stack from `composer.json` and `package.json`.
2. Decide which variants apply:
   - **Laravel variant** (`devkit-reviewer-deep-laravel`, at `plugins/laravel/skills/reviewer-deep/SKILL.md`) — when `devkit-laravel` is enabled.
   - **Frontend variant** (`devkit-reviewer-deep-frontend`, at `plugins/frontend/skills/reviewer-deep/SKILL.md`) — when any frontend stack plugin is enabled (`devkit-frontend`, `devkit-nuxt`, `devkit-vue`, `devkit-inertia`).
3. Dispatch the applicable variants. If your harness exposes subagents (e.g. Claude Code's Agent tool with `subagent_type`), invoke each variant as a subagent so its large context — walking many files and conduct docs — stays out of this orchestrator's context. When both variants apply, dispatch them **in parallel** in a single tool-call batch and only synthesize after both reports return. If subagents are not available, invoke each variant skill sequentially.
4. Present each variant's report unchanged, under a heading: `## Laravel — Deep review` and `## Frontend — Deep review`. Reports are **sequential and clearly separated** — do not merge findings, do not produce a cross-wire pairing section.
5. **Cross-check in Codex.** Once the variant reports are assembled, run the cross-agent cross-check per `plugins/core/conduct/cross-agent-review.md`, using Codex skill slug `devkit-core--reviewer-deep`. Merge kept findings into the matching stack section, tagged `(via Codex)`. **This step is mandatory when the gate holds** — run `command -v codex`, do not treat it as optional or proportional, and state the gate outcome explicitly. Skip only when a gating condition genuinely fails, naming which.
6. Apply the review completion gate in `plugins/core/conduct/review-findings-format.md` after all requested review skills finish. When paired with business-logic review, wait for both reports before deciding the combined pass outcome.
7. If neither side is active, stop and tell the user no compatible stack plugin is enabled and which plugins this skill supports.

When both variants run, ask the user upfront whether to scope each side to the same change set or audit them independently.

Return findings and the pass outcome. This reviewer never repairs findings or invokes `devkit-coder`.

**NEVER change code, ONLY review it.**
