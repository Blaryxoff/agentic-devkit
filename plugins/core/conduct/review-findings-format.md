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

Use these shared types as written. Skill-specific taxonomies (for example `RALPHEX FORMAT` in plan-reviewer, `IDEMPOTENCY RISK` in business-logic reviewers) may extend this list.

## Severity buckets

Group findings under these headers, in this order:

1. **Blocking** — the reviewed change is not ready for handoff as written.
2. **Significant** — meaningful non-blocking risk or rework.
3. **Minor** — polish, consistency, or clarity.

Empty buckets may be omitted. If all buckets are empty, state that explicitly plus any residual risks.

## Review completion gate

Apply this gate to static code review. It does not replace terminal conditions owned by browser QA or interactive git
review.

Evaluate the outcome only after every requested reviewer and mandatory cross-agent check has finished. For a full code
review, combine deep and business-logic findings before deciding. If an external reviewer calls a finding `Critical`,
normalize it to **Blocking**. Never promote Significant or Minor findings merely to keep the loop running.

### Significant-finding adjudication

Blocking/Critical findings fail the review. Minor findings remain non-blocking. Assess Significant findings after all retained review
findings are combined:

- Promote a Significant finding to Blocking when it threatens a required acceptance criterion or user flow, security,
  permissions, data integrity, irreversible state, or a broad regression.
- Promote a related cluster of Significant findings when their combined impact makes the change unsafe to hand off.
- Keep a finding Significant when the change remains safe and usable, the impact is limited to a non-critical edge case,
  or the evidence/likelihood does not justify blocking handoff.
- Assess clusters of Significant findings by combined impact; use evidence and risk rather than finding count alone.
- Verify every retained finding against the code before adjudicating it. A review source's severity label is evidence
  for the decision, not the decision itself.

State one line in the final outcome: `Significant gate: pass — <reason>` or
`Significant gate: fail — promoted <finding/cluster> to Blocking because <reason>`.

### Review-only mode — default

Reviewers are read-only. A plain review request runs one complete pass, returns findings and the outcome, and stops.
Require an explicit request to fix or repair findings before editing files. Phrases such as "review until satisfied" or "review until clean" describe review scope and leave the reviewer read-only.

Return issues and the review outcome from a review execution. Keep the reviewer read-only; invoke the coder skill, edit files, or start a repair loop only in a separate workflow after an explicit repair request.

### Explicit repair/recheck mode

Only an explicit request to fix, repair, or implement review findings authorizes a separate repair workflow. The reviewer
itself remains read-only; that workflow must activate the coder skill, repair the authorized severity set, verify, and then
start a fresh complete review pass.

Unless the user defines a different threshold:

- A **pass** means the complete requested review set plus its mandatory cross-checks.
- Run at most **5 complete passes**: the initial pass and up to 4 repair/recheck passes.
- **REVIEW PASSED** — zero Blocking findings remain after Significant adjudication. List Significant and Minor findings
  as non-blocking follow-ups, state that the review passed, and stop immediately.
- **FIX REQUIRED** — Blocking findings remain. Return them as the review result. Repair occurs only outside the reviewer
  and only when explicitly authorized.
- **REVIEW BLOCKED** — stop when pass 5 still has Blocking findings, the same Blocking finding survives two consecutive
  passes without material progress, or an ambiguity/external dependency prevents a safe fix. Report the remaining
  blockers; do not continue automatically.

An explicit user threshold such as "fix Significant too" overrides only the severity threshold, not the 5-pass safety
cap unless the user also explicitly changes the cap.

