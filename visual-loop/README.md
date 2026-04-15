# Visual Loop Tool

Self-contained screenshot+diff pipeline for deterministic UI verification. All dependencies live inside the toolkit; parent projects require zero visual-related `devDependencies`.

> **Development-only tooling.** Never include `agentic-devkit` or its `node_modules` in production builds, Docker images, or deploy artifacts.

## Setup

```bash
# One command setup from your project root
node toolkits/agentic-devkit/visual-loop/bootstrap.mjs .
```

This single command:
- scaffolds project-local visual files
- installs `visual-loop` dependencies inside toolkit submodule via `pnpm install`
- installs Playwright Chromium via `pnpm exec playwright install chromium` in toolkit-local cache
- injects `ui:*` scripts into parent `package.json`
- adds `visual/` to parent `.gitignore`

Scaffolded project files:

```
<project>/visual/
  config.json                 Main configuration
  baselines/home/meta.json    Page metadata
  output/.gitkeep             Output directory
```

Dependencies still stay inside toolkit (`toolkits/agentic-devkit/visual-loop`), while parent gets only script aliases.

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

After bootstrap, parent `package.json` has `ui:*` scripts, so you can run:
`pnpm ui:check -- --page home --viewport desktop`

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

## Authentication

For pages behind login, add an `auth` block to `visual/config.json`:

```json
{
  "auth": {
    "loginUrl": "/login",
    "fields": {
      "email": "[name=email]",
      "password": "[name=password]"
    },
    "submit": "button[type=submit]",
    "waitAfterLogin": "a[href*=dashboard]",
    "credentials": {
      "email": "test@example.com",
      "password": "secret"
    }
  }
}
```

- If `credentials.email` or `credentials.password` are empty, the CLI prompts interactively.
- Auth state is saved to `visual/.auth-state.json` and reused for 30 minutes.
- To skip auth for a specific page, set `"auth": false` on that page entry.

## CI / Production Guardrails

- Do **not** run `ui:*` commands in production pipelines.
- Do **not** package `toolkits/` or its `node_modules` into production images.
- In Docker multi-stage builds, copy only application runtime files in the production stage.
- Playwright browsers are cached at `toolkits/agentic-devkit/visual-loop/.cache/ms-playwright`.
