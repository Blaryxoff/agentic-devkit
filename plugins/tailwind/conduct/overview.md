# Tailwind Conduct

This section contains Tailwind-specific styling conventions covering tokenization, accessibility, performance, responsive strategy, and anti-patterns.

## Scope

- Utility class usage conventions
- Design token discipline via Tailwind config
- Accessibility patterns using Tailwind variants
- Animation and rendering performance
- Responsive strategy
- Anti-patterns and AI slop detection

## Boundaries

- Generic CSS best practices are owned by frontend conduct.
- Do not duplicate CSS policy text here; reference it where needed.
- Reference `plugins/core/conduct/ownership-map.md` when in doubt.

## Design token discipline

Tailwind config is the single source of truth for design tokens. Treat `theme.extend` as the project's token registry.

### Three-tier token mapping

| Tier | Purpose | Tailwind location |
|------|---------|-------------------|
| Primitive | Raw palette values (`blue-500`, `gray-100`) | `theme.colors` |
| Semantic | Purpose-driven aliases (`primary`, `surface`, `error`) | `theme.extend.colors` referencing primitives |
| Component | Defaults consumed by UI components | Component props / `@apply` blocks mapping to semantic tokens |

### Rules

- Never repeat arbitrary values (`[#e2e7ef]`, `[14px]`) across components — if it appears twice, it belongs in config.
- Derive shades with opacity modifiers (`bg-primary/80`) instead of defining new one-off color entries.
- Dark mode via `dark:` variant; in Tailwind v4, prefer CSS `color-scheme` integration.
- Keep `tailwind.config` theme flat and scannable — avoid deeply nested custom scales.
- Prefer semantic token names (`text-muted`, `bg-surface`) over raw palette names (`text-gray-400`) in component markup.

## Accessibility

### Focus styles

- Use `focus-visible:` variant on all interactive elements — never strip outlines without a visible replacement.
- Combine outline + offset for clear, high-contrast focus rings: `focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary`.
- Never use `outline-none` globally without providing a replacement.
- Focus styles must remain visible in forced-colors mode — `outline` works; `ring` alone does not.

### Reduced motion

- Wrap non-essential animations with `motion-safe:` so they are removed when the user prefers reduced motion.
- Use `motion-reduce:` to provide a reduced alternative for essential feedback (spinners, progress bars).
- Every `animate-*` and `transition-*` must have a motion-safe/reduce counterpart or a global reduced-motion stylesheet.

### Contrast and forced colors

- Use `contrast-more:` variant to increase border widths, darken muted text, and add visible borders to background-only elements.
- Test with Windows High Contrast mode — elements that rely solely on background color for meaning need a visible border fallback.

### Touch targets

- All interactive elements must meet minimum 44x44px: `min-h-11 min-w-11`.
- Icon buttons with small visual size: expand the hit area with padding or a pseudo-element overlay, not by inflating the icon.

### Color-only indicators

- Never rely on color alone to convey information (validation, status, categories).
- Pair color with a secondary indicator: icon, text label, border treatment, or shape difference.

### Screen reader support

- Use Tailwind's `sr-only` utility for visually hidden but accessible content (icon button labels, skip link text, table captions).
- Never use `hidden` or `invisible` when content must remain in the accessibility tree.

### Skip links

- Include a skip link as the first focusable element: visually hidden by default, visible on focus.
- Target `#main-content` or the primary content landmark.

### WCAG contrast minimums

| Element | Minimum ratio |
|---------|---------------|
| Normal text (< 24px / < 18.66px bold) | 4.5:1 |
| Large text (>= 24px / >= 18.66px bold) | 3:1 |
| UI components and graphical objects | 3:1 |

## Performance

### Animation constraints

- Only animate composited properties: `transition-transform`, `transition-opacity`, `transition-shadow`.
- Never use `transition-all` — list explicit properties to avoid triggering layout recalculations.
- `will-change-transform` only on elements about to animate (e.g., on hover), not as a global default.
- Durations: 150–400ms for UI feedback, 200–600ms for entrance animations.

### Rendering

- Use `content-visibility-auto` on long lists, below-fold sections, and heavy off-screen content.
- Prefer `gap-*` on flex/grid parents over margin utilities between children — cleaner, no collapsing-margin surprises.
- Add `aspect-ratio` (`aspect-video`, `aspect-square`) to images and media to prevent layout shift (CLS).

### What to avoid

- `backdrop-blur-*` on large areas — expensive paint operation; limit to small overlays.
- `shadow-2xl` / `shadow-lg` on many elements simultaneously — each is a paint cost.
- `animate-*` with `infinite` iteration unless there is a clear UX purpose (not decorative loops).

## Anti-patterns and AI slop

### Layout

| Bad | Good |
|-----|------|
| `float-left` / `float-right` for layout | `grid`, `flex` + `gap-*` |
| Negative margins (`-mt-4`) for spacing | `gap-*` on parent |
| `w-[960px]` fixed width | `max-w-screen-xl w-full` or extend config |

### Values

| Bad | Good |
|-----|------|
| `text-[14px]` arbitrary font size | `text-sm` from type scale |
| `[#e2e7ef]` repeated arbitrary color | Add to config as semantic token |
| `max-w-[960px]` arbitrary width | `max-w-6xl` or extend config breakpoints |
| `p-[13px]` arbitrary spacing | Nearest scale value or extend config |

### Specificity

| Bad | Good |
|-----|------|
| `!important` modifier | Fix specificity at source — restructure layers |
| Inline `style` attributes for overrides | Tailwind class or config token |
| `#id` selectors in custom CSS | Class-based selectors |

### AI slop tells

Flag and rewrite these patterns — they signal generic AI-generated output:

- Generic purple gradients (`from-indigo-500 to-purple-600`) on everything
- Glassmorphism (`backdrop-blur-xl bg-white/10`) where it adds no UX value
- `shadow-xl` or `shadow-2xl` on every card
- `rounded-2xl` on everything with no design rationale
- Card-grid-with-icon layouts repeated for every section
- Fake metrics ("10K+ users", "99.9% uptime") as placeholder content
- Excessive transparency and layering for decoration

## Responsive strategy

### Container queries first (Tailwind v4)

- Use `@container` variants for component-level responsiveness — the component adapts to its container, not the viewport.
- Reserve `sm:` / `md:` / `lg:` / `xl:` breakpoints for page-level layout shifts only (sidebar collapse, navigation pattern change).

### Intrinsic sizing

- Prefer Tailwind's built-in intrinsic classes (`max-w-prose`, `min-w-fit`, `w-full`, `w-auto`) over fixed arbitrary widths.
- Use `min()`-based patterns via config for card grids: `grid-cols-[repeat(auto-fill,minmax(min(280px,100%),1fr))]` or extract to a config utility.

### Fluid type and spacing

- Define a fluid type scale in config using `clamp()` values rather than scattering per-element arbitrary clamp utilities.
- Same for spacing: define fluid tokens centrally, reference by name.

### Rules

- Limit page-level breakpoint variants to 2–3 tiers maximum.
- Never use viewport breakpoints to change a reusable component's internal layout — that is the job of container queries.
- Test content readability at 320px and 2560px viewports.

## Usage conventions

- Keep utility class usage consistent with project conventions and readable groupings.
- Reuse existing UI primitives and components before introducing one-off class-heavy markup.
- Group related utilities logically (layout, spacing, typography, color, state) for readability.
