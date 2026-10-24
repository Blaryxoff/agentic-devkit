# Visual Workflow

Use this shared workflow for reference implementation and visual regression protection. Resolve the target's actual runtime before choosing inspection tools; platform-specific mechanics live in the enabled plugins' conduct.

## 1. Resolve the verification adapter

1. Resolve enabled plugins and transitive dependencies from `.devkit/toolkit.json`; inspect target manifests, entry points, and project instructions to identify the rendered surface and its host.
2. Read the relevant plugin indexes and follow their visual/interaction verification routes. Select the adapter matching the surface; combine renderer checks with host lifecycle/window checks when the product spans both.
3. Use the selected adapter's tools, commands, readiness/authentication path, measurement units, capture method, and baseline conventions. Do not infer device behavior from a different runtime or require a browser tool for a surface it cannot inspect.
4. Report unavailable tools, references, login, or target environments precisely. Missing persistent assertion tooling blocks claiming regression protection; it need not block a clearly labeled one-off comparison when actual evidence is available. Add dependencies only with approval.

## 2. Establish the source of truth

- Apply [design-quality.md](./design-quality.md) and [motion.md](./motion.md) for design decisions, keeping implementation mechanisms in the selected adapter.
- For reference implementation, resolve the supplied design context and matching frame/state. Record whole-frame inventory, measured bounds, spacing, typography, colors, assets/icons, component variants, and responsive/adaptive constraints before editing.
- For a guarded change, verify approved baselines against current rendering for every affected target/state/configuration before editing. If missing, capture current output and obtain explicit approval; current rendering is not automatically correct.
- Classify the requested change: visual-preserving refactor/token extraction, intentional restyle, or targeted adaptive-layout correction. Preserve public component contracts and unrelated surfaces.
- Reuse existing components, tokens, icon systems, and layout patterns. Resolve missing required assets/components/tokens from references or the user rather than silently substituting a different design.

## 3. Implement and compare

1. Activate `devkit-coder` before edits. Implement the smallest complete page/screen/component change, top-down, with existing primitives and project conventions.
2. Enumerate every affected route/screen/state × viewport/window/device/runtime configuration using the project's config when present. Include auth, data, theme, scale, locale, orientation, and interaction prerequisites required by the adapter.
3. Stabilize data, fonts/assets, clocks, animation/caret, and environment through the adapter. Inspect the live structural/layout/accessibility state, classify overflow, occlusion, clipping, broken assets, and stale loading markers, then perform the applicable visual comparison.
4. Compare complete composition and element inventory before details. Verify resolved spacing values against measured reference values explicitly; a similar screenshot does not prove correct padding or token resolution. Audit each icon's presence, placement, glyph, dimensions, stroke, and color.
5. Normalize reference/actual scale, dimensions, crop, units, and environment before a pixel comparison. Keep design-reference fidelity distinct from a current-output regression baseline; label assertions that do not compare to the design.
6. Read assertion/mismatch results and expected/actual/diff paths first, inspect live measurements next, then the smallest useful matching image crops. Full frames establish composition; selective crops resolve ambiguous paint differences.
7. Fix structure/inventory → overflow → position/size/alignment → clipping/overlap → spacing/typography → colors/materials → icons/images. Prefer systemic token/layout fixes over isolated pixel patches.

## 4. Iterate, approve, and report

- Re-run affected cells after each correction, then the full configured target set once before completion. Keep a traceable per-cell ledger; do not sacrifice one target to make another pass.
- Treat every unexplained visual delta in a pure refactor as a regression. For intentional changes, separate requested deltas from collateral regressions, restore the latter, and present the concrete intentional changes for approval.
- Never overwrite baselines, mask changed controls, or broaden thresholds merely to pass. After explicit approval, update only named snapshots/captures and review the resulting diff; never run a blanket update.
- For guarded work, require both applicable layout/accessibility checks and the adapter's persistent assertions to claim full protection. State clearly when only manual evidence was available.
- Report modified files, reused/new components/tokens, every target/state/configuration checked, structural results, reference/diff evidence, intentional delta approvals, unresolved discrepancies, and unavailable environments. Leave visual output ready for review rather than declaring unverified targets matched.
