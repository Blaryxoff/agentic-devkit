---
name: devkit-reviewer-business-logic
description: >-
  orchestrate behavioural-completeness and business-rule-correctness review across the active stack. Run
  alongside devkit-reviewer-deep when reviewing code or a whole branch ("поревьюй ветку/изменения", "review the
  branch/code") — the two cover different axes and should both run for a full code review.
---

# Business-logic reviewer (orchestrator)

Routing policy — which review skill owns which target, and when several must run together: `plugins/core/conduct/review-routing.md`.

You are dispatching a behavioural-completeness review across whatever stacks the project has enabled. This skill does not perform the review itself — it routes to the stack-specific variants.

This is **complementary** to `devkit-reviewer-deep` and `devkit-reviewer-fast`. Those cover code quality. This one covers entity-lifecycle and user-flow completeness.

When the user named revmux as the review engine, revmux replaces this fan-out; run this skill only when they asked for both passes (`plugins/core/conduct/revmux-review.md`).

Return review findings and the pass outcome; leave fixes to a separate implementation request under `devkit-coder`.

---

## Procedure

1. Resolve enabled plugins, transitive dependencies, and changed responsibilities under `plugins/core/conduct/reviewer-dispatch.md`.
2. Discover applicable `reviewer-business-logic` capabilities from those plugins' declared skill directories and frontmatter. Select only the responsibility owners, and add the **Generic implementation fallback** for uncovered scope; keep framework names and APIs in plugin conduct.
3. When this is a standalone business-logic review, resolve the visual-reference specialist gate, then dispatch the
   applicable variants, fallback, and opened specialist per
   `review-specialist-fanout.md`. When paired with deep review for a full review, register them with the shared top-level
   fan-out and do not dispatch them independently.
4. Present each resolved stack/responsibility report, generic fallback, and opened specialist under its own named heading. Keep quality and behavioral axes separate; omit unopened gates and unused fallbacks.
5. **Cross-check with the selected peer.** Once the variant reports are assembled, follow `plugins/core/conduct/cross-agent-review.md`. Resolve the review skill from the peer's catalog or supply the same self-contained brief. Merge kept findings into the matching stack section, tagged `(via <peer>)`. This step is mandatory when the gate holds; state the gate outcome, naming any failed condition.
6. Apply the review completion gate in `plugins/core/conduct/review-findings-format.md` after all requested review skills finish. When paired with deep review, wait for both reports before deciding the combined pass outcome.
7. Stop only when no stack variant, generic implementation fallback, or visual-reference specialist applies. Report
   unavailable stack coverage separately from the review outcome.

Use the same requested entity/flow set for every stack by default. Ask about independent scopes only when the user names
different targets or the repository layout makes one shared scope ambiguous.

Return findings and the pass outcome. Leave repairs to a separate implementation request under `devkit-coder`.
