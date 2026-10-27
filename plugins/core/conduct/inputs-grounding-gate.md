# Inputs Grounding Gate

Shared rule for any skill that produces analysis, plans, reviews, or implementation: ground in real inputs before producing output.

## When this applies

Apply at the start of every skill that depends on project context (planners, reviewers, coders, testers, auditors, build/guard skills).

## Required steps

1. **Enumerate inputs** the skill depends on. Typical inputs:
    - supplied task/specification, complete relevant discussion, attachments, dated amendments, and accepted deviations; use an active product/dev plan when supplied
    - `.devkit/toolkit.json` and the risk-matched conduct selected through enabled plugin indexes
    - `database/schema.snapshot.json` when database structure matters
    - the source files, tests, or routes being changed or reviewed
    - a Figma node, design token file, or visual baseline when UI is involved
    - test-case documents when implementing tests
2. **Read the relevant inputs** before forming expectations. Follow the project's tracker access and pagination rules; identify inaccessible attachments or incomplete discussions. A supplied task can establish the contract without a separate plan document.
3. **Resolve requirement provenance.** For changed behavior, record criterion, source/version/date, expected outcome, applicable actors/surfaces, and any superseded decision or conflict. Establish a decision's authority before using it to replace an earlier requirement; recency alone is insufficient. Keep the ledger compact and reuse it across review and QA.
4. **Separate requirements from execution evidence.** Code identifies implementation; it does not establish intended business behavior. A report edit or another agent's summary is not a new run. Preserve the original method, run/build, and evidence limits; runtime reuse follows `runtime-qa-evidence.md`.
5. **Isolate missing inputs.** Continue independent evidence-backed analysis and label code-inferred findings. Mark affected criteria unverified and request only the missing decision/source that changes the result. Do not claim behavioral acceptance or perform a dependent mutation with an unknown contract. Ask for a new document only when existing authorized sources cannot establish the requirement.

## Forbidden

- Inventing file paths, column names, route names, or behaviour not present in the inputs.
- Treating "the file probably exists" or "the convention is probably X" as grounded.
- Replacing a missing expected outcome with `TBD`, a guessed assertion, or a passing result.

See `plugins/core/skills/plan-reviewer/SKILL.md` (Steps 2 and 3.5–3.6) for the full pattern and `plugins/core/conduct/research-first.md` for the implementation-side counterpart.
