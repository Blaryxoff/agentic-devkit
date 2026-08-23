---
name: devkit-wrong
description: reset and re-evaluate when the current approach has hit a dead end — step back, restate the problem, and propose fresh alternatives instead of patching a failing path. Use when the user says "wrong", "this isn't working", "wrong approach", "start over", "try again", or "bad direction".
---

# Wrong — Reset and Re-evaluate

> Adapted from `umputun/cc-thingz` (MIT).

The current approach isn't working. Stop patching it. Re-examine the problem from the start and propose alternatives.

## Workflow

### 1. Re-analyze the core problem

State the problem in plain terms. What exactly are we solving? Strip away the failed approach.

### 2. Identify missing context

What do we still not know about: existing codebase patterns, constraints, integration points, expected scale, or domain requirements not yet stated?

### 3. Propose 2–3 fresh approaches

Each must:
- follow the project's idioms and existing architecture
- match the surrounding code's style (per `plugins/core/conduct/surgical-changes.md`)
- solve the exact problem without over-engineering (per `plugins/core/conduct/solid-dry.md`)
- avoid shortcuts and hacks

### 4. Explain trade-offs

For each: why it fits, main benefits/drawbacks, how it integrates with the existing code.

### 5. Recommend the best path

Which approach is most appropriate, and why.

## Guidelines

- Production-quality, idiomatic solutions — not proofs of concept.
- Scope changes surgically; do not rewrite working code that isn't part of the problem.
- Ask clarifying questions before proceeding when the problem is underspecified — resolve via `plugins/core/conduct/clarification-protocol.md`.
- For a non-trivial chosen approach, use the harness's native plan mode when available; otherwise present the plan in chat and get approval before implementing.
