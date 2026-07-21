# Design Quality

Tool-agnostic guidance for choosing and evaluating a frontend visual direction. Apply it when design decisions are part
of the task, especially for from-scratch UI, redesigns, visual critique, or requests to make an interface feel less
generic.

## Source-of-truth order

1. Explicit user requirements and supplied references.
2. Figma, approved screenshots, brand guidelines, and existing product design tokens.
3. Established components and neighboring product surfaces.
4. The heuristics below.

Never override a stronger source of truth just to make the result more fashionable.

## Design read

Before choosing a direction, establish:

- surface: marketing/brand, product/application, editorial/content, or mixed;
- audience and primary task;
- existing identity: typography, palette, imagery, radii, density, and interaction patterns;
- requested change: preserve, evolve, or deliberately replace the current direction;
- constraints: accessibility, performance, supported viewports, content, and available assets.

Summarize the result in one sentence when it helps alignment. Ask one focused question only when two materially
different directions remain plausible.

## Registers

### Brand surfaces

On marketing pages, campaigns, portfolios, and editorial surfaces, design helps communicate identity. Composition,
typography, imagery, and controlled surprise may carry more weight than component uniformity.

### Product surfaces

In applications, dashboards, settings, and tools, design serves task completion. Clarity, predictable hierarchy,
information density, state coverage, and consistency with neighboring flows take priority over novelty.

Mixed products may use both registers, but do not apply a campaign-page treatment to high-frequency product controls.

## Identity preservation

- Inspect existing tokens, representative components, and adjacent screens before proposing new visual language.
- Reuse the project's component and icon systems when they fit.
- Treat a redesign as preservation by default. Replace an identity choice only when the user requests it or evidence
  shows it is causing a concrete usability, accessibility, or coherence problem.
- Prefer fixing systemic tokens and component rules over accumulating one-off visual patches.

## Craft checks

Evaluate the interface as a whole before polishing isolated details:

1. **Hierarchy:** one clear focal point, legible action priority, and appropriate weight for secondary information.
2. **Composition:** intentional alignment, whitespace, rhythm, and density across viewports.
3. **Typography:** readable line length, coherent type roles, deliberate scale, and no clipping or overflow.
4. **Color:** sufficient contrast, consistent semantic meaning, and an accent strategy tied to the identity.
5. **Components:** cards, pills, dividers, shadows, and decoration earn their role instead of becoming default wrappers.
6. **Content:** realistic copy and data; no fake metrics, decorative status, or placeholder product claims presented as
   fact.
7. **States:** loading, empty, error, disabled, focus, hover, active, and success states match the surrounding product.
8. **Responsive behavior:** the hierarchy and composition reflow intentionally rather than merely shrinking.

## Anti-slop check

AI slop is repetition without a reason, not a specific color or style. Check at two levels:

- **Category reflex:** could the palette, hero, component structure, and typography be predicted from the industry alone?
- **Anti-reflex reflex:** after avoiding the obvious default, did the design fall into another fashionable template?

Common signals to investigate:

- the same centered hero, equal card grid, eyebrow, and fade-up sequence on every page;
- nested cards or universal pills/radii with no information-architecture purpose;
- generic gradients, glass, glow, grid overlays, or oversized type used as substitute for identity;
- fake product screenshots, decorative metrics, version labels, or status indicators;
- arbitrary font, icon, or library swaps that discard an existing system;
- visual novelty that weakens comprehension on high-frequency product UI.

These are prompts to justify or revise a choice, not unconditional bans. A pattern is valid when it fits the content,
identity, and usage frequency better than the alternatives.

## Verification

- Inspect the running UI at the relevant mobile and desktop viewports when available.
- Compare against Figma or approved baselines when supplied.
- Verify spacing, typography, content overflow, focus, and interaction states in rendered output, not code alone.
- Review motion separately under [motion.md](./motion.md).
- If the task is critique-only, report findings and do not edit source files.

## Provenance

Adapted as a small, tool-agnostic policy from ideas in
[Impeccable](https://github.com/pbakaus/impeccable/tree/b906b41462c26c359e452040994685ce6d8e4008)
(Apache-2.0) and
[Taste Skill](https://github.com/Leonxlnx/taste-skill/tree/98565e65bc3274ddf6eb0838734341714057178b)
(MIT). No upstream runtime, hooks, dependency defaults, or blanket aesthetic bans are included.
