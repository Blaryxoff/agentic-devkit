---
name: css-expert
description: >-
  Use for CSS or visible web styling: implement or debug CSS, or audit, refactor, lay out,
  adapt, theme, animate, or improve the accessibility of styled interfaces. Do not
  use for backend-only work or JavaScript/TypeScript behavior changes that do not
  change presentation, or native styling APIs such as React Native StyleSheet. Route scoped work to one CSS specialist;
  handle small isolated CSS changes directly. Skip when a CSS specialist is explicitly selected.
license: MIT
metadata:
  author: css-dev
  version: "1.0"
---

# CSS work

Use this as the automatic entrypoint for work that changes CSS or visible web styling. First identify whether the request
changes presentation and whether it asks for implementation, diagnosis, or a read-only review. Backend-only work and
JavaScript/TypeScript behavior changes with no presentation impact do not need CSS guidance. Native styling APIs
such as React Native StyleSheet use their platform's workflow, not web CSS patterns.

For a clear, scoped task, read the full `SKILL.md` for exactly one primary specialist below and follow its workflow.
Treat that file as an on-demand resource; do not load every specialist or reference catalog. Add another specialist
only for a distinct need in scope. For small, isolated tweaks that do not need a specialist workflow, use the shared
constraints here and stay in this skill.

| Task | Specialist |
| --- | --- |
| Design or implement a layout | [`css-layout`](../css-layout/SKILL.md) |
| Responsive behavior, fluid sizing, or viewport adaptation | [`css-responsive`](../css-responsive/SKILL.md) |
| Theme, color system, or design tokens | [`css-theme`](../css-theme/SKILL.md) |
| CSS motion or transitions | [`css-animate`](../css-animate/SKILL.md) |
| CSS rendering, cascade, or layout diagnosis | [`css-debug`](../css-debug/SKILL.md) |
| CSS quality audit or report-only review | [`css-audit`](../css-audit/SKILL.md) |
| CSS accessibility audit or a specific accessibility defect | [`css-a11y`](../css-a11y/SKILL.md) |
| Modernize or consolidate legacy CSS | [`css-refactor`](../css-refactor/SKILL.md) |

Specialists remain available through the harness's explicit skill menu. Resolve the loaded skill's symlink to its
canonical directory before following the relative specialist and reference links. Open a reference
only when it resolves a concrete pattern, anti-pattern, or browser support question; never load the catalog as a bundle.

## Shared constraints

- Follow the project's styling system, framework, design tokens, browser support, and existing conventions. Modern CSS
  features are defaults only when they fit those constraints; do not introduce broad syntax or architecture changes
  for a small local task.
- Preserve visible keyboard focus. Respect `prefers-reduced-motion` for nonessential motion. Do not rely on color
  alone to convey meaning; consider contrast and forced-colors behavior when the changed UI implicates them.
- Keep changed text at least 4.5:1 contrast for normal text and 3:1 for large text, and touch targets at least 44×44 CSS pixels.
- Keep the request's read/write mode: an audit or review is read-only; diagnosis may report a cause before proposing or
  applying a fix as requested; implementation changes only the relevant styling.
- Verify a visual change on its affected route at a relevant viewport. Include responsive sizes when the change can
  affect them, and check the relevant preference or keyboard state when those behaviors change.
