# Risk Probe Gate

## When

End of any review or post-implementation verification.

## Probes

Each probe has a **role** (a perspective to adopt) and an **output contract** (the slots that must be filled). Vague answers fail the contract.

### A. First-break

Role: **senior engineer asked what will break first in a real-world app with real users**.

Output (one entry):
- `Trigger:` what makes it happen (load spike, retry storm, malformed input, slow dependency, …)
- `Actor:` who triggers it (specific user role, client, scheduled job, webhook source)
- `Failure:` the user-visible or system-visible symptom
- `Why first:` why this beats every other candidate failure

### B. Chaos

Role: **chaotic user (or chaotic client/operator for backend) interacting with this code**. Examples: rapid double-submit, refresh mid-mutation, two tabs racing the same record, offline then reconnect, webhook replay after timeout, retry storm, clock skew.

Output (≥3 entries):
- `Case:` the interaction sequence in concrete terms
- `Status:` `covered (file:line)` | `missing` | `n/a (reason)`
- `Fix:` for every `missing`, the smallest change that closes it

### C. User-assumption

Role: **first-time user of this UI who has never seen the product**. Find every place that assumes prior knowledge.

Output (one entry per surface, or `n/a — no UI`):
- `Location:` file:line or screen name
- `Assumption:` what the UI expects the user to already know
- `Missing affordance:` the label, copy, empty-state hint, error recovery, or next-step CTA that would remove the assumption

## Output block

Append to findings:

```md
## Risk Probes
### A. First-break
- Trigger: …; Actor: …; Failure: …; Why first: …
### B. Chaos
- Case: …; Status: …; Fix: …
### C. User-assumption
- Location: …; Assumption: …; Missing affordance: …
```

## Severity

- Unhandled first-break: **Blocking**.
- Missing chaos case with data-loss or security impact: **Blocking**. UX-only: **Significant**.
- Blocked / empty / error state with no next action: **Significant**.

## Fail conditions

The probe is invalid if any of:
- A slot is left blank or filled with hedging ("could", "might fail", "various").
- Probe A names a category instead of a scenario ("the API", "the database").
- Probe B has fewer than 3 entries when the change is non-trivial, or any `missing` lacks a `Fix:`.
- Probe C is skipped on a UI change without `n/a — no UI` justification.
- Code is in scope but no entry cites file:line.
