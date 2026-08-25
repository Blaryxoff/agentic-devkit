---
name: devkit-reviewer-deep
description: >-
  orchestrate deep code-quality review across the active stack (architecture, security, data correctness, performance),
  with risk-gated testing, documentation, and design-reference specialists. Dispatches applicable reviewers in parallel
  and presents reports by axis. Use when the user asks to review code, a code change, or a whole branch. Run TOGETHER with
  devkit-reviewer-business-logic for a full review. Routing policy: plugins/core/conduct/review-routing.md.
---

# Deep reviewer (orchestrator)

You are dispatching a deep code-quality review across whatever stacks the project has enabled. This skill does not perform the review itself — it routes to the stack-specific variants.

Deep review covers architecture, security, data correctness, error handling, performance, and maintainability. For behavioural-completeness use `devkit-reviewer-business-logic`. For a faster, regression-focused pass use `devkit-reviewer-fast`.

When the user named revmux as the review engine, this skill does not run unless they asked for both passes: routing hands that pass to the upstream revmux skill, which replaces this fan-out rather than adding to it (`plugins/core/conduct/revmux-review.md`).

**NEVER change code, ONLY review it.**

---

## Procedure

1. Read `.devkit/toolkit.json` to determine enabled plugins. If absent, detect stack from `composer.json` and `package.json`.
2. Decide which variants apply:
   - **Laravel variant** (`devkit-reviewer-deep-laravel`, at `plugins/laravel/skills/reviewer-deep/SKILL.md`) — when `devkit-laravel` is enabled.
   - **Frontend variant** (`devkit-reviewer-deep-frontend`, at `plugins/frontend/skills/reviewer-deep/SKILL.md`) — when any frontend stack plugin is enabled (`devkit-frontend`, `devkit-nuxt`, `devkit-vue`, `devkit-inertia`).
   - **Generic quality fallback** — for changed code not covered by either active stack variant; use the role defined in
     `plugins/core/conduct/review-specialist-fanout.md`.
3. Resolve the risk-gated testing, documentation, and visual-reference specialists, then dispatch every applicable reviewer per
   `plugins/core/conduct/review-specialist-fanout.md`. For a standalone deep review, this top-level skill owns dispatch.
   For a full review, the top-level session registers applicable business-logic variants and owns one shared dispatch;
   the paired business-logic skill must not dispatch them again. Never rely on a subagent to fan out further.
4. Present reports under separate headings: `## Laravel — Deep review`, `## Frontend — Deep review`,
   `## Core/general — Deep review`, `## Testing`, `## Documentation`, and `## Design-reference fidelity`. Omit unopened
   gates and unused fallbacks. Do not merge different axes.
5. **Cross-check in Codex.** Once the variant reports are assembled, run the cross-agent cross-check per `plugins/core/conduct/cross-agent-review.md`, using Codex skill slug `devkit-core--reviewer-deep`. Merge kept findings into the matching stack or specialist section, tagged `(via Codex)`. **This step is mandatory when the gate holds** — run `command -v codex`, do not treat it as optional or proportional, and state the gate outcome explicitly. Skip only when a gating condition genuinely fails, naming which.
6. Apply the review completion gate in `plugins/core/conduct/review-findings-format.md` after all requested review skills finish. When paired with business-logic review, wait for both reports before deciding the combined pass outcome.
7. Stop only when the complete resolved reviewer set—stack variants, generic fallback, testing, documentation, and
   visual-reference specialist—is empty. Report unavailable stack coverage separately; never discard an open fallback
   or specialist gate.

Use the same requested change set for every axis by default. Ask about independent scopes only when the user names
different targets or the repository layout makes one shared scope ambiguous.

Return findings and the pass outcome. This reviewer never repairs findings or invokes `devkit-coder`.

**NEVER change code, ONLY review it.**
