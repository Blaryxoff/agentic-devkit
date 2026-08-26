# Playwright Visual Regression

Use Playwright Test for committed, repeatable regression assertions. Keep chrome-devtools MCP as the interactive browser
for navigation, state setup, DOM inspection, console/network diagnosis, and finding confirmation.

## Setup

- Reuse the project's installed `@playwright/test` and existing config. Every committed spec must resolve a pinned
  project dev dependency and run through the project package manager; a global package does not satisfy test imports or
  lockfile reproducibility. Add the project dependency/test files only with authorisation.
- A machine or container image may also provision a pinned global Playwright CLI plus Chrome/system dependencies so the
  tool is discoverable after restart or recreation. Treat that layer as availability/scaffolding only, never as the
  dependency for committed specs.
- Run visual baselines in one canonical Linux environment with the installed Chrome channel. Set `channel: "chrome"`
  in the visual project's `use` config so Playwright does not look for an unprovisioned managed Chromium. macOS and
  Linux font rasterisation require separate baselines when both are intentionally supported.
- Configure a focused visual project/spec set, fixed viewport and device scale, stable fixtures, ready fonts, disabled
  animation/caret, explicit colour scheme/locale/timezone, and `trace: "retain-on-failure"` plus
  `screenshot: "only-on-failure"`.
- Point `snapshotPathTemplate` at the project's approved baseline directory when it already uses
  `visual/baselines/`; keep transient results under `visual/output/` or the existing ignored test-results directory.
- Start with exact comparison. Add a narrow documented `maxDiffPixels`, `maxDiffPixelRatio`, or colour threshold only for
  proven platform rasterisation noise; never tune a threshold until a real layout defect passes.

## Assertion shape

Use page or locator assertions at named viewports and states:

```ts
// playwright.config.ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  projects: [{
    name: "visual-chrome",
    use: {
      baseURL: "http://127.0.0.1:<project-port>", // Resolve from project config; do not guess the port.
      channel: "chrome",
      // Required in unprivileged Firebat/Incus containers; omit where the Chrome sandbox works.
      launchOptions: { args: ["--no-sandbox"] },
    },
  }],
});
```

```ts
import { expect, test } from "@playwright/test";

test("dashboard desktop", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1200 });
  await page.goto("/dashboard");
  await page.evaluate(async () => await document.fonts.ready);
  await expect(page).toHaveScreenshot(["dashboard", "desktop.png"], {
    animations: "disabled",
    caret: "hide",
    scale: "css",
  });
});
```

Use project fixtures for authentication and stable data. Mask only volatile content that is outside the acceptance
criterion; prefer deterministic timestamps, IDs, and records over masks.

## Design references

- Export a Figma frame as the named expected snapshot only when it maps exactly to the live route, state, viewport, crop,
  and device scale.
- Use locator-level assertions for reference components or partial frames. Do not force a partial design into a full-page
  baseline.
- When browser rendering legitimately differs from the design export, keep the design separate. If the project already
  provides an offline image-diff tool, normalise viewport, DPR, crop, and image dimensions before using it and record its
  expected/actual/diff paths. Otherwise use the reference-geometry/inventory ledger plus the smallest useful matching
  live/reference crops; do not invent an ad hoc diff dependency or call a non-normalised comparison a pixel diff.
- Never approve browser output merely because a broad pixel threshold passes.

## Failure triage

1. Read the assertion, mismatch count/ratio, and expected/actual/diff paths.
2. Run the live DOM/layout audit and inspect the affected selectors' boxes/computed styles.
3. Fix structural, overflow, position, clipping, and typography causes from text evidence.
4. Open the smallest failed diff and matching baseline/reference crop only for unexplained paint-level deltas.
5. Rerun the focused assertion; run all configured viewports once after the implementation stabilises.

Do not open passing screenshots. Do not silently update snapshots. Update only named baselines after explicit user
approval and review of the generated diff.
