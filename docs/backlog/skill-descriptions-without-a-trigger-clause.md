---
worth: yes
where: plugins/core/skills/reviewer-logging/SKILL.md:3
added: 2026-09-02
---
# Three skill descriptions state what the skill does but never when to invoke it

`CLAUDE.md:127` requires `description` to "be specific about *when* to invoke… Include the inputs/outputs and the
situations that skip the skill." Three skills state only what they do, at ~95-105 chars against a 250-800 char norm
across the catalog:

- `plugins/core/skills/git/SKILL.md:3` — "enforce git workflow conventions for the current team…"
- `plugins/core/skills/babysit/SKILL.md:3` — "keep a PR merge-ready by triaging comments…"
- `plugins/core/skills/reviewer-logging/SKILL.md:3` — "review code for logging standards…"

`devkit-reviewer-logging` compounds it: nothing in `review-routing.md`, `review-specialist-fanout.md`, or
`reviewer-deep/SKILL.md` mentions logging, so its description is the *only* route to it. The four dispatched reviewer
variants share the shape but their orchestrators name them explicitly, so the cost is lower.

Fix: append a trigger clause to each, following `devkit-wrapup` / `devkit-clarify`. E.g. `devkit-git`: `… Use when the
user asks to branch, commit, open a PR/MR, or tag a release. Does NOT review code.`

Related: [[review-conduct-cross-reference-defects]].
