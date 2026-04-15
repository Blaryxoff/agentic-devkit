import fs from "node:fs/promises";
import path from "node:path";

export function createPaths(projectRoot) {
  const visualDir = path.join(projectRoot, "visual");
  return {
    visualDir,
    configPath: path.join(visualDir, "config.json"),
    baselinesDir: path.join(visualDir, "baselines"),
    outputDir: path.join(visualDir, "output"),
  };
}

export function baselinePath(baselinesDir, page, viewport) {
  return path.join(baselinesDir, page, `${viewport}.png`);
}

export function outputPath(outputDir, page, viewport, filename) {
  return path.join(outputDir, page, viewport, filename);
}

export async function loadVisualConfig(configPath) {
  const raw = await fs.readFile(configPath, "utf8");
  return JSON.parse(raw);
}

export async function loadPageMeta(baselinesDir, pageName, configPage = {}) {
  const metaPath = path.join(baselinesDir, pageName, "meta.json");
  try {
    const raw = await fs.readFile(metaPath, "utf8");
    const fromMeta = JSON.parse(raw);
    return { ...configPage, ...fromMeta };
  } catch (error) {
    if (error?.code === "ENOENT") {
      return configPage;
    }
    throw error;
  }
}

export function getViewports(config, targetViewport = null) {
  const entries = Object.entries(config.viewports ?? {});
  if (entries.length === 0) {
    throw new Error("No viewports configured in visual/config.json");
  }

  if (!targetViewport) {
    return entries.map(([name, viewport]) => ({ name, ...viewport }));
  }

  const viewport = config.viewports[targetViewport];
  if (!viewport) {
    throw new Error(`Unknown viewport '${targetViewport}'`);
  }

  return [{ name: targetViewport, ...viewport }];
}
