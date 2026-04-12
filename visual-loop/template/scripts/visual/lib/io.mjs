import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

export async function ensureDirForFile(filePath) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
}

export async function writeJson(filePath, data) {
  await ensureDirForFile(filePath);
  await fs.writeFile(filePath, `${JSON.stringify(data, null, 2)}\n`, "utf8");
}

export async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

export function isMainModule(importMetaUrl) {
  if (!process.argv[1]) {
    return false;
  }

  return importMetaUrl === pathToFileURL(process.argv[1]).href;
}

export function toAbsolutePath(...parts) {
  return path.resolve(process.cwd(), ...parts);
}

export function thisFilePath(importMetaUrl) {
  return fileURLToPath(importMetaUrl);
}
