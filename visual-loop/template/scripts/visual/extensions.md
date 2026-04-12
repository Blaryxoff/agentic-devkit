# Visual Loop Extensions

## Phase 2
- Add per-page clip regions via `visual-baselines/<page>/meta.json`.
- Add dark-mode baselines by extending viewport keys with theme suffixes.
- Improve hotspot labels using optional selector maps in metadata.
- Add CI execution with `pnpm ui:check <page>` per critical route.
- Add multi-page batch mode in `check.mjs` for route lists.

## Phase 3
- Ingest Figma-exported token/measurement metadata into `figma-map.json`.
- Add DOM-aware hotspot naming from selector bounding boxes.
- Add typography/token drift checks (font family, size, line-height, spacing).
- Add optional full-page stitch mode for long layouts.
- Add adapter modules for non-Vite frameworks (Next, Nuxt, static sites).
