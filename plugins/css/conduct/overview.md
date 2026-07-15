# CSS Conduct

Modern CSS conventions and anti-patterns. Apply these rules whenever writing or reviewing CSS.

## Scope

- Layout, color, typography, animation, and architecture conventions
- Anti-patterns to flag and fix during implementation and review
- Accessibility and responsive design requirements

## Boundaries

- Tailwind-specific conventions are owned by `devkit-tailwind` conduct.
- Generic CSS token discipline is owned by `devkit-frontend` conduct.
- Projects using BEM naming also apply [bem.md](./bem.md).

## Core principles

1. **Modern CSS first.** Use current standards — container queries over media queries, Grid over float, nesting over preprocessors, `oklch()` over hex/hsl.
2. **The cascade is a feature.** Use `@layer` to organize styles. Manage specificity with `:where()` instead of fighting it with `!important`.
3. **Performance is a constraint.** Only animate `transform` and `opacity` for composited animations. Avoid layout thrashing.
4. **Accessibility is non-negotiable.** Respect `prefers-reduced-motion`. Provide `:focus-visible` styles. Support `forced-colors`. Maintain contrast ratios. Minimum 44×44px touch targets.

## Layout

- Use CSS Grid for two-dimensional layouts; Flexbox for one-dimensional alignment.
- Use `place-items: center` on a grid container for centering — not absolute positioning.
- Never use floats or clearfix for layout.
- Avoid absolute positioning to achieve layouts that Grid/Flex can handle natively.

## Custom properties and tokens

- Three-tier token model: primitive → semantic → component.
- Any value used more than once becomes a custom property.
- Component-scoped properties use the `--_name` underscore convention.
- No hardcoded colors — always reference a token.
- No hardcoded pixel values for spacing or typography — use `clamp()` or token scale.
- No magic numbers — derive positions from layout context (`calc(100% + var(--space-2xs))`) not arbitrary offsets.

## Color

- Use `oklch()` or `oklab()` for all color definitions — not hex, rgb, or hsl.
- Use `color-mix(in oklch, ...)` for hover/state variations.
- Use `light-dark()` with `color-scheme: light dark` for theme-aware colors.

## Responsive design

- Container queries for component-level responsiveness; media queries for page-level layout only.
- Use `em`-based breakpoints (not `px`) to respect user font-size preferences.
- Use `clamp()` for fluid typography and spacing — no fixed sizes per breakpoint.
- Use logical properties (`margin-block`, `padding-inline`, `inset-inline-start`) over physical properties.
- Never hide content with `display: none` on mobile unless it is genuinely removed from the design.

## Cascade layers

- Declare layer order explicitly at the top of each stylesheet: `@layer reset, tokens, base, layout, components, utilities;`
- Never use `!important` to override specificity — use `@layer` ordering or `:where()` instead.
- Never use ID selectors for styling.
- Keep nesting to 3 levels maximum.

## Animation

- Only animate `transform` and `opacity` for GPU-composited transitions (never `width`, `height`, `top`, `left`).
- Always provide a `prefers-reduced-motion: reduce` override that disables or minimizes motion.
- Use `will-change` only on elements immediately before animation; remove it after.

## Architecture

- Never use `@import` inside stylesheets — load stylesheets in parallel via `<link>` tags.
- Never set styles via inline JavaScript (`element.style.property`). Toggle classes or set custom properties (`element.style.setProperty`).

## Anti-patterns to flag

- Float-based layouts
- Absolute positioning used as a layout tool
- Negative margins for spacing
- `!important` overuse
- ID selectors for styling
- Over-qualified selectors (more than 2–3 levels)
- Hardcoded hex/rgb colors instead of tokens
- Hardcoded `px` spacing/typography values
- Magic number offsets
- `px`-based media query breakpoints
- Animating layout properties (`width`, `height`, `top`, `left`)
- `will-change` applied globally
- Missing `prefers-reduced-motion` override
- `@import` inside CSS files
- Inline JS style manipulation

## AI slop tells — never write these

- Generic gradient backgrounds (`linear-gradient(135deg, #667eea, #764ba2)`)
- Glassmorphism `backdrop-filter: blur()` without clear purpose
- `box-shadow: 0 10px 40px rgba(0,0,0,0.1)` on everything
- Hardcoded `border-radius: 12px` universally
- `rgba()` for color manipulation instead of `color-mix(in oklch, ...)`
- Fake metrics sections with placeholder numbers
