# Visual Implementation Loop

Canonical rules for visual frontend skills (`devkit-pixel-build`, `devkit-pixel-guard`). Skills cite sections here; do not duplicate these rules in skill bodies.

## 1. Prerequisites

1.1. Verify chrome-devtools MCP is reachable (`list_pages`). Read each tool schema before first use.

1.2. Verify the dev server is up; discover base URL from `visual/config.json`, env, README, or project config.

1.3. For `devkit-pixel-build`: Figma MCP must be connected when the user provides a Figma URL.

1.4. For `devkit-pixel-guard`: baseline screenshots must exist under `visual/baselines/<page>/` before changes. If missing, capture and get user approval first.

1.5. Missing prerequisite → stop via `plugins/core/conduct/clarification-protocol.md`.

## 2. Page and viewport config

2.1. Read `visual/config.json` when present for `baseUrl`, `pages`, `viewports`, and `auth`.

2.2. When `visual/config.json` is absent, discover routes from the project router and viewports from CSS/Tailwind breakpoints.

2.3. Default viewports when nothing else is configured: mobile `390×844`, tablet `768×1024`, desktop `1440×1200`.

2.4. Ensure the target page key and `route` exist in `visual/config.json` when that file is used. Add the entry if the skill scaffolds visual config.

## 3. Browser session

3.1. Start from the browser tab already open when one exists; do not navigate away unless the task requires it.

3.2. `take_snapshot` before acting on each page.

3.3. `list_pages` → `select_page` or `new_page` as needed.

3.4. Set viewport per check: `emulate` with `viewport: "<width>x<height>"` or `resize_page`.

3.5. Navigate with `navigate_page` to `<baseUrl><route>`.

3.6. Authenticated routes: `navigate_page` to login URL → `take_snapshot` → `fill_form` → submit → `wait_for` confirmation. Discover credentials from `visual/config.json`, seeders, or env examples — never invent secrets.

3.7. Wait for page readiness: `wait_for` with expected text, or `evaluate_script` checking `document.fonts.ready`.

3.8. Stabilize before screenshot — inject via `evaluate_script`:

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

3.9. `take_screenshot` with `filePath` for every page × viewport check. Save captures under `visual/output/<page>/<viewport>/actual.png`.

3.10. Apply `plugins/core/conduct/browser-qa.md` §6.1–6.3 for general session discipline.

## 4. Comparison

4.1. **Pixel build (Figma is source of truth):** `get_design_context` or `get_screenshot` from Figma MCP; compare layout, spacing, typography, colors, icons, and component presence against the live capture. Report every delta explicitly.

4.2. **Pixel guard (baselines are source of truth):** read `visual/baselines/<page>/<viewport>.png`; compare against the fresh `actual.png`. Any unintended visual change is a regression.

4.3. Fix priority: layout → spacing → typography → sizing → alignment → icons.

4.4. A visually clean screenshot is not sufficient for spacing or icons — verify measured Figma values and icon inventory explicitly.

## 5. Iteration

5.1. After code fixes, reload or re-navigate, re-stabilize, and re-capture every affected viewport.

5.2. Keep all configured viewports passing; do not optimize for only one breakpoint.

5.3. Prefer design token / layout fixes over one-off pixel hacks.

5.4. Stop when all viewports pass comparison or the user ends the session.

## 6. Baselines

6.1. Never silently update baseline files.

6.2. Baseline approval requires explicit user confirmation.

6.3. After approval, save the confirmed capture: `take_screenshot` with `filePath` set to `visual/baselines/<page>/<viewport>.png`.

## 7. MCP tools

**chrome-devtools:** `list_pages`, `select_page`, `new_page`, `navigate_page`, `resize_page`, `emulate`, `take_snapshot`, `take_screenshot`, `fill`, `fill_form`, `click`, `wait_for`, `evaluate_script`, `handle_dialog`.

**Figma** (pixel-build only): `get_design_context`, `get_screenshot`.

## 8. Hard rules

8.1. Do not use Playwright, Chromium, or `pnpm ui:*` / visual-loop CLI commands.

8.2. chrome-devtools MCP uses the installed Google Chrome browser — independent of any Playwright browser cache.

8.3. Do not introduce new dependencies without user approval.

8.4. Do not overwrite `visual/baselines/` unless the user explicitly approves.
