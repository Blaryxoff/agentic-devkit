import fs from "node:fs/promises";
import { globby } from "globby";
import { runVisualCheck } from "./check.mjs";
import { loadVisualConfig } from "./lib/config.mjs";
import { isMainModule } from "./lib/io.mjs";

function parseArgs(argv) {
  const args = argv.slice(2);
  return {
    page: args[0],
    viewport: args[1] ?? null,
  };
}

async function currentSignature(globs) {
  const files = await globby(globs, {
    gitignore: true,
  });

  const stats = await Promise.all(
    files.map(async (filePath) => {
      try {
        const stat = await fs.stat(filePath);
        return `${filePath}:${stat.mtimeMs}:${stat.size}`;
      } catch {
        return `${filePath}:missing`;
      }
    }),
  );

  return stats.sort().join("|");
}

async function waitForChange(globs, initialSignature, timeoutMs, pollIntervalMs) {
  const startedAt = Date.now();
  while (Date.now() - startedAt <= timeoutMs) {
    const nextSignature = await currentSignature(globs);
    if (nextSignature !== initialSignature) {
      return true;
    }

    await new Promise((resolve) => setTimeout(resolve, pollIntervalMs));
  }

  return false;
}

export async function runVisualLoop({ page, viewport = null }) {
  if (!page) {
    throw new Error("Usage: pnpm ui:loop <page> [viewport]");
  }

  const config = await loadVisualConfig();
  const loop = config.loop ?? {};
  const maxIterations = loop.maxIterations ?? 6;
  const waitForChangesMs = loop.waitForChangesMs ?? 300000;
  const pollIntervalMs = loop.pollIntervalMs ?? 1500;
  const watchGlobs = loop.watchGlobs ?? ["resources/js/**/*.{js,ts,vue,css,scss}"];

  for (let iteration = 1; iteration <= maxIterations; iteration += 1) {
    console.log(`\nIteration ${iteration}/${maxIterations}`);

    const beforeSignature = await currentSignature(watchGlobs);
    const result = await runVisualCheck({ page, viewport });
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

async function main() {
  const args = parseArgs(process.argv);
  const result = await runVisualLoop(args);
  if (!result.ok) {
    process.exitCode = 1;
  }
}

if (isMainModule(import.meta.url)) {
  main().catch((error) => {
    console.error(error.message);
    process.exit(1);
  });
}
