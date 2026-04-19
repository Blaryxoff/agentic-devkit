# Inputs Grounding Gate

Shared rule for any skill that produces analysis, plans, reviews, or implementation: ground in real inputs before producing output.

## When this applies

Apply at the start of every skill that depends on project context (planners, reviewers, coders, testers, auditors, build/guard skills).

## Required steps

1. **Enumerate inputs** the skill depends on. Typical inputs:
    - active product/dev plan in `docs/plans/`
    - `.devkit/toolkit.json` and the `conduct/` directory of every enabled plugin
    - `database/schema.snapshot.json` when database structure matters
    - the source files, tests, or routes being changed or reviewed
    - a Figma node, design token file, or visual baseline when UI is involved
    - test-case documents when implementing tests
2. **Read each input** before forming output. Do not infer structure, naming, or behaviour without reading.
3. **Stop on missing required input.** If a required input is absent, tell the user what to produce (and which skill produces it) instead of guessing.

## Forbidden

- Inventing file paths, column names, route names, or behaviour not present in the inputs.
- Treating "the file probably exists" or "the convention is probably X" as grounded.
- Continuing past a missing input by writing `TBD` or a placeholder.

See `plugins/core/skills/plan-reviewer/SKILL.md` (Steps 2 and 3.5–3.6) for the full pattern and `plugins/core/conduct/research-first.md` for the implementation-side counterpart.
