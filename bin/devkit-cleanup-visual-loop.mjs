#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";

const UI_SCRIPT_KEYS = [
  "ui:check",
  "ui:loop",
  "ui:approve",
  "ui:figma-map",
  "ui:mcp-health",
];

async function exists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function cleanupProject(projectRoot) {
  const resolved = path.resolve(projectRoot);
  const packageJsonPath = path.join(resolved, "package.json");
  const changes = [];

  if (await exists(packageJsonPath)) {
    const raw = await fs.readFile(packageJsonPath, "utf8");
    const pkg = JSON.parse(raw);
    const scripts = { ...(pkg.scripts ?? {}) };
    let removed = 0;

    for (const key of UI_SCRIPT_KEYS) {
      if (key in scripts) {
        delete scripts[key];
        removed += 1;
      }
    }

    if (removed > 0) {
      pkg.scripts = scripts;
      await fs.writeFile(packageJsonPath, `${JSON.stringify(pkg, null, 2)}\n`, "utf8");
      changes.push(`removed ${removed} ui:* script(s) from package.json`);
    }
  }

  const authStatePath = path.join(resolved, "visual", ".auth-state.json");
  if (await exists(authStatePath)) {
    await fs.unlink(authStatePath);
    changes.push("removed visual/.auth-state.json");
  }

  return { projectRoot: resolved, changes };
}

function printHelp() {
  console.log(`Usage: devkit-cleanup-visual-loop.mjs <project-root> [more-project-roots...]

Removes visual-loop / Playwright bootstrap artifacts from devkit consumer projects:
  - ui:check, ui:loop, ui:approve, ui:figma-map, ui:mcp-health from package.json
  - visual/.auth-state.json (Playwright auth cache)

Keeps visual/config.json, baselines, and output — still used by chrome-devtools pixel skills.`);
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    printHelp();
    process.exit(args.length === 0 ? 1 : 0);
  }

  for (const target of args) {
    const result = await cleanupProject(target);
    if (result.changes.length === 0) {
      console.log(`${result.projectRoot}: nothing to clean`);
      continue;
    }
    console.log(`${result.projectRoot}:`);
    for (const line of result.changes) {
      console.log(`  - ${line}`);
    }
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
