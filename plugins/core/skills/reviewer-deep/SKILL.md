---
name: devkit-reviewer-deep
description: >-
  orchestrate deep code-quality review across the active stack — architecture, security, data correctness,
  performance, with risk-gated testing, documentation and design-reference specialists. Use when the user asks
  to review code, a code change, or a whole branch. Run TOGETHER with devkit-reviewer-business-logic for a full
  review.
---

# Deep reviewer (orchestrator)

Routing policy — which review skill owns which target, and when several must run together: `plugins/core/conduct/review-routing.md`.

You are dispatching a deep code-quality review across whatever stacks the project has enabled. This skill does not perform the review itself — it routes to the stack-specific variants.

Deep review covers architecture, security, data correctness, error handling, performance, and maintainability. For behavioural-completeness use `devkit-reviewer-business-logic`. For a faster, regression-focused pass use `devkit-reviewer-fast`.

When the user named revmux as the review engine, this skill does not run unless they asked for both passes: routing hands that pass to the upstream revmux skill, which replaces this fan-out rather than adding to it (`plugins/core/conduct/revmux-review.md`).

Return review findings and the pass outcome; leave fixes to a separate implementation request under `devkit-coder`.

---

## Procedure

1. Resolve enabled plugins, transitive dependencies, and changed responsibilities under `plugins/core/conduct/reviewer-dispatch.md`.
2. Discover applicable `reviewer-deep` capabilities from those plugins' declared skill directories and frontmatter. Select only the responsibility owners, and add the **Generic quality fallback** for uncovered scope; keep framework names and APIs in plugin conduct.
3. Resolve the risk-gated testing, documentation, and visual-reference specialists, then dispatch every applicable reviewer per
   `plugins/core/conduct/review-specialist-fanout.md`. For a standalone deep review, this top-level skill owns dispatch.
   For a full review, the top-level session registers applicable business-logic variants and owns one shared dispatch;
   the paired business-logic skill must not dispatch them again. Never rely on a subagent to fan out further.
4. Present each resolved stack/responsibility report, generic fallback, and opened specialist under its own named heading. Keep quality and behavioral axes separate; omit unopened gates and unused fallbacks.
5. **Cross-check in Codex.** Once the variant reports are assembled, run the cross-agent cross-check per `plugins/core/conduct/cross-agent-review.md`, using Codex skill slug `devkit-core--reviewer-deep`. Merge kept findings into the matching stack or specialist section, tagged `(via Codex)`. **This step is mandatory when the gate holds** — the gate requires Claude Code or Cursor Agent, so when this skill runs inside Codex it is closed and you review natively without a cross-check. Otherwise run `command -v codex`, do not treat it as optional or proportional, and state the gate outcome explicitly. Skip only when a gating condition genuinely fails, naming which.
6. Apply the review completion gate in `plugins/core/conduct/review-findings-format.md` after all requested review skills finish. When paired with business-logic review, wait for both reports before deciding the combined pass outcome.
7. Stop only when the complete resolved reviewer set—stack variants, generic fallback, testing, documentation, and
   visual-reference specialist—is empty. Report unavailable stack coverage separately; never discard an open fallback
   or specialist gate.

Use the same requested change set for every axis by default. Ask about independent scopes only when the user names
different targets or the repository layout makes one shared scope ambiguous.

Return findings and the pass outcome. Leave repairs to a separate implementation request under `devkit-coder`.
