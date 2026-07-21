---
name: css-animate
description: |
  Create purposeful, performant CSS motion using transitions, @starting-style,
  keyframes, scroll-driven animation, and View Transitions. Use when the user
  asks to implement CSS animation, hover/press feedback, entrance/exit motion,
  scroll animation, or page transitions. Includes reduced-motion and feel-check
  verification; use devkit-reviewer-motion for a read-only motion review.
disable-model-invocation: true
license: MIT
---

# CSS Animate

Implement CSS motion after deciding that motion improves the interaction. This skill owns CSS technique and
verification. When `devkit-frontend` is enabled, also apply `plugins/frontend/conduct/motion.md` for shared product and
interaction policy.

Also consult:

- [modern-patterns.md](../css-expert/references/modern-patterns.md) for current CSS patterns;
- [browser-compat.md](../css-expert/references/browser-compat.md) for support and fallback decisions.

## Workflow

1. Read the triggering interaction and existing motion tokens/components.
2. Name the motion's purpose and reduce its amplitude/duration as interaction frequency increases. When
   `devkit-frontend` is enabled, apply its full motion conduct.
3. Choose the smallest interruptible technique that fits.
4. Implement with visible default content and scoped performance costs.
5. Add reduced-motion and pointer-mode behavior.
6. Exercise repeated triggers, reversals, and supported viewports.

## Technique selection

```text
Simple state change or frequent interaction?
└─ CSS transition

Element entering from a DOM/state change?
└─ Transition + @starting-style when supported

Authored multi-step sequence that will not reverse mid-flight?
└─ @keyframes

Scroll progress or element visibility?
└─ animation-timeline: scroll() / view(), behind @supports

Page or shared-element navigation?
└─ View Transition API

Gesture, velocity, or physics-driven input?
└─ CSS is not sufficient by itself; use the project's existing motion/gesture layer
```

Prefer transitions over keyframes for rapidly reversible UI because transitions retarget from the current value.

## Timing and tokens

Reuse project tokens. When none exist, start from the ranges and curves below, then tune in the rendered interaction.

```css
:root {
  --motion-fast: 160ms;
  --motion-standard: 220ms;
  --motion-ease-out: cubic-bezier(0.23, 1, 0.32, 1);
  --motion-ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);
}
```

Do not introduce a parallel token scale when the project already has equivalent values.

## Patterns

### Press and hover feedback

```css
.button {
  transition:
    transform var(--motion-fast) var(--motion-ease-out),
    background-color var(--motion-fast) ease;

  &:active {
    transform: scale(0.97);
  }
}

@media (hover: hover) and (pointer: fine) {
  .button:hover {
    transform: translateY(-1px);
  }
}
```

Keep press feedback subtle. Do not animate surrounding layout.

### Origin-aware entry

```css
.popover {
  transform-origin: var(--popover-transform-origin, top center);
  opacity: 1;
  transform: scale(1) translateY(0);
  transition:
    opacity var(--motion-fast) var(--motion-ease-out),
    transform var(--motion-fast) var(--motion-ease-out);

  @starting-style {
    opacity: 0;
    transform: scale(0.96) translateY(-0.25rem);
  }
}
```

Use the component library's transform-origin variable when it provides one. Do not enter from `scale(0)`.

### Scroll-linked enhancement

Content must be visible without animation. Add the enhancement only when the browser supports it.

```css
.section {
  opacity: 1;
  transform: none;
}

@supports (animation-timeline: view()) {
  .section {
    animation: section-reveal linear both;
    animation-timeline: view();
    animation-range: entry 10% entry 80%;
  }

  @keyframes section-reveal {
    from {
      opacity: 0.4;
      transform: translateY(1rem);
    }
  }
}
```

Do not apply the same reveal mechanically to every section. Match the motion to the content and frequency.

### View transitions

```css
@view-transition {
  navigation: auto;
}

.hero-image {
  view-transition-name: hero-image;
}

::view-transition-old(hero-image),
::view-transition-new(hero-image) {
  animation-duration: var(--motion-standard);
  animation-timing-function: var(--motion-ease-in-out);
}
```

Names must be unique in the active document. Confirm the transition does not delay navigation or leave duplicate
elements visible.

## Performance

- Prefer `transform` and `opacity` for continuous motion.
- Do not animate `width`, `height`, `margin`, `padding`, `top`, or `left` frame by frame.
- `clip-path`, color, filter, blur, mask, and shadow are allowed only for bounded effects verified on target browsers.
- Avoid `transition: all`; list intended properties.
- Scope `will-change` to an imminent animation. Never apply it globally.
- Use percentage transforms when movement should follow the element's own size.

## Reduced motion

Prefer component-level alternatives over a global `!important` reset:

```css
@media (prefers-reduced-motion: reduce) {
  .popover,
  .section {
    transform: none;
    animation: none;
    transition-duration: 0.01ms;
  }
}
```

Preserve opacity, color, progress, or instant state feedback when it helps comprehension. Remove parallax, large
position changes, and decorative choreography.

## Verification checklist

- [ ] The animation has a named UX purpose appropriate to its frequency.
- [ ] Existing duration/easing tokens are reused or deliberately extended.
- [ ] Repeated triggers and rapid reversals do not jump or restart incorrectly.
- [ ] Popovers and menus use the correct spatial origin.
- [ ] Content is visible when animation support or observation fails.
- [ ] Hover motion is gated for fine pointers.
- [ ] Reduced-motion behavior is useful and does not erase essential feedback.
- [ ] No unintended layout animation or `transition: all` remains.
- [ ] The interaction has been feel-checked at realistic speed and, when necessary, in slow motion.

## Provenance

Retains the original css.dev MIT lineage and adapts motion decision ideas from
[Emil Kowalski's skills](https://github.com/emilkowalski/skills/tree/6bf24434f7730ad169077756cf9c7cd7bd675fc6)
(MIT). Framework-specific performance claims are intentionally excluded unless they can be verified in the target
project.
