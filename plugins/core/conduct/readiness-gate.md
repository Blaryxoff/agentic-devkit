# Readiness Gate

Shared self-check any skill must pass before declaring its output ready for handoff.

## When this applies

Apply at the end of any skill that produces a deliverable the user will act on (plan, review, design, implementation, test cases, audit report).

## Required gate

Fill in this table before declaring done. Mark each ✅ or ❌, with a one-line note.

| Gate                | Question                                                                          |
|---------------------|-----------------------------------------------------------------------------------|
| Scope clarity       | Are in-scope and out-of-scope boundaries explicit?                                |
| Inputs grounded     | Were all required inputs read (see `inputs-grounding-gate.md`)?                   |
| Evidence cited      | Does every non-trivial claim or finding cite a file, line, plan, or conduct rule? |
| Open questions      | Are all blocking ambiguities resolved (see `clarification-protocol.md`)?          |
| Conduct compliance  | Does the output respect rules from active plugin conduct docs?                    |
| Output format       | For reviewers: does the output follow `review-findings-format.md`?                |

If any gate is ❌, the output is **not ready**. Either fix it, ask the user, or surface the failing gate explicitly in the result.

Skills with their own richer rubric (for example plan-reviewer's quality bar) extend this gate; they do not replace it.

See `plugins/core/skills/plan-reviewer/SKILL.md` (Step 8) for the full pattern.
