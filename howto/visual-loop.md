# Visual Loop How-To

## Quick Start

```bash
# Scaffold visual/ folder in your project
node toolkits/agentic-devkit/visual-loop/bootstrap.mjs /absolute/path/to/project

# Install toolkit deps (one-time, inside toolkit only)
cd toolkits/agentic-devkit/visual-loop && npm install && npx playwright install chromium
```

## What Bootstrap Creates

Inside the target project:

- `visual/config.json` — server, viewports, thresholds, pages
- `visual/baselines/home/meta.json` — starter page metadata
- `visual/output/.gitkeep` — output directory placeholder

No scripts or dependencies are added to the parent `package.json`.

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

## Optional Script Aliases

Add to your project's `package.json` for convenience:

```json
{
  "scripts": {
    "ui:check": "node toolkits/agentic-devkit/visual-loop/cli.mjs check --project-root .",
    "ui:loop": "node toolkits/agentic-devkit/visual-loop/cli.mjs loop --project-root .",
    "ui:approve": "node toolkits/agentic-devkit/visual-loop/cli.mjs approve --project-root .",
    "ui:figma-map": "node toolkits/agentic-devkit/visual-loop/cli.mjs figma-map --project-root .",
    "ui:mcp-health": "node toolkits/agentic-devkit/visual-loop/cli.mjs mcp-health --project-root ."
  }
}
```

Usage with aliases: `pnpm ui:check -- --page home --viewport desktop`

## Where Dependencies Live

All runtime dependencies (`playwright`, `pixelmatch`, `pngjs`, `globby`, `execa`) are declared in `toolkits/agentic-devkit/visual-loop/package.json` and installed inside the toolkit only. Parent projects stay clean.

Playwright browsers are cached at `toolkits/agentic-devkit/visual-loop/.cache/ms-playwright` to avoid polluting the parent project or global cache.

## Production Safety

`agentic-devkit` is strictly development-only tooling:

- Do **not** run `ui:*` commands in production pipelines.
- Do **not** include `toolkits/` or its `node_modules` in production Docker images or deploy artifacts.
- In multi-stage Docker builds, copy only application runtime files in the final stage.
