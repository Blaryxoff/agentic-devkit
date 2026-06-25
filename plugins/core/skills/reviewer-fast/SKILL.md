---
name: devkit-reviewer-fast
description: >-
  orchestrate fast correctness/regressions review across the active stack — dispatches to laravel and frontend variants and presents their reports sequentially. Use only when the user signals speed ("quick review", "fast pass", "быстро глянь", "just regressions"). For a full branch/code review use devkit-reviewer-deep + devkit-reviewer-business-logic; for plan/spec-only changes use devkit-plan-reviewer. Routing policy: plugins/core/conduct/review-routing.md.
---

# Fast reviewer (orchestrator)

You are dispatching a fast review across whatever stacks the project has enabled. This skill does not perform the review itself — it routes to the stack-specific variants.

Fast review focuses on correctness, regressions, and major convention violations. For a thorough architecture/security/performance pass use `devkit-reviewer-deep`. For behavioural-completeness use `devkit-reviewer-business-logic`.

**NEVER change code, ONLY review it.**

---

## Procedure

1. Read `.devkit/toolkit.json` to determine enabled plugins. If absent, detect stack from `composer.json` and `package.json`.
2. Decide which variants apply:
   - **Laravel variant** (`devkit-reviewer-fast-laravel`, at `plugins/laravel/skills/reviewer-fast/SKILL.md`) — when `devkit-laravel` is enabled.
   - **Frontend variant** (`devkit-reviewer-fast-frontend`, at `plugins/frontend/skills/reviewer-fast/SKILL.md`) — when any frontend stack plugin is enabled (`devkit-frontend`, `devkit-nuxt`, `devkit-vue`, `devkit-inertia`).
3. Dispatch the applicable variants. If your harness exposes subagents (e.g. Claude Code's Agent tool with `subagent_type`), invoke each variant as a subagent so its context stays out of this orchestrator's context. When both variants apply, dispatch them **in parallel** in a single tool-call batch and only synthesize after both reports return. If subagents are not available, invoke each variant skill sequentially.
4. Present each variant's report unchanged, under a heading: `## Laravel — Fast review` and `## Frontend — Fast review`. Reports are **sequential and clearly separated** — do not merge findings, do not produce a cross-wire pairing section.
5. **Cross-check in Codex.** Once the variant reports are assembled, run the cross-agent cross-check per `plugins/core/conduct/cross-agent-review.md`, using Codex skill slug `devkit-core--reviewer-fast`. Merge kept findings into the matching stack section, tagged `(via Codex)`. **This step is mandatory when the gate holds** — run `command -v codex`, do not treat it as optional or proportional, and state the gate outcome explicitly. Skip only when a gating condition genuinely fails, naming which.
6. If neither side is active, stop and tell the user no compatible stack plugin is enabled and which plugins this skill supports.

**NEVER change code, ONLY review it.**
