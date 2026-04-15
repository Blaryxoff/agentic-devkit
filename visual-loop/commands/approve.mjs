import fs from "node:fs/promises";
import path from "node:path";
import {
  createPaths,
  baselinePath as getBaselinePath,
  outputPath as getOutputPath,
  loadVisualConfig,
  getViewports,
} from "../lib/config.mjs";
import { fileExists } from "../lib/io.mjs";

export async function approveBaselines({ page, viewport = null, projectRoot, configPath }) {
  if (!page) {
    throw new Error("Missing --page. Usage: visual-loop approve --project-root <path> --page <page> [--viewport <name>]");
  }

  const paths = createPaths(projectRoot);
  const resolvedConfigPath = configPath || paths.configPath;
  const config = await loadVisualConfig(resolvedConfigPath);
  const selectedViewports = getViewports(config, viewport);

  for (const current of selectedViewports) {
    const actual = getOutputPath(paths.outputDir, page, current.name, "actual.png");
    const baseline = getBaselinePath(paths.baselinesDir, page, current.name);

    const actualExists = await fileExists(actual);
    if (!actualExists) {
      throw new Error(
        `Cannot approve '${current.name}': actual screenshot missing at visual/output/${page}/${current.name}/actual.png`,
      );
    }

    await fs.mkdir(path.dirname(baseline), { recursive: true });
    await fs.copyFile(actual, baseline);
    console.log(`Approved baseline: visual/baselines/${page}/${current.name}.png`);
  }
}
