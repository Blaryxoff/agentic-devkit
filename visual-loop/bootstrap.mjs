#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

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

Dependencies live inside the toolkit (visual-loop/package.json).
Parent projects do not need visual-related devDependencies.`,
  );
}

async function bootstrap(targetRoot) {
  const scriptDir = path.dirname(fileURLToPath(import.meta.url));
  const templateRoot = path.join(scriptDir, "template");
  const visualDir = path.join(targetRoot, "visual");

  const scaffolded = [];

  if (await copyIfMissing(
    path.join(templateRoot, "config.json"),
    path.join(visualDir, "config.json"),
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
