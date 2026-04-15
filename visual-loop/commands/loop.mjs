import fs from "node:fs/promises";
import path from "node:path";
import { globby } from "globby";
import { runVisualCheck } from "./check.mjs";
import { createPaths, loadVisualConfig } from "../lib/config.mjs";

async function currentSignature(globs, cwd) {
  const files = await globby(globs, { gitignore: true, cwd });

  const stats = await Promise.all(
    files.map(async (relPath) => {
      const absPath = path.join(cwd, relPath);
      try {
        const stat = await fs.stat(absPath);
        return `${relPath}:${stat.mtimeMs}:${stat.size}`;
      } catch {
        return `${relPath}:missing`;
      }
    }),
  );

  return stats.sort().join("|");
}

async function waitForChange(globs, cwd, initialSignature, timeoutMs, pollIntervalMs) {
  const startedAt = Date.now();
  while (Date.now() - startedAt <= timeoutMs) {
    const nextSignature = await currentSignature(globs, cwd);
    if (nextSignature !== initialSignature) {
      return true;
    }

    await new Promise((resolve) => setTimeout(resolve, pollIntervalMs));
  }

  return false;
}

export async function runVisualLoop({ page, viewport = null, projectRoot, configPath }) {
  if (!page) {
    throw new Error("Missing --page. Usage: visual-loop loop --project-root <path> --page <page> [--viewport <name>]");
  }

  const paths = createPaths(projectRoot);
  const resolvedConfigPath = configPath || paths.configPath;
  const config = await loadVisualConfig(resolvedConfigPath);

  const loop = config.loop ?? {};
  const maxIterations = loop.maxIterations ?? 6;
  const waitForChangesMs = loop.waitForChangesMs ?? 300000;
  const pollIntervalMs = loop.pollIntervalMs ?? 1500;
  const watchGlobs = loop.watchGlobs ?? ["resources/js/**/*.{js,ts,vue,css,scss}"];

  for (let iteration = 1; iteration <= maxIterations; iteration += 1) {
    console.log(`\nIteration ${iteration}/${maxIterations}`);

    const beforeSignature = await currentSignature(watchGlobs, projectRoot);
    const result = await runVisualCheck({ page, viewport, projectRoot, configPath });
    if (result.ok) {
      console.log("Visual loop passed.");
      return { ok: true, iterations: iteration };
    }

    if (iteration === maxIterations) {
      break;
    }

    console.log(
      `Waiting for source changes before next iteration (timeout ${Math.floor(waitForChangesMs / 1000)}s)...`,
    );
    const changed = await waitForChange(
      watchGlobs,
      projectRoot,
      beforeSignature,
      waitForChangesMs,
      pollIntervalMs,
    );
    if (!changed) {
      console.log("No source changes detected. Stopping loop.");
      break;
    }
  }

  return { ok: false };
}
