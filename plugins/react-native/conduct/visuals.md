# Native Design, Accessibility, and Motion

Use `plugins/frontend/conduct/design-quality.md` for source precedence, identity, hierarchy, composition, typography, content integrity, whole-frame inventory before details, anti-slop checks, and evidence. Use `plugins/frontend/conduct/motion.md` for purpose/frequency/origin/interruptibility policy. Apply native mechanisms below rather than CSS, DOM, or browser-only verification.

## Reference and regression loop

1. Discover the existing device/simulator automation and screenshot tools; use project-approved commands without installing a new runner. Resolve test login/fixtures, relevant screens/states, and target OS/device/build/locale/theme/font scale/orientation/keyboard/safe-area configuration.
2. Read supplied Figma/design references and export the matching frame when available. Record dimensions, component inventory, hierarchy, tokens, type roles, and native control variants. Preserve existing identity unless the request authorizes a redesign.
3. For a guarded refactor, verify an approved current baseline for each target/state before editing. Capture and obtain explicit approval when one is missing; never bless a new baseline simply because it matches current code.
4. Measure actual native layout/accessibility state where tooling exposes it; capture the simulator/device output for comparison. Normalize device pixels versus layout units, pixel ratio, crop, insets/system chrome, and font scale before comparing. Keep baselines separate per intended OS/device rendering configuration.
5. Compare whole-screen composition and complete control inventory first, then bounds, spacing, text/font, colors, imagery, radii, states, clipping/overlap, and scroll behavior. Inspect safe areas, notches, keyboard avoidance, dynamic type, and supported orientations.
6. Use the project's existing image-diff/assertion tooling for persistent regression checks when available. Read mismatch metrics and expected/actual/diff paths first; inspect relevant images to diagnose. Do not hide a structural defect with a broad threshold, crop, mask, or baseline replacement.
7. Fix unintended deltas; keep intentional changes separate for approval. Record screen/state/device/build plus expected/actual/diff evidence and which cells remain unverified. A manual screenshot comparison is not persistent regression protection.

## Accessibility

- Verify role, accessible name/hint/state, grouping, reading order, focus transfer, announcements, and modal dismissal/back behavior using native accessibility tools and relevant VoiceOver/TalkBack checks.
- Check text scaling, truncation, contrast in both themes, touch target/hitSlop, keyboard/switch access when supported, and color-independent meaning. Keep meaningful validation/loading/success feedback accessible.
- Respect system reduced motion and native platform conventions. Preserve essential progress feedback and a usable path when animation, fonts, network, permission, or an optional native module is unavailable.

## Motion and performance

- Reuse duration/easing/spring tokens and the installed native animation library. Translate shared timing guidance into the platform's units; CSS easing strings and `prefers-reduced-motion` are not native APIs.
- Verify touch/gesture velocity, cancellation, rapid reversal/repeated trigger, navigation transitions, and scroll interaction. Keep input responsive, content visible, and session-owning components mounted when layout changes.
- Measure JS and UI frame behavior on the relevant device/build; expensive JS work and layout animation have different costs. Reanimated/UI-thread work is not automatically free of frame, memory, or battery cost.
- Inspect long lists, image decoding/caching, large stream buffers, foreground reconnect storms, background timers, CPU/memory, and battery/network use when those paths change. Use actual product/device budgets and release/profile builds rather than debug-only timing claims.
- Use the shared critique, motion-review, reference-build, and visual-guard workflows with this native adapter; keep workflow selection independent of the framework.

Sources: [React Native accessibility](https://reactnative.dev/docs/accessibility), [performance](https://reactnative.dev/docs/performance), [Expo development tools](https://docs.expo.dev/develop/tools/).
