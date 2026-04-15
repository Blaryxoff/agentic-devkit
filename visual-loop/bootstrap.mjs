#!/usr/bin/env node
import fs from "node:fs/promises";
import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const PACKAGE_SCRIPTS = {
  "ui:check": "node toolkits/agentic-devkit/visual-loop/cli.mjs check --project-root .",
  "ui:loop": "node toolkits/agentic-devkit/visual-loop/cli.mjs loop --project-root .",
  "ui:approve": "node toolkits/agentic-devkit/visual-loop/cli.mjs approve --project-root .",
  "ui:figma-map": "node toolkits/agentic-devkit/visual-loop/cli.mjs figma-map --project-root .",
  "ui:mcp-health": "node toolkits/agentic-devkit/visual-loop/cli.mjs mcp-health --project-root .",
};

async function exists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function copyIfMissing(source, destination) {
  if (await exists(destination)) {
    return false;
  }
  await fs.mkdir(path.dirname(destination), { recursive: true });
  await fs.copyFile(source, destination);
  return true;
}

function normalizeEnvValue(value) {
  const trimmed = value.trim();
  if (
    (trimmed.startsWith("\"") && trimmed.endsWith("\"")) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return trimmed.slice(1, -1).trim();
  }
  return trimmed;
}

async function readAppUrlFromEnv(targetRoot) {
  const envPath = path.join(targetRoot, ".env");
  if (!(await exists(envPath))) {
    return null;
  }

  const envRaw = await fs.readFile(envPath, "utf8");
  const lines = envRaw.split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) {
      continue;
    }

    const match = trimmed.match(/^APP_URL\s*=\s*(.+)$/);
    if (!match) {
      continue;
    }

    const parsed = normalizeEnvValue(match[1]);
    if (!parsed) {
      return null;
    }

    try {
      const normalized = new URL(parsed);
      return normalized.toString().replace(/\/$/, "");
    } catch {
      console.warn(`Ignoring APP_URL from .env because it is not a valid URL: ${parsed}`);
      return null;
    }
  }

  return null;
}

async function scaffoldConfigIfMissing(templatePath, destinationPath, appUrl = null) {
  if (await exists(destinationPath)) {
    return false;
  }

  const raw = await fs.readFile(templatePath, "utf8");
  const config = JSON.parse(raw);

  if (appUrl) {
    config.baseUrl = appUrl;
    config.server = {
      ...(config.server ?? {}),
      readyUrl: appUrl,
    };
  }

  await fs.mkdir(path.dirname(destinationPath), { recursive: true });
  await fs.writeFile(destinationPath, `${JSON.stringify(config, null, 2)}\n`, "utf8");
  return true;
}

function parseArgs(argv) {
  const args = argv.slice(2);
  let target = null;

  for (const arg of args) {
    if (arg === "--help") {
      printHelp();
      process.exit(0);
    } else if (!arg.startsWith("--")) {
      target = arg;
    }
  }

  return {
    target: target ? path.resolve(target) : process.cwd(),
  };
}

function runCommand(command, args, cwd, env = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd,
      stdio: "inherit",
      shell: process.platform === "win32",
      env: {
        ...process.env,
        ...env,
      },
    });

    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) {
        resolve();
        return;
      }
      reject(new Error(`Command failed (${command} ${args.join(" ")}), exit code ${code}`));
    });
  });
}

async function upsertPackageJsonScripts(targetRoot) {
  const packageJsonPath = path.join(targetRoot, "package.json");
  if (!(await exists(packageJsonPath))) {
    console.warn(`Skipping scripts injection. package.json not found in ${targetRoot}`);
    return;
  }

  const raw = await fs.readFile(packageJsonPath, "utf8");
  const pkg = JSON.parse(raw);
  pkg.scripts = {
    ...(pkg.scripts ?? {}),
    ...PACKAGE_SCRIPTS,
  };

  await fs.writeFile(packageJsonPath, `${JSON.stringify(pkg, null, 2)}\n`, "utf8");
  console.log("Injected ui:* scripts into parent package.json");
}

async function ensureVisualIgnored(targetRoot) {
  const gitignorePath = path.join(targetRoot, ".gitignore");
  const ignoreRule = "visual/";
  const visualIgnorePattern = /^\s*\/?visual\/?\s*(?:#.*)?$/;

  if (!(await exists(gitignorePath))) {
    await fs.writeFile(gitignorePath, `${ignoreRule}\n`, "utf8");
    console.log("Added visual/ to .gitignore");
    return;
  }

  const raw = await fs.readFile(gitignorePath, "utf8");
  const lines = raw.split(/\r?\n/);
  if (lines.some((line) => visualIgnorePattern.test(line))) {
    return;
  }

  const normalized = raw.endsWith("\n") ? raw : `${raw}\n`;
  await fs.writeFile(gitignorePath, `${normalized}${ignoreRule}\n`, "utf8");
  console.log("Added visual/ to .gitignore");
}

function printHelp() {
  console.log(
    `Usage: bootstrap.mjs [target-dir] [options]

Scaffold the visual/ folder structure in a target project.

Arguments:
  target-dir        Project root (default: current directory)

Options:
  --help            Show this help message

Scaffolded structure:
  <target>/visual/config.json
  <target>/visual/baselines/home/meta.json
  <target>/visual/output/.gitkeep

This command also:
  1) installs visual-loop dependencies in toolkits/agentic-devkit/visual-loop
  2) installs Playwright Chromium in toolkit-local cache
  3) injects ui:* scripts into parent package.json
  4) adds visual/ to parent .gitignore`,
  );
}

async function bootstrap(targetRoot) {
  const scriptDir = path.dirname(fileURLToPath(import.meta.url));
  const templateRoot = path.join(scriptDir, "template");
  const visualDir = path.join(targetRoot, "visual");
  const playwrightCachePath = path.join(scriptDir, ".cache", "ms-playwright");
  const playwrightCliPath = path.join(
    scriptDir,
    "node_modules",
    "playwright",
    "cli.js",
  );
  const appUrl = await readAppUrlFromEnv(targetRoot);

  const scaffolded = [];

  if (await scaffoldConfigIfMissing(
    path.join(templateRoot, "config.json"),
    path.join(visualDir, "config.json"),
    appUrl,
  )) {
    scaffolded.push("visual/config.json");
  }

  if (await copyIfMissing(
    path.join(templateRoot, "baselines", "home", "meta.json"),
    path.join(visualDir, "baselines", "home", "meta.json"),
  )) {
    scaffolded.push("visual/baselines/home/meta.json");
  }

  if (await copyIfMissing(
    path.join(templateRoot, "output", ".gitkeep"),
    path.join(visualDir, "output", ".gitkeep"),
  )) {
    scaffolded.push("visual/output/.gitkeep");
  }

  if (scaffolded.length > 0) {
    console.log(`Scaffolded:\n  ${scaffolded.join("\n  ")}`);
  } else {
    console.log("All scaffold files already exist. Nothing to do.");
  }

  if (appUrl) {
    console.log(`Detected APP_URL from .env: ${appUrl}`);
  }

  await upsertPackageJsonScripts(targetRoot);
  await ensureVisualIgnored(targetRoot);

  console.log("Installing visual-loop dependencies...");
  await runCommand("pnpm", ["--dir", scriptDir, "install", "--ignore-workspace"], scriptDir);

  console.log("Installing Playwright Chromium...");
  await runCommand(
    "node",
    [playwrightCliPath, "install", "chromium"],
    scriptDir,
    { PLAYWRIGHT_BROWSERS_PATH: playwrightCachePath },
  );

  console.log(`Visual loop scaffold ready in ${targetRoot}`);
}

async function main() {
  const args = parseArgs(process.argv);
  await bootstrap(args.target);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
