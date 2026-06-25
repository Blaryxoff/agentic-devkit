---
name: devkit-clarify
description: >-
  handle user confusion — verify intent, explain the actual behaviour with evidence, and decide whether there's a real issue to fix. Use when the user appears confused or misaligned: "I don't understand", "this doesn't make sense", "wait, shouldn't it…", "why is this happening", "I expected X but got Y", contradictory statements, or frustration. Primary goal is to clarify, not to fix.
---

# Clarify

> Adapted from `umputun/cc-thingz` (MIT).

Resolve user confusion by investigating the actual behaviour, explaining it with evidence, and determining whether a real issue exists. **Primary goal: clarify and explain, not fix.** About half of confusion cases are genuine issues; the other half are misunderstandings. Do not assume either way — investigate first.

## When to use

- "confused", "I don't understand", "doesn't make sense"
- "wait, shouldn't it…", "but I thought…", "why does this…"
- "I expected X but got Y", "this is wrong", "something's off"
- contradictory statements, frustration, questions revealing a misconception

## Context to keep in mind

Users often: work on several projects in parallel (and mix behaviours), forget how things were implemented, hold outdated mental models, or confuse similar concepts across codebases. But they are also experienced developers whose instincts are frequently right, and real bugs do exist. Treat both outcomes as equally valid until evidence decides.

## Workflow

### 1. Identify the confusion

Extract the core question, the expectation, the reality, and locate the gap. Categorize: memory gap · project mixing · outdated mental model · architectural · behavioural · configuration · documentation · conceptual · implementation.

### 2. Investigate

Gather evidence before explaining: read the relevant code, check configuration, review docs, trace the execution flow. Do not guess — verify the actual system state.

### 3. Explain (gently)

1. Acknowledge the confusion (it's normal).
2. State the expectation: "you expected X to do Y".
3. State the reality: "actually X does Z because…".
4. Explain why — the reasoning / design decision behind it.
5. Show evidence — specific `file:line`, config, or docs.

Tone: gentle, not condescending. Avoid "you're wrong" framing. Keep it concrete and backed by the codebase, focused on the specific case — not a general tutorial.

### 4. Assess the outcome

- **A) Memory gap** — user forgot; system works as designed → gentle reminder with references.
- **B) Project mixing** — user is thinking of another project → clarify how this one differs.
- **C) Outdated understanding** — system changed, or the model never matched reality → explain current behaviour.
- **D) Documentation issue** — code is correct but docs mislead → suggest doc fix.
- **E) Configuration issue** — system can do it but isn't configured → suggest config change.
- **F) Real issue** — the expectation is reasonable AND the system genuinely doesn't meet it → proceed to step 5.

### 5. Plan the fix (real issues only)

For category F:

1. **State the scope** explicitly: trivial · localized · moderate · significant · architectural — and why. The user must understand the magnitude before deciding.
2. **Present options** when multiple valid approaches exist — via `AskUserQuestion`, recommended option first, include "do nothing" when the issue is cosmetic, has a workaround, or the fix is risky relative to benefit. Follow `plugins/core/conduct/clarification-protocol.md` for how to phrase and batch questions.
3. **Switch to `EnterPlanMode`** for the chosen approach. Do not fix a non-trivial issue without planning.

## Response format

```
## Understanding Your Confusion
**What you expected**: [...]
**What actually happens**: [...]

## Why This Happens
[explanation with evidence — file:line, config, docs]

## Assessment
[Not an issue / Documentation issue / Configuration issue / Real issue]
[if real issue] This is a real issue. I recommend entering plan mode to design the fix.
```

## Guidelines

- Never dismiss confusion as "user error" — investigate first. Never assume something is broken without evidence either.
- Always back explanations with evidence from the actual codebase.
- Don't over-explain — focus on the specific confusion.
- If the confusion reveals a real problem, treat it as valuable feedback and proceed to plan the fix.
