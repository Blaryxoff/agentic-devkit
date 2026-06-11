---
name: devkit-mcp2cli
description: call MCP, OpenAPI, or GraphQL tools as one-shot CLI commands via mcp2cli. Use when a workflow needs a small terminal-callable integration without writing a Hermes plugin, running a daemon, or loading huge tool schemas into the agent context.
---

# mcp2cli — One-shot Tool Bridge

Use `mcp2cli` when you need to call an external tool surface from shell/script/cron as a **single command that exits**.

Good fits:
- OpenAPI endpoints where `curl` is tedious but the schema exists.
- stdio MCP servers that should be invoked from terminal scripts, not registered permanently.
- Small JSON pipelines where Hermes can inspect filtered output.

Do **not** use it to create a resident service, a second scheduler, or a permanent integration before a repeated need is proven.

## Fast path

Prefer `uvx` so nothing is globally installed:

```bash
uvx mcp2cli --help
uvx mcp2cli --spec https://petstore3.swagger.io/api/v3/openapi.json --list
```

For repeated local use, install as a uv tool only after the one-shot path proves useful:

```bash
uv tool install mcp2cli
```

## OpenAPI workflow

1. List available operations:

```bash
uvx mcp2cli --spec <openapi-url-or-file> --list
```

2. Call one operation and return JSON:

```bash
uvx mcp2cli --spec <openapi-url-or-file> <operation-name> \
  --json \
  --param key=value
```

3. Filter before handing output to the agent:

```bash
uvx mcp2cli --spec <openapi-url-or-file> <operation-name> --json \
  | jq '{id, name, state}'
```

## Auth

Keep secrets in environment variables or files, never inline in committed docs/logs:

```bash
export API_TOKEN=***
uvx mcp2cli --spec <spec> \
  --auth-header 'Authorization:env:API_TOKEN' \
  <operation> --json
```

If the target supports bearer tokens only through normal headers, prefer a wrapper script that reads env and prints a redacted command summary.

## stdio MCP workflow

Use this only for MCP servers that are safe to start on demand and exit with the command:

```bash
uvx mcp2cli --mcp-stdio 'npx -y <mcp-server-package>' --list
uvx mcp2cli --mcp-stdio 'npx -y <mcp-server-package>' <tool-name> --json
```

If the MCP server requires a browser profile, DB, long warm-up, or resident daemon, stop and reconsider. Registering a Hermes MCP server may be cleaner for frequent interactive use.

## Hermes/devkit use cases

- Cron scripts that need one external API call and want JSON back.
- Temporary API exploration before deciding whether to build a proper Hermes tool.
- Calling a stdio MCP server from a Ralphex/devkit skill without adding it to every project config.

## Verification

For every new use:

```bash
uvx mcp2cli --spec <spec> --list >/tmp/mcp2cli.list
head -40 /tmp/mcp2cli.list
```

Then run one harmless read-only call and confirm:
- command exits cleanly;
- output is bounded and machine-readable;
- no background process remains;
- no secret is printed.

## Hard rules

- Prefer read-only operations until the command shape is proven.
- Do not commit tokens, generated schemas containing credentials, or raw giant JSON dumps.
- Do not replace a stable first-class Hermes tool with `mcp2cli` just because it is shiny.
- If a command becomes mission-critical, promote it into a small script/skill with explicit verification.
