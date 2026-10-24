---
name: devkit-reviewer-fast
description: >-
  orchestrate a fast correctness/regressions review across the active stack. Use only when the user signals
  speed — "quick review", "fast pass", "быстро глянь", "just regressions". For a full branch/code review use
  devkit-reviewer-deep + devkit-reviewer-business-logic; for changes under docs/plans/** use
  devkit-plan-reviewer.
---

# Fast reviewer (orchestrator)

Routing policy — which review skill owns which target, and when several must run together: `plugins/core/conduct/review-routing.md`.

You are dispatching a fast review across whatever stacks the project has enabled. This skill does not perform the review itself — it routes to the stack-specific variants.

Fast review focuses on correctness, regressions, and major convention violations. For a thorough architecture/security/performance pass use `devkit-reviewer-deep`. For behavioural-completeness use `devkit-reviewer-business-logic`.

When the user named revmux as the review engine, this skill does not run unless they asked for both passes: routing hands that pass to the upstream revmux skill, which replaces this fan-out rather than adding to it (`plugins/core/conduct/revmux-review.md`).

Return review findings and the pass outcome; leave code unchanged.

---

## Procedure

1. Resolve enabled plugins, transitive dependencies, and changed responsibilities under `plugins/core/conduct/reviewer-dispatch.md`.
2. Discover applicable `reviewer-fast` capabilities from those plugins' declared skill directories and frontmatter. Select only the responsibility owners, and add the generic quality fallback for uncovered scope; keep framework names and APIs in plugin conduct.
3. Dispatch the resolved reviewers, generic fallback, and opened specialist. If your harness exposes subagents (e.g. Claude Code's Agent tool with `subagent_type`), invoke each as a subagent so its context stays out of this orchestrator's context. Dispatch them **in parallel** in a single tool-call batch and only synthesize after all reports return. If subagents are not available, invoke each sequentially.
4. Present each resolved stack/responsibility report, generic fallback, and opened specialist under its own named heading. Keep quality and behavioral axes separate; omit unopened gates and unused fallbacks.
5. **Cross-check in Codex.** Once the variant reports are assembled, run the cross-agent cross-check per `plugins/core/conduct/cross-agent-review.md`, using Codex skill slug `devkit-core--reviewer-fast`. Merge kept findings into the matching stack section, tagged `(via Codex)`. **This step is mandatory when the gate holds** — the gate requires Claude Code or Cursor Agent, so when this skill runs inside Codex it is closed and you review natively without a cross-check. Otherwise run `command -v codex`, do not treat it as optional or proportional, and state the gate outcome explicitly. Skip only when a gating condition genuinely fails, naming which.
6. Apply the review completion gate in `plugins/core/conduct/review-findings-format.md` to the combined current pass.
7. Stop only when the resolved reviewer, fallback, and specialist set is empty. Report unavailable capabilities separately; do not discard uncovered scope that a generic role can review.

Return findings and the pass outcome. Leave fixes to a separate implementation request under `devkit-coder`.
