import fs from "node:fs/promises";
import path from "node:path";
import { loadVisualConfig, getViewports, resolveFromRoot } from "./lib/config.mjs";
import { fileExists, isMainModule } from "./lib/io.mjs";

function parseArgs(argv) {
  const args = argv.slice(2);
  return {
    page: args[0],
    viewport: args[1] ?? null,
  };
}

async function copyActualToBaseline(page, viewportName) {
  const actual = resolveFromRoot("visual-output", page, viewportName, "actual.png");
  const baseline = resolveFromRoot("visual-baselines", page, `${viewportName}.png`);

  const actualExists = await fileExists(actual);
  if (!actualExists) {
    throw new Error(
      `Cannot approve '${viewportName}': actual screenshot missing at ${path.relative(process.cwd(), actual)}`,
    );
  }

  await fs.mkdir(path.dirname(baseline), { recursive: true });
  await fs.copyFile(actual, baseline);
  console.log(`Approved baseline: ${path.relative(process.cwd(), baseline)}`);
}

export async function approveBaselines({ page, viewport = null }) {
  if (!page) {
    throw new Error("Usage: pnpm ui:approve <page> [viewport]");
  }

  const config = await loadVisualConfig();
  const selectedViewports = getViewports(config, viewport);

  for (const current of selectedViewports) {
    await copyActualToBaseline(page, current.name);
  }
}

async function main() {
  const args = parseArgs(process.argv);
  await approveBaselines(args);
}

if (isMainModule(import.meta.url)) {
  main().catch((error) => {
    console.error(error.message);
    process.exit(1);
  });
}
