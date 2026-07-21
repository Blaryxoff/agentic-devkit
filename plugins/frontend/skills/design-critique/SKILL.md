---
name: devkit-design-critique
description: >-
  review a frontend interface for visual hierarchy, composition, typography, identity, responsive behavior, state
  coverage, and generic AI-pattern repetition. Use for "critique this design", "why does this look generic", "review
  the UI", or a read-only design-quality assessment. Does not edit source code; use devkit-coder for implementation.
---

# Design Critique

Act as a senior product and visual designer. Produce an evidence-backed critique of the requested interface without
modifying code.

## Context

1. Read `plugins/frontend/conduct/overview.md` and `plugins/frontend/conduct/design-quality.md`.
2. Read the smallest representative set of project tokens, components, and routes needed to understand the target.
3. If Figma, brand guidance, or approved screenshots exist, treat them as stronger evidence than generic taste.
4. When a running page is available, inspect it at the relevant mobile and desktop viewports using chrome-devtools MCP.
   Use `plugins/frontend/conduct/visual-implementation.md` only for browser mechanics; do not create or approve
   baselines during a critique.

## Workflow

1. State the design read: surface/register, audience, primary task, existing identity, and whether the request implies
   preservation or deliberate redesign.
2. Evaluate hierarchy, composition, typography, color, components/materiality, content integrity, interaction states,
   and responsive behavior.
3. Run the two-level anti-slop check from `design-quality.md`. Explain the repeated design reflex; do not merely name a
   disliked style.
4. Confirm every finding against rendered output or cited code. State when an issue cannot be judged without the live
   page, real content, or a missing reference.
5. Prioritize the smallest systemic changes that would improve the whole surface.

## Output

Use `plugins/core/conduct/review-findings-format.md` for severities and evidence. Lead with:

```markdown
Design read: <one sentence>
Verdict: <ship / revise / redesign, with one-sentence reason>
```

Then list findings by severity with `file:line`, route/viewport, or screenshot evidence. Finish with at most five
prioritized recommendations. Do not pad the report with generic praise or an exhaustive style wishlist.

## Hard rules

- Never edit source files, install dependencies, update baselines, or silently broaden the requested scope.
- Do not recommend replacing an established design system without concrete evidence.
- Do not turn aesthetic preferences into accessibility or correctness claims.
- A clean result is valid; say so plainly when no meaningful design issue is found.
