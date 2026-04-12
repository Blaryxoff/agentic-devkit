# Visual Loop How-To

Use the shared visual loop bootstrap from `agentic-devkit`:

```bash
node toolkits/agentic-devkit/visual-loop/bootstrap.mjs /absolute/path/to/project
```

What it installs into the target project:
- `scripts/visual/*` visual loop scripts
- `visual.config.json` starter config
- `visual-baselines/home/meta.json`
- `visual-output/.gitkeep`
- package scripts: `ui:check`, `ui:loop`, `ui:approve`, `ui:figma-map`, `ui:mcp-health`
- dev dependencies: `playwright`, `pixelmatch`, `pngjs`, `globby`, `execa`
