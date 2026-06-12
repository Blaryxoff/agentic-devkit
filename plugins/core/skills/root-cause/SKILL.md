---
name: devkit-root-cause
description: systematic root-cause analysis for errors, bugs, and unexpected behaviour using 5-Why methodology — drill from symptom to fundamental cause before proposing any fix. Use when the user reports errors, build/test failures, performance degradation, integration problems, or any "it's not working" scenario. Investigation only; it does not write the fix.
---

# Root Cause Investigator

> Adapted from `umputun/cc-thingz` (MIT). Bundled paths resolve under the devkit clone root (`~/.claude/agentic-devkit`).

Apply 5-Why analysis to find the fundamental cause of an issue instead of treating symptoms. Gather evidence at each level; resist proposing solutions until the root cause is identified.

## When to use

- errors, bugs, or unexpected behaviour
- build failures or test failures
- performance issues or degradation
- integration problems
- any "it's not working" scenario

## The 5-Why methodology

Ask "why" progressively to drill from surface to root:

1. **Why #1** — immediate cause (the symptom)
2. **Why #2** — process / workflow issue
3. **Why #3** — system-level problem
4. **Why #4** — design / architecture issue
5. **Why #5** — fundamental root cause

## Workflow

### 1. Gather context

```
## Issue Summary
[brief description]

## Initial Symptoms
- what the user is experiencing
- error messages / logs
- observable behaviour

## Context
- environment, recent changes, related components, repro steps
```

### 2. Apply 5-Why

```
### Why #1: [surface cause]   — Evidence: [logs/errors]      Impact: [...]
### Why #2: [deeper cause]    — Evidence: [code/config]      Impact: [...]
### Why #3: [system cause]    — Evidence: [arch/deps]        Impact: [...]
### Why #4: [design cause]    — Evidence: [patterns]         Impact: [...]
### Why #5: [root cause]      — Evidence: [fundamental]      Impact: [...]
```

### 3. Identify root cause

```
## Root Cause Identified
[the fundamental issue to address]

## Recommended Investigation Areas
- specific files / components / systems to examine next
```

## Principles

1. Avoid solution bias — understand before fixing.
2. Gather evidence — don't assume, verify with data.
3. Consider multiple contributing factors.
4. Document evidence at each level.
5. Think systemically — broader implications.
6. Question "it should work" assumptions.
7. Use version control — check when the issue was introduced.

## References

Load on demand during investigation:

- `references/patterns.md` — common root-cause patterns by category (configuration, race conditions, resource exhaustion, integration, build/deploy).
- `references/techniques.md` — investigation techniques with command examples (error analysis, code investigation, dependency analysis, environment).

## Handoff

Once the root cause is confirmed and a fix is warranted, stop and switch to implementation (or `EnterPlanMode` for non-trivial fixes). This skill investigates; it does not change code.
