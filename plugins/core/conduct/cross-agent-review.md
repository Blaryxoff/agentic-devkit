# Cross-Agent Review Cross-Check

Shared protocol for any review skill: run the review in the calling agent first, then — only when the caller is Claude Code — cross-check by running the same review in Codex and merging the relevant findings.

## When this applies

Apply in any review skill (deep, fast, business-logic, logging, plan) after it has produced its own findings, and only when **all** of these hold:

1. You are **Claude Code** (not Codex, Cursor, or any other agent).
2. You are the **top-level review invocation** — the skill the user (or a non-review caller) invoked directly. Skip the cross-check when you were dispatched as a subagent/variant by a review orchestrator; return your report to the orchestrator and let it run the cross-check once.
3. The `codex` CLI is available: `command -v codex` succeeds.

If any condition fails, skip the cross-check silently and present only your own findings. Never recurse: when this same skill runs inside Codex, condition 1 is false, so Codex performs a plain native review with no further cross-check.

## Procedure

1. **Run the native review first.** Complete your own findings in full before invoking Codex. The cross-check augments your review; it never replaces it.
2. **Invoke Codex on the same scope, read-only.** Run the same review skill in Codex against the same change set, with no write access:

   ```bash
   codex exec --sandbox read-only --skip-git-repo-check \
     "Use the <codex-skill-slug> skill to review the same scope: <scope description>. \
      Review only — do not modify code. Output findings only, in the devkit review-findings-format \
      (defect type, finding, evidence as file:line, suggested fix), grouped by Blocking/Significant/Minor."
   ```

   - `<codex-skill-slug>` is this skill's Codex symlink under `.codex/skills/` (e.g. `devkit-core--reviewer-fast`). Each skill names its own slug where it cites this protocol.
   - `<scope description>` is the exact thing you reviewed (working-tree diff, branch diff, named files, or the plan document), so both agents review the same thing.
   - If the run fails, times out, or returns nothing, note `Codex cross-check: skipped (unavailable)` and present your own findings unchanged.
3. **Analyze Codex's findings — do not trust them blindly.** For each Codex finding, verify against the actual code before accepting it:
   - **Discard** findings that are duplicates of yours (same `file:line` + same defect), out of scope, unevidenced/speculative, or factually wrong when you check the cited code.
   - **Keep** findings that are valid, evidenced, in scope, and absent from your own list.
4. **Merge the kept findings into your report.** Place each into the matching severity bucket (and matching stack section, for orchestrators). Tag merged findings `(via Codex)` so provenance is visible. Preserve the existing presentation structure — do not collapse separate stack sections or restate the shared format.
5. **State the cross-check outcome** in one line: how many Codex findings were merged and how many discarded (e.g. `Codex cross-check: 2 findings merged, 3 discarded as duplicate/out-of-scope`).
