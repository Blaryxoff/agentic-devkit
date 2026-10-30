# CSS Conduct

Apply these shared constraints when a task changes CSS or visible styling. Use the project's existing design system,
framework, browser support, and conventions. Use [css-expert](../skills/css-expert/SKILL.md) as the entry when CSS work
needs guidance unless a matching specialist is already selected. Behavior-only frontend work does not need CSS skills.

## Shared constraints

- Treat modern CSS patterns as defaults, not mandates. Choose Grid, Flexbox, container queries, logical properties,
  custom properties, cascade layers, nesting, and modern color functions when they fit the project's support matrix,
  design tokens, and surrounding code. Do not add them to a small change without a task need.
- Keep accessibility behavior intact: visible keyboard focus, reduced motion for nonessential animation, sufficient
  contrast for changed colors, and non-color cues when color conveys meaning. Consider forced-colors behavior when the
  affected UI relies on custom colors.
- Preserve text contrast of at least 4.5:1 for normal text and 3:1 for large text, with touch targets at least 44×44 CSS pixels.
- Prefer `transform` and `opacity` for frequent animation; use `will-change` narrowly and only when needed.
- Verify visual changes on the affected route and relevant viewport sizes. Check keyboard or preference states when
  the change affects those behaviors.

Tailwind-specific conventions belong to `devkit-tailwind`. Generic design-token policy belongs to `devkit-frontend`.
For projects using BEM naming, also apply [bem.md](./bem.md).
