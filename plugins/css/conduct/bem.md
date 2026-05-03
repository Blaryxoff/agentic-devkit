# BEM Naming Methodology

Apply this conduct when the project uses BEM (Block-Element-Modifier) naming for hand-written CSS/SCSS class names. Skip if the project uses utility-first (Tailwind) or another methodology.

## Scope

- Class naming for components and pages styled with hand-written CSS or SCSS
- Modifier semantics
- SCSS variable/mixin reuse where SCSS is in use

## Conventions

- Class naming: `block`, `block__element`, `block--modifier`.
- One component = one primary block name.
- Avoid mixing unrelated blocks in the same component stylesheet.
- Keep modifiers semantic (`--active`, `--disabled`, `--error`), not presentational (`--red`).
- Keep class naming stable across refactors; avoid ad-hoc one-off names.
- Reuse existing SCSS variables/mixins/placeholders where present.
- Keep styles local to component scope unless project conventions require global styles.

## Anti-pattern: BEM inconsistency

Bad:
- random class naming per component, mixed styles, unclear modifiers.

Good:
- stable `block__element--modifier` naming and one primary block per component.

## Review checklist

- [ ] Class names follow BEM conventions
- [ ] Modifier usage is semantic and consistent
- [ ] No style leakage or conflicting block naming
