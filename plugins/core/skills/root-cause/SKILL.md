---
name: devkit-root-cause
description: >-
  diagnose errors, build/test failures, performance or integration problems, and unexpected behaviour. Use for
  bug investigations, "it's not working", or an unexplained expectation/behaviour mismatch. Establish the cause
  from evidence before fixing; an investigation-only request does not authorise edits.
---

# Root Cause Investigator

> Adapted from `umputun/cc-thingz` (MIT). Bundled paths resolve under the devkit clone root (`~/.claude/agentic-devkit`).

## Investigate

1. Establish the expected and observed behaviour, reproduction, affected environment and recent changes. Check the
   actual code, configuration and runtime state; treat a defect, misleading documentation and a mistaken expectation
   as possibilities until evidence distinguishes them.
2. Separate observations from hypotheses. Trace the failing path and test competing explanations with the smallest
   useful log, query, source slice or reproducible probe. Check version history when it helps locate the regression.
3. Follow the causal chain as far as the evidence supports, including contributing factors and state ownership.
   Use successive "why" questions when useful; do not invent process or architecture causes to fill five levels.
   After repeated failed fixes or a rejected approach, apply
   [Reassess repeated failures](../../conduct/verification-loop.md#reassess-repeated-failures).
4. Report the supported cause and its evidence, distinguish remaining uncertainty, and identify the smallest
   correction or next discriminating check. For an expectation mismatch, explain the expected and actual behaviour
   plainly with source references; do not assume user error or impose a fixed report template.

## Continue within the requested scope

Keep an investigation-only or explanatory request read-only. When the user already requested a fix, continue through
`devkit-coder` after establishing the cause; preserve that authorisation without adding another approval or handoff.
Ask only when a material decision, missing prerequisite or destructive action needs the user's input under
[clarification-protocol.md](../../conduct/clarification-protocol.md).

## References

Load only the resource needed for the current investigation:

- [patterns.md](references/patterns.md) — configuration, races, resource exhaustion, integration and build/deploy causes.
- [techniques.md](references/techniques.md) — log analysis, code tracing, dependencies and environment probes.
