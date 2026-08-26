# Visual Implementation Loop

Canonical rules for visual frontend skills (`devkit-pixel-build`, `devkit-pixel-guard`). Skills cite sections here; do not duplicate these rules in skill bodies.

## 1. Prerequisites

1.1. Verify chrome-devtools MCP is reachable (`list_pages`). Read each tool schema before first use.

1.2. Verify the dev server is up; discover base URL from `visual/config.json`, env, README, or project config.

1.3. For `devkit-pixel-build`: Figma MCP must be connected when the user provides a Figma URL.

1.4. For `devkit-pixel-guard`: baseline screenshots must exist under `visual/baselines/<page>/` before changes. If missing, capture and get user approval first.

1.5. Use the project's existing Playwright Test setup for repeatable visual regression. When none exists, add
`@playwright/test` and a focused visual spec only when dependency/test-file changes are authorised. Missing Playwright
does not block a one-off design check; it does block claiming persistent regression protection. Apply
`plugins/frontend/conduct/playwright-visual-regression.md`.

1.6. Missing prerequisite → stop via `plugins/core/conduct/clarification-protocol.md`.

## 2. Page and viewport config

2.1. Read `visual/config.json` when present for `baseUrl`, `pages`, `viewports`, and `auth`.

2.2. When `visual/config.json` is absent, discover routes from the project router and viewports from CSS/Tailwind breakpoints.

2.3. Default viewports when nothing else is configured: mobile `390×844`, tablet `768×1024`, desktop `1440×1200`.

2.4. Ensure the target page key and `route` exist in `visual/config.json` when that file is used. Add the entry if the skill scaffolds visual config.

## 3. Browser session

3.1. Start from the browser tab already open when one exists; do not navigate away unless the task requires it.

3.2. Each chrome-devtools MCP server runs a throwaway profile under `--isolated` (`plugins/core/conduct/browser-qa-rules.md` §2.7). Tabs and logins from other projects and other sessions are not shared.

3.3. `take_snapshot` before acting on each page.

3.4. `list_pages` → `select_page` or `new_page` as needed.

3.5. Set viewport per check: `emulate` with `viewport: "<width>x<height>"` or `resize_page`.

3.6. Navigate with `navigate_page` to `<baseUrl><route>`.

3.7. Authenticated routes: `navigate_page` to login URL → `take_snapshot` → `fill_form` → submit → `wait_for` confirmation. Read credentials from `visual/config.json` first, then authenticate per `plugins/core/conduct/browser-qa-rules.md` §3.6–§3.8. A redirect to the login page is the cue to authenticate; it never blocks the visual check.

3.8. Wait for page readiness: `wait_for` with expected text, or `evaluate_script` checking `document.fonts.ready`.

3.9. Stabilize before measurement or capture — inject via `evaluate_script`:

```js
async () => {
  const style = document.createElement("style");
  style.textContent = `
    *, *::before, *::after {
      animation: none !important;
      transition: none !important;
      caret-color: transparent !important;
    }
    html { scroll-behavior: auto !important; }
  `;
  document.head.appendChild(style);
  await document.fonts.ready;
  return true;
}
```

3.10. Run `take_snapshot`, then the DOM/layout audit from `plugins/core/conduct/browser-qa-rules.md` §6.3 at every
page × viewport. Resolve or classify every viewport escape, clipped/scrollable region, actionable-element occlusion,
broken asset, and stale loading marker before pixel comparison.

3.11. Capture with `take_screenshot(filePath: ...)` only for design-reference comparison, baseline creation, or confirmed
visual-finding evidence. Save under `visual/output/<page>/<viewport>/actual.png`; do not attach or open a passing capture.

3.12. Apply `plugins/core/conduct/browser-qa-rules.md` §6 for evidence order and screenshot escalation.

## 4. Comparison

4.1. **Pixel build (Figma is source of truth):** extract whole-frame inventory, measured boxes, spacing, typography,
colours, and component states with `get_design_context`; use `get_screenshot` for paint-level reference. Compare stable
reference elements with live DOM bounding boxes and computed styles before inspecting pixels. Report every delta explicitly.

4.2. **Pixel guard (approved baselines are source of truth):** run focused Playwright Test specs using
`expect(page|locator).toHaveScreenshot()`. Keep expected, actual, and diff images local. Any unintended visual change is a
regression; a passing local comparison does not need model image input. Apply
`plugins/frontend/conduct/playwright-visual-regression.md`.

4.3. Configure visual specs deterministically: canonical Linux runtime, `use: { channel: "chrome" }`, fixed viewport and
device scale, stable fixtures, ready fonts, disabled animations/caret, explicit colour scheme/locale/timezone, and masking
only for genuinely volatile data. In an unprivileged container whose Chrome sandbox cannot start, also set
`launchOptions: { args: ["--no-sandbox"] }`. Store separate baselines when a different runtime is intentionally supported.

4.4. Fix in this order: structure/inventory → document overflow → element position/size/alignment → clipping/overlap →
spacing/typography → colours/borders/shadows → icons/images.

4.5. Read Playwright's textual mismatch result and diff path first. Inspect live DOM measurements next. Open only the
smallest failed diff/reference crop needed to explain a paint-level mismatch; use the full frame only for composition.

4.6. A clean DOM audit cannot prove paint fidelity, and a passing pixel threshold cannot prove exact spacing, correct
semantics, or absence of masked defects. Require both applicable gates plus the design inventory.

## 5. Iteration

5.1. After code fixes, reload or re-navigate and re-stabilize. Rerun the affected DOM audit and focused Playwright
assertion when configured; otherwise rerun the measured inventory/geometry and matching-crop comparison. Then run the
full configured viewport set once before completion.

5.2. Keep all configured viewports passing; do not optimize for only one breakpoint.

5.3. Prefer design token / layout fixes over one-off pixel hacks.

5.4. Stop when all viewports pass comparison or the user ends the session.

## 6. Baselines

6.1. Never silently update baseline files.

6.2. Baseline approval requires explicit user confirmation.

6.3. After approval, update only the named Playwright snapshot(s) or save the confirmed Chrome capture under
`visual/baselines/<page>/<viewport>.png`. Review the generated diff before updating; never use a blanket snapshot update.

## 7. MCP tools

**chrome-devtools:** `list_pages`, `select_page`, `new_page`, `navigate_page`, `resize_page`, `emulate`, `take_snapshot`, `take_screenshot`, `fill`, `fill_form`, `click`, `wait_for`, `evaluate_script`, `handle_dialog`.

**Playwright Test:** committed deterministic assertions and local visual diffs only; never interactive agent browsing.

**Figma** (pixel-build only): `get_design_context`, `get_screenshot`.

## 8. Hard rules

8.1. Do not use direct Playwright scripts, Playwright MCP, or removed `pnpm ui:*` / visual-loop commands. Playwright Test
is the only allowed second browser path and only for deterministic committed regression checks.

8.2. chrome-devtools MCP uses the installed Google Chrome browser — independent of any Playwright browser cache.

8.3. Do not introduce project dependencies without user approval. Committed specs require a pinned project-local
`@playwright/test`; a provisioning-managed global CLI/browser runtime is allowed for durable tool availability but never
replaces the local dependency or project package-manager command.

8.4. Do not overwrite `visual/baselines/` unless the user explicitly approves.
