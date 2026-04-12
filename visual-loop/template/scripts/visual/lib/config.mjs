import fs from "node:fs/promises";
import path from "node:path";

const ROOT = process.cwd();

export const resolveFromRoot = (...parts) => path.join(ROOT, ...parts);

export async function loadVisualConfig() {
  const configPath = resolveFromRoot("visual.config.json");
  const raw = await fs.readFile(configPath, "utf8");
  return JSON.parse(raw);
}

export async function loadPageMeta(pageName, configPage = {}) {
  const metaPath = resolveFromRoot("visual-baselines", pageName, "meta.json");
  try {
    const raw = await fs.readFile(metaPath, "utf8");
    const fromMeta = JSON.parse(raw);
    return {
      ...configPage,
      ...fromMeta,
    };
  } catch (error) {
    if (error && error.code === "ENOENT") {
      return configPage;
    }

    throw error;
  }
}

export function getViewports(config, targetViewport = null) {
  const entries = Object.entries(config.viewports ?? {});
  if (entries.length === 0) {
    throw new Error("No viewports configured in visual.config.json");
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
