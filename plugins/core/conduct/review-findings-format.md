# Review Findings Format

Shared output format for any skill that produces review findings (reviewers, auditors, plan checks, security spot-checks, PR triage).

## When this applies

Apply whenever a skill emits a list of issues, defects, mismatches, or gaps the user is expected to act on.

## Per-finding template

```
[DEFECT TYPE] <short title>
Finding: <what is wrong or missing>
Evidence: <file:line, plan section, conduct rule, or external source>
Suggested fix: <concrete change, ready to apply>
```

Every finding must cite evidence. A finding without evidence is a guess and must be reframed as a question via the clarification protocol.

## Defect types

`MISSING` | `VAGUE` | `INCONSISTENT` | `STALE` | `FORBIDDEN` | `STACK MISMATCH` | `SECURITY` | `REGRESSION` | `DUPLICATION` | `PERFORMANCE`

Skill-specific taxonomies (for example `RALPHEX FORMAT` in plan-reviewer, `IDEMPOTENCY RISK` in business-logic reviewers) may extend this list. Do not rename or drop the shared types.

## Severity buckets

Group findings under these headers, in this order:

1. **Blocking** — output is not ready for handoff as written.
2. **Significant** — usable only with reviewer assumptions or rework.
3. **Minor** — polish, consistency, or clarity.

Empty buckets may be omitted. If all buckets are empty, state that explicitly plus any residual risks.

See `plugins/core/skills/plan-reviewer/SKILL.md` (Steps 7–8) for the full pattern.
