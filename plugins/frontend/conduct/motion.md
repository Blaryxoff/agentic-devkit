# Motion Design

Tool-agnostic policy for CSS, Web Animations API, and framework motion libraries. Motion must improve comprehension or
feedback without making frequent work feel slower.

## Purpose gate

Before adding or keeping an animation, name its purpose:

- preserve spatial continuity;
- explain a state or hierarchy change;
- acknowledge input;
- prevent a jarring content change;
- add restrained delight to a rare, high-emotion moment.

If none applies, remove the animation. "It looks expensive" is not a sufficient purpose on its own.

## Frequency

Frequency changes the motion budget:

| Frequency | Default treatment |
|---|---|
| Continuous or keyboard-speed interaction | Instant or nearly instant; animate only when it improves orientation |
| Many times per session | Small amplitude and short duration |
| Occasional modal, drawer, popover, or toast | Standard transition with clear spatial origin |
| Rare onboarding, completion, or celebration | May use richer choreography without blocking interaction |

Treat this as a decision aid, not a universal prohibition. Verify the actual interaction rather than guessing its
frequency from the component name.

## Timing and easing

Recommended starting ranges:

| Interaction | Duration |
|---|---|
| Press feedback | 100-160ms |
| Tooltip or small popover | 125-200ms |
| Dropdown or select | 150-250ms |
| Modal or drawer | 200-500ms, with the shorter end preferred for routine UI |
| Marketing or explanatory sequence | May be longer when it does not delay input |

- Entering and exiting UI usually starts fast and decelerates with a strong ease-out.
- Movement or morphing between visible states usually uses ease-in-out.
- Hover and color feedback may use a restrained `ease`.
- Constant progress may use `linear`.
- Avoid slow-starting `ease-in` on routine UI unless the deliberate delay communicates something meaningful.

Prefer project tokens. When none exist, these are useful starting points:

```css
--motion-ease-out: cubic-bezier(0.23, 1, 0.32, 1);
--motion-ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);
--motion-ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);
```

## Physicality and origin

- Popovers, menus, and tooltips should emerge from their trigger or attachment edge. Use the component library's
  transform-origin variable when available.
- Avoid entrances from `scale(0)`. A subtle `scale(0.9-0.97)` with opacity preserves continuity without appearing from
  nothing.
- Keep modals centered unless the product establishes another spatial model.
- Press feedback should be subtle enough not to move surrounding layout or blur text.
- Deliberate phases may be slower than system responses; release and confirmation should feel immediate.

## Interruptibility

- Use CSS transitions for rapidly reversible state changes because they retarget from the current value.
- Use keyframes for authored sequences that are not expected to reverse mid-flight.
- Use springs or equivalent dynamic models for gestures and velocity-sensitive interactions.
- Use `@starting-style` for CSS entry transitions when supported; provide a project-compatible fallback when required.
- Never block input until decorative choreography completes.

## Performance

- Prefer `transform` and `opacity` for continuous motion.
- Avoid animating layout properties such as `width`, `height`, `margin`, `padding`, `top`, and `left` frame by frame.
- `clip-path`, color, filter, blur, mask, and shadow may be appropriate for bounded, measured effects; keep the affected
  area small and verify on target browsers and devices.
- Scope `will-change` to elements that are about to animate and remove it when practical.
- Prefer CSS or WAAPI for predetermined motion; use JavaScript when runtime input, gestures, or interruption require it.
- Extend existing duration, easing, and spring tokens instead of creating near-duplicates.

## Accessibility and input modes

- Respect `prefers-reduced-motion`. Remove position changes and parallax; preserve instant or gentle opacity/color
  feedback when it aids comprehension.
- Do not globally erase essential progress or state feedback.
- Gate hover-only motion behind `@media (hover: hover) and (pointer: fine)`.
- Keep content visible before reveal enhancement; animation failure must not ship invisible content.
- Avoid autoplaying or infinite decorative motion unless the user can pause it and it has a clear purpose.

## Verification

1. Exercise the interaction repeatedly at realistic speed.
2. Slow it down 2-5x when origin, easing, or coordinated properties are hard to judge.
3. Check rapid reversals and repeated triggers for jumps or restarts.
4. Inspect the reduced-motion path and touch/pointer behavior.
5. Verify gestures on a real target device when device physics or scrolling materially affects the result.
6. Check for layout shifts, dropped frames, and delayed input before declaring the motion polished.

## Provenance

Adapted from the focused decision framework and review vocabulary in
[Emil Kowalski's skills](https://github.com/emilkowalski/skills/tree/6bf24434f7730ad169077756cf9c7cd7bd675fc6)
(MIT). Absolute upstream claims were converted into contextual rules where browser, library, or product behavior requires
measurement.
