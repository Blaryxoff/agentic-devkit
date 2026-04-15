#!/usr/bin/env node
import path from "node:path";
import { fileURLToPath } from "node:url";

const TOOLKIT_DIR = path.dirname(fileURLToPath(import.meta.url));

function setupPlaywrightCache() {
  if (!process.env.PLAYWRIGHT_BROWSERS_PATH) {
    process.env.PLAYWRIGHT_BROWSERS_PATH = path.join(TOOLKIT_DIR, ".cache", "ms-playwright");
  }
}

function usage() {
  console.error(
    `Usage: visual-loop <command> --project-root <path> [options]

Commands:
  check       Capture screenshots and diff against baselines
  loop        Repeated check + file-watch cycle
  approve     Promote actual screenshots to baselines
  figma-map   Generate figma-map.json scaffold
  mcp-health  Verify Playwright MCP and visual pipeline health

Required:
  --project-root <path>   Target project root directory

Options:
  --config <path>         Config file (default: <project-root>/visual/config.json)
  --page <name>           Page name (check, loop, approve)
  --viewport <name>       Viewport name (check, loop, approve)`,
  );
  process.exit(1);
}

function parseArgs(argv) {
  const args = argv.slice(2);
  const command = args[0];

  if (!command || command.startsWith("--")) {
    usage();
  }

  const flags = {};
  for (let i = 1; i < args.length; i += 1) {
    if (args[i] === "--") break;
    const match = args[i].match(/^--([a-z-]+)(?:=(.+))?$/);
    if (match) {
      flags[match[1]] = match[2] ?? args[i + 1];
      if (!match[2]) i += 1;
    }
  }

  return { command, flags };
}

async function main() {
  const { command, flags } = parseArgs(process.argv);

  const projectRoot = flags["project-root"];
  if (!projectRoot) {
    console.error("Error: --project-root is required.\n");
    usage();
  }

  const resolvedProjectRoot = path.resolve(projectRoot);
  const configPath = flags.config ? path.resolve(flags.config) : undefined;

  setupPlaywrightCache();

  const params = {
    projectRoot: resolvedProjectRoot,
    configPath,
    page: flags.page,
    viewport: flags.viewport,
  };

  switch (command) {
    case "check": {
      const { runVisualCheck } = await import("./commands/check.mjs");
      const result = await runVisualCheck(params);

      for (const report of result.reports) {
        const statusIcon = report.status === "pass" ? "PASS" : report.status.toUpperCase();
        console.log(
          `[${statusIcon}] ${report.viewport}: mismatch=${report.mismatchPercent}% (${report.pixelsDifferent} px)`,
        );
      }

      if (!result.ok) process.exitCode = 1;
      break;
    }

    case "loop": {
      const { runVisualLoop } = await import("./commands/loop.mjs");
      const result = await runVisualLoop(params);
      if (!result.ok) process.exitCode = 1;
      break;
    }

    case "approve": {
      const { approveBaselines } = await import("./commands/approve.mjs");
      await approveBaselines(params);
      break;
    }

    case "figma-map": {
      const { exportFigmaMap } = await import("./commands/figma-map.mjs");
      await exportFigmaMap(params);
      break;
    }

    case "mcp-health": {
      const { mcpHealthCheck } = await import("./commands/mcp-health.mjs");
      await mcpHealthCheck(params);
      break;
    }

    default:
      console.error(`Unknown command: ${command}\n`);
      usage();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
