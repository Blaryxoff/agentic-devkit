# Visual Loop How-To

## Quick Start

```bash
# One command from parent project root
node toolkits/agentic-devkit/visual-loop/bootstrap.mjs .
```

## What Bootstrap Creates

Inside the target project:

- `visual/config.json` — server, viewports, thresholds, pages
- `visual/baselines/home/meta.json` — starter page metadata
- `visual/output/.gitkeep` — output directory placeholder

Bootstrap also:
- installs toolkit deps in `toolkits/agentic-devkit/visual-loop` via `pnpm install`
- installs Playwright Chromium via `pnpm exec playwright install chromium` (toolkit-local cache)
- adds `ui:*` scripts to parent `package.json`
- adds `visual/` to parent `.gitignore`

## Commands

All commands run from the toolkit CLI with `--project-root` pointing to your project:

```bash
VISUAL_CLI="node toolkits/agentic-devkit/visual-loop/cli.mjs"

# Capture + diff against baselines
$VISUAL_CLI check --project-root . --page home --viewport desktop

# Repeated check + file-watch loop
$VISUAL_CLI loop --project-root . --page home

# Promote actual screenshots to baselines (after design approval)
$VISUAL_CLI approve --project-root . --page home --viewport desktop

# Generate figma-map.json scaffold
$VISUAL_CLI figma-map --project-root .

# Verify Playwright MCP and visual pipeline health
$VISUAL_CLI mcp-health --project-root .
```

Usage with injected aliases: `pnpm ui:check -- --page home --viewport desktop`

## Where Dependencies Live

All runtime dependencies (`playwright`, `pixelmatch`, `pngjs`, `globby`, `execa`) are declared in `toolkits/agentic-devkit/visual-loop/package.json` and installed inside the toolkit only. Parent projects stay clean.

Playwright browsers are cached at `toolkits/agentic-devkit/visual-loop/.cache/ms-playwright` to avoid polluting the parent project or global cache.

## Authentication

To capture pages behind login, configure the `auth` block in `visual/config.json`:

```json
{
  "auth": {
    "loginUrl": "/login",
    "fields": {
      "email": "[name=email]",
      "password": "[name=password]"
    },
    "submit": "button[type=submit]",
    "waitAfterLogin": null,
    "credentials": {
      "email": "",
      "password": ""
    }
  }
}
```

- `loginUrl` -- route to navigate to for login (relative to `baseUrl`).
- `fields` -- CSS selectors for the email and password inputs.
- `submit` -- CSS selector for the submit button.
- `waitAfterLogin` -- optional CSS selector to confirm successful login. If `null`, waits for URL to change.
- `credentials` -- if empty, the CLI prompts interactively.

Auth state is cached at `visual/.auth-state.json` for 30 minutes.

Per-page control: set `"auth": false` on a page entry to skip auth for public routes.

## Production Safety

`agentic-devkit` is strictly development-only tooling:

- Do **not** run `ui:*` commands in production pipelines.
- Do **not** include `toolkits/` or its `node_modules` in production Docker images or deploy artifacts.
- In multi-stage Docker builds, copy only application runtime files in the final stage.
