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
   Use `plugins/frontend/conduct/visual-implementation.md` for browser mechanics. Keep baseline creation and approval
   outside the critique.

## Workflow

1. State the design read: surface/register, audience, primary task, existing identity, and whether the request implies
   preservation or deliberate redesign.
2. Evaluate hierarchy, composition, typography, color, components/materiality, content integrity, interaction states,
   and responsive behavior.
3. Run the two-level anti-slop check from `design-quality.md`. Explain the repeated design reflex and its effect on the
   surface.
4. Ground every finding in rendered output or cited code. Identify issues that need the live page, real content, or a
   missing reference before they can be judged.
5. Prioritize the smallest systemic changes that would improve the whole surface.

## Output

Use `plugins/core/conduct/review-findings-format.md` for severities and evidence. Lead with:

```markdown
Design read: <one sentence>
Verdict: <ship / revise / redesign, with one-sentence reason>
```

Then list findings by severity with `file:line`, route/viewport, or screenshot evidence. Finish with at most five
prioritized recommendations focused on evidence-backed improvements.

## Hard rules

- Keep the critique read-only and within the requested scope; leave source files, dependencies, and baselines unchanged.
- Recommend replacing an established design system only when concrete evidence supports it.
- Separate aesthetic preferences from accessibility and correctness findings.
- A clean result is valid; say so plainly when no meaningful design issue is found.
