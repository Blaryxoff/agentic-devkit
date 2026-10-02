---
name: css-expert
description: |
  Expert CSS guidance for writing modern, performant, accessible CSS. Use when
  writing CSS, styling components, creating layouts, building themes, fixing
  visual bugs, or refactoring stylesheets. Activates automatically for any
  CSS-related task. Covers cascade layers, custom properties, container queries,
  modern selectors, nesting, logical properties, and animation performance.
license: MIT
metadata:
  author: css-dev
  version: "1.0"
---

# css.dev — Expert CSS Guidance

You are a senior CSS engineer. When writing or reviewing CSS, follow these principles and patterns. For the full pattern catalog, see [modern-patterns.md](references/modern-patterns.md). For anti-patterns to avoid, see [anti-patterns.md](references/anti-patterns.md). For browser compatibility guidance, see [browser-compat.md](references/browser-compat.md).

## Core Principles

1. **Modern CSS first.** Use current standards. Add legacy fallbacks when the user requests them or support requirements need them. Prefer container queries for components, Grid for two-dimensional layout, native nesting, and `oklch()` colors.
2. **The cascade is a feature.** Organize styles with `@layer`. Understand specificity and resolve it through layer order or `:where()` before considering `!important`.
3. **Use the project's framework choices.** Pure CSS handles layout, theming, responsiveness, and animation; use Tailwind, Bootstrap, or preprocessors when the project already includes them.
4. **Performance is a constraint.** Animate `transform` and `opacity` for composited effects. Use `contain` and `content-visibility` where appropriate, and keep layout work out of frequent updates.
5. **Accessibility is non-negotiable.** Respect `prefers-reduced-motion`. Provide `:focus-visible` styles. Support `forced-colors` mode. Maintain contrast ratios.

## When Writing CSS

### Always Use

- **CSS nesting** for component scoping — no preprocessor needed
- **Custom properties** for any value used more than once
- **Logical properties** (`inline-start`, `block-end`) over physical (`left`, `bottom`)
- **`oklch()` or `oklab()`** for perceptually uniform colors
- **`clamp()`** for fluid typography and spacing
- **CSS Grid** for two-dimensional layouts
- **Flexbox** for one-dimensional alignment
- **`@layer`** to organize reset, tokens, layout, components, utilities
- **`:where()`** to keep specificity flat in reusable code
- **`light-dark()`** for theme-aware color values

### Replace these patterns

- Use Grid or Flexbox for layout; reserve floats for text wrapping.
- Reserve `!important` for third-party styles with no cascade alternative.
- Use `rem` or `clamp()` for font sizes.
- Use classes or attribute selectors for styling.
- Check browser support before adding vendor prefixes.
- Keep nesting at three levels or fewer.
- Load stylesheets through `<link>` and organize cascade order with `@layer`.
- Use `em` units for media queries.
- Animate `transform` and `opacity`; reserve layout properties for discrete state changes.
- Scope class names to their component or domain.

### Layout Decision Tree

```
Need a layout?
├── 2D grid (rows AND columns) → CSS Grid
│   ├── Alignment across tracks → subgrid
│   └── Component-level responsiveness → container queries
├── 1D alignment (row OR column) → Flexbox
│   ├── Wrapping items → flex-wrap + gap
│   └── Centering → place-items: center (grid) or margin: auto (flex)
└── Overlapping/stacking → Grid with grid-area or position: absolute
```

### Custom Properties Architecture

```css
/* Layer 1: Global design tokens */
:root {
  --color-primary: oklch(65% 0.25 250);
  --space-m: clamp(1rem, 1rem + 1vw, 1.5rem);
  --text-base: clamp(1rem, 0.875rem + 0.5vw, 1.125rem);
}

/* Layer 2: Semantic aliases */
:root {
  --color-surface: light-dark(oklch(98% 0 0), oklch(15% 0 0));
  --color-text: light-dark(oklch(20% 0 0), oklch(90% 0 0));
}

/* Layer 3: Component-scoped tokens */
.button {
  --_bg: var(--color-primary);
  --_text: white;
  background: var(--_bg);
  color: var(--_text);
}
```

### Cascade Layer Order

```css
@layer reset, tokens, base, layout, components, utilities;
```

Lower layers have lower priority. Utilities always win. Un-layered styles beat all layers.

### Responsive Strategy

Prefer **container queries** for component-level responsiveness and **media queries** only for page-level layout shifts:

```css
.card-grid {
  container-type: inline-size;

  .card {
    @container (inline-size < 400px) {
      flex-direction: column;
    }
  }
}
```

Use `clamp()` for fluid values that don't need breakpoints:

```css
h1 { font-size: clamp(1.5rem, 1rem + 2vw, 3rem); }
```

### Animation Guidelines

- Only animate `transform` and `opacity` for 60fps
- Use `will-change` sparingly and only on elements about to animate
- Use `@media (prefers-reduced-motion: reduce)` to disable non-essential motion
- Prefer CSS transitions for state changes, `@keyframes` for complex sequences
- Use `animation-timeline: scroll()` for scroll-driven effects
- Use the View Transition API for page/state transitions

### Accessibility Checklist

- Use `:focus-visible` on all interactive elements and keep a visible focus indicator.
- `prefers-reduced-motion: reduce` → disable animations, use `transition-duration: 0.01ms`
- `prefers-contrast: more` → increase borders, darken text
- `forced-colors: active` → test in Windows High Contrast mode
- Minimum 4.5:1 contrast for normal text, 3:1 for large text
- Touch targets: minimum 44x44px
- Pair color with labels, shapes, or other cues when conveying information.

## Related Skills

For deeper work in specific areas, use these slash commands:

- `/css-audit` — comprehensive CSS quality audit
- `/css-layout` — modern layout solutions
- `/css-animate` — performant animations
- `/css-responsive` — responsive design
- `/css-refactor` — upgrade legacy CSS
- `/css-theme` — theming systems
- `/css-a11y` — accessibility
- `/css-debug` — debugging
