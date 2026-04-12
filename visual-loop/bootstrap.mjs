#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REQUIRED_DEV_DEPENDENCIES = {
  execa: "^9.6.1",
  globby: "^16.2.0",
  pixelmatch: "^7.1.0",
  playwright: "^1.59.1",
  pngjs: "^7.0.0",
};

const PACKAGE_SCRIPTS = {
  "ui:check": "node scripts/visual/check.mjs",
  "ui:loop": "node scripts/visual/loop.mjs",
  "ui:approve": "node scripts/visual/approve.mjs",
  "ui:figma-map": "node scripts/visual/export-figma-map.mjs",
  "ui:mcp-health": "node scripts/visual/mcp-healthcheck.mjs",
};

async function exists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function copyFile(source, destination) {
  await fs.mkdir(path.dirname(destination), { recursive: true });
  await fs.copyFile(source, destination);
}

async function writeJson(filePath, data) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, `${JSON.stringify(data, null, 2)}\n`, "utf8");
}

function parseArgs(argv) {
  const args = argv.slice(2);
  return {
    target: args[0] ? path.resolve(args[0]) : process.cwd(),
  };
}

async function upsertPackageJson(targetRoot) {
  const packageJsonPath = path.join(targetRoot, "package.json");
  const packageJsonExists = await exists(packageJsonPath);
  if (!packageJsonExists) {
    console.warn(`Skipping package.json update. File not found in ${targetRoot}`);
    return;
  }

  const pkgRaw = await fs.readFile(packageJsonPath, "utf8");
  const pkg = JSON.parse(pkgRaw);
  pkg.scripts = {
    ...(pkg.scripts ?? {}),
    ...PACKAGE_SCRIPTS,
  };
  pkg.devDependencies = {
    ...(pkg.devDependencies ?? {}),
    ...REQUIRED_DEV_DEPENDENCIES,
  };

  await writeJson(packageJsonPath, pkg);
  console.log("Updated package.json scripts and devDependencies.");
}

async function bootstrap(targetRoot) {
  const scriptDir = path.dirname(fileURLToPath(import.meta.url));
  const templateRoot = path.join(scriptDir, "template");

  await copyFile(
    path.join(templateRoot, "visual.config.json"),
    path.join(targetRoot, "visual.config.json"),
  );
  await copyFile(
    path.join(templateRoot, "visual-baselines", "home", "meta.json"),
    path.join(targetRoot, "visual-baselines", "home", "meta.json"),
  );
  await copyFile(
    path.join(templateRoot, "visual-output", ".gitkeep"),
    path.join(targetRoot, "visual-output", ".gitkeep"),
  );

  const visualScripts = [
    "check.mjs",
    "loop.mjs",
    "approve.mjs",
    "export-figma-map.mjs",
    "mcp-healthcheck.mjs",
    "extensions.md",
    path.join("lib", "capture.mjs"),
    path.join("lib", "config.mjs"),
    path.join("lib", "diff.mjs"),
    path.join("lib", "hotspots.mjs"),
    path.join("lib", "io.mjs"),
    path.join("lib", "server.mjs"),
  ];

  for (const filePath of visualScripts) {
    await copyFile(
      path.join(templateRoot, "scripts", "visual", filePath),
      path.join(targetRoot, "scripts", "visual", filePath),
    );
  }

  await upsertPackageJson(targetRoot);
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
