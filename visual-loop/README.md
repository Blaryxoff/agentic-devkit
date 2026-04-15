# Visual Loop Tool

Self-contained screenshot+diff pipeline for deterministic UI verification. All dependencies live inside the toolkit; parent projects require zero visual-related `devDependencies`.

> **Development-only tooling.** Never include `agentic-devkit` or its `node_modules` in production builds, Docker images, or deploy artifacts.

## Setup

```bash
# 1. Install toolkit dependencies (one-time, inside the toolkit)
cd toolkits/agentic-devkit/visual-loop && npm install

# 2. Install Playwright browsers (cached inside toolkit)
npx playwright install chromium

# 3. Scaffold visual/ folder in your project
node toolkits/agentic-devkit/visual-loop/bootstrap.mjs /path/to/project
```

This creates project-local files only:

```
<project>/visual/
  config.json                 Main configuration
  baselines/home/meta.json    Page metadata
  output/.gitkeep             Output directory
```

No scripts or dependencies are injected into the parent `package.json`.

## CLI Usage

All commands require `--project-root`:

```bash
# Capture + diff
node toolkits/agentic-devkit/visual-loop/cli.mjs check \
  --project-root . --page home --viewport desktop

# Repeated check + file-watch loop
node toolkits/agentic-devkit/visual-loop/cli.mjs loop \
  --project-root . --page home

# Promote actual screenshots to baselines
node toolkits/agentic-devkit/visual-loop/cli.mjs approve \
  --project-root . --page home --viewport desktop

# Generate figma-map.json scaffold
node toolkits/agentic-devkit/visual-loop/cli.mjs figma-map \
  --project-root .

# Verify Playwright MCP and visual pipeline health
node toolkits/agentic-devkit/visual-loop/cli.mjs mcp-health \
  --project-root .
```

### Optional `package.json` aliases

Add shorthand scripts to your project (not required):

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

Then run: `pnpm ui:check -- --page home --viewport desktop`

## Project Layout

```
<project>/
  visual/
    config.json               Server, viewports, thresholds, pages
    baselines/
      home/
        meta.json             Per-page metadata
        desktop.png           Approved baseline (after approve)
    output/
      home/
        desktop/
          actual.png          Latest capture
          diff.png            Pixel diff
          report.json         Machine-readable report
```

## Configuration

`visual/config.json` controls server, viewports, thresholds, loop behavior, and page definitions. See `template/config.json` for the full default.

## CI / Production Guardrails

- Do **not** run `ui:*` commands in production pipelines.
- Do **not** package `toolkits/` or its `node_modules` into production images.
- In Docker multi-stage builds, copy only application runtime files in the production stage.
- Playwright browsers are cached at `toolkits/agentic-devkit/visual-loop/.cache/ms-playwright`.
