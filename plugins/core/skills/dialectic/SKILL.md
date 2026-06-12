---
name: devkit-dialectic
description: prove and counter-prove a statement with two opposing analyses run in parallel, then synthesize an objective conclusion verified against the code. Use when the user says "dialectic", "prove/disprove", "stress-test this claim", "is this really true", "argue both sides", or when a claim about the codebase needs bias-free analysis from opposing viewpoints.
---

# Dialectic Analysis

> Adapted from `umputun/cc-thingz` (MIT).

Analyze a statement objectively by gathering evidence for and against it independently, then synthesizing — to eliminate confirmation bias.

## Process

### 1. Launch two opposing analyses in parallel

Run both at once. If your harness exposes subagents (e.g. Claude Code's Agent tool), dispatch both **in a single tool-call batch** so they run concurrently and their context stays out of this session. Do not run them sequentially, and do not run them in the background. If subagents are unavailable, perform both passes yourself, one after the other, without letting the first conclusion anchor the second.

- **Thesis** — find all POSITIVE evidence: what works, supporting facts, proof the statement is TRUE, benefits, strengths.
- **Antithesis** — find all NEGATIVE evidence: problems, risks, anti-patterns, edge cases, proof the statement is FALSE, weaknesses, failure modes, hidden costs.

Both must cite specific `file:line` references when analyzing code.

### 2. Synthesize

Weigh both sides into an objective conclusion:
- where thesis and antithesis agree → strongest signal
- note unresolved tensions
- the goal is truth, not winning either side

### 3. Verify against the code

**Required.** Before presenting the synthesis, read the specific files and lines both sides cited. Confirm the evidence exists, the flow matches the claims, and no context was misread. Revise the synthesis if verification reveals inaccuracies.

## Examples

```
devkit-dialectic this microservice split improves maintainability
devkit-dialectic the connection pool fixes the timeout issue
devkit-dialectic this implementation is thread-safe
devkit-dialectic review the changes in <file>
```

## Principles

- **Eliminate confirmation bias** — examining both sides at once prevents anchoring.
- **Evidence-based** — cite files, lines, facts; not general claims.
- **Verification required** — check the synthesis against actual code before presenting.
- **Objective conclusion** — truth over either side.
