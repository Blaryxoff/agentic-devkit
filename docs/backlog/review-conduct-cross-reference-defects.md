---
worth: yes
where: plugins/core/conduct/review-findings-format.md:92
added: 2026-09-02
---
# Three cross-reference defects in the review conduct cluster

1. **`review-findings-format.md:92` cites a pattern that does not exist.** The closing line of "Explicit repair/recheck
   mode" — which owns the 5-pass cap and `REVIEW PASSED` / `FIX REQUIRED` / `REVIEW BLOCKED` — says "See
   `plugins/core/skills/plan-reviewer/SKILL.md` (Steps 7–8) for the full pattern." Step 7 is "Produce proposed updates"
   (`:220`), Step 8 is "Readiness assessment" (`:277`); neither mentions passes, a cap, or repair, and Step 8's terminal
   outcomes are `READY FOR HANDOFF` / `UPDATES PROPOSED`. (`readiness-gate.md:34` cites Step 8 correctly.)
2. **`review-gate.md:24-27` restates instead of citing.** "Output requirement" re-encodes two rules
   `review-findings-format.md` owns — severity-ordered findings with file references (`:28-32`) and the "if no issues,
   state that plus residual risks" rule (`:34`, near-verbatim). `review-gate.md` never cites it, so the two can drift.
   `CLAUDE.md:117` forbids exactly this.
3. **`review-routing.md:15-23` has no row for `devkit-reviewer-logging`.** The table claims to pick "the right skill(s)
   when the user asks to review, test, QA, or check a change" and covers plan, code, fast, browser and revmux. Logging
   review is absent, and `review-specialist-fanout.md` does not gate it either — so a skill that ships as a Claude
   subagent is unreachable through the documented routing path.

Related: [[skill-descriptions-without-a-trigger-clause]].
