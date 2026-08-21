---
name: devkit-reviewer-business-logic
description: >-
  orchestrate behavioural-completeness / business-rule-correctness review across the active stack — dispatches to laravel and frontend variants and presents their reports sequentially. Run alongside devkit-reviewer-deep when reviewing code or a whole branch ("поревьюй ветку/изменения", "review the branch/code") — the two cover different axes and should both run for a full code review. Routing policy: plugins/core/conduct/review-routing.md.
---

# Business-logic reviewer (orchestrator)

You are dispatching a behavioural-completeness review across whatever stacks the project has enabled. This skill does not perform the review itself — it routes to the stack-specific variants.

This is **complementary** to `devkit-reviewer-deep` and `devkit-reviewer-fast`. Those cover code quality. This one covers entity-lifecycle and user-flow completeness.

When the user named revmux as the review engine, this skill does not run unless they asked for both passes: routing hands that pass to the upstream revmux skill, which replaces this fan-out rather than adding to it (`plugins/core/conduct/revmux-review.md`).

**NEVER change code, ONLY review it.**

---

## Procedure

1. Read `.devkit/toolkit.json` to determine enabled plugins. If absent, detect stack from `composer.json` and `package.json`.
2. Decide which variants apply:
   - **Laravel variant** (`devkit-reviewer-business-logic-laravel`, at `plugins/laravel/skills/reviewer-business-logic/SKILL.md`) — when `devkit-laravel` is enabled.
   - **Frontend variant** (`devkit-reviewer-business-logic-frontend`, at `plugins/frontend/skills/reviewer-business-logic/SKILL.md`) — when any frontend stack plugin is enabled (`devkit-frontend`, `devkit-nuxt`, `devkit-vue`, `devkit-inertia`).
   - **Generic implementation fallback** — for changed behavior not covered by either active stack variant; use the role
     defined in `plugins/core/conduct/review-specialist-fanout.md`.
3. When this is a standalone business-logic review, dispatch the applicable variants and fallback per
   `review-specialist-fanout.md`. When paired with deep review for a full review, register them with the shared top-level
   fan-out and do not dispatch them independently.
4. Present each variant's report unchanged, under a heading: `## Laravel — Business-logic review` and `## Frontend — Business-logic review`. Reports are **sequential and clearly separated** — do not merge findings, do not produce a cross-wire pairing section.
5. **Cross-check in Codex.** Once the variant reports are assembled, run the cross-agent cross-check per `plugins/core/conduct/cross-agent-review.md`, using Codex skill slug `devkit-core--reviewer-business-logic`. Merge kept findings into the matching stack section, tagged `(via Codex)`. **This step is mandatory when the gate holds** — run `command -v codex`, do not treat it as optional or proportional, and state the gate outcome explicitly. Skip only when a gating condition genuinely fails, naming which.
6. Apply the review completion gate in `plugins/core/conduct/review-findings-format.md` after all requested review skills finish. When paired with deep review, wait for both reports before deciding the combined pass outcome.
7. Stop only when no stack variant or generic implementation fallback applies. Report unavailable stack coverage
   separately from the review outcome.

Use the same requested entity/flow set for every stack by default. Ask about independent scopes only when the user names
different targets or the repository layout makes one shared scope ambiguous.

Return findings and the pass outcome. This reviewer never repairs findings or invokes `devkit-coder`.

**NEVER change code, ONLY review it.**
