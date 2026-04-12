import fs from "node:fs";
import pixelmatch from "pixelmatch";
import { PNG } from "pngjs";
import { buildHotspots, buildLikelyIssues } from "./hotspots.mjs";
import { ensureDirForFile } from "./io.mjs";

export async function runDiff({
  baselinePath,
  actualPath,
  diffPath,
  route,
  viewportName,
  thresholds,
  pixelmatchOptions,
}) {
  const baseline = PNG.sync.read(fs.readFileSync(baselinePath));
  const actual = PNG.sync.read(fs.readFileSync(actualPath));

  if (
    baseline.width !== actual.width ||
    baseline.height !== actual.height
  ) {
    return {
      route,
      viewport: viewportName,
      width: actual.width,
      height: actual.height,
      threshold: thresholds.pass,
      mismatchPercent: 100,
      pixelsDifferent: actual.width * actual.height,
      status: "fail",
      hotspots: [],
      notes: [
        "Baseline and actual image dimensions do not match.",
        `baseline=${baseline.width}x${baseline.height}, actual=${actual.width}x${actual.height}`,
      ],
    };
  }

  const diff = new PNG({ width: actual.width, height: actual.height });
  const pixelsDifferent = pixelmatch(
    baseline.data,
    actual.data,
    diff.data,
    actual.width,
    actual.height,
    {
      threshold: pixelmatchOptions?.threshold ?? 0.1,
    },
  );
  const totalPixels = actual.width * actual.height;
  const mismatchPercent = Number(((pixelsDifferent / totalPixels) * 100).toFixed(4));

  await ensureDirForFile(diffPath);
  fs.writeFileSync(diffPath, PNG.sync.write(diff));

  const hotspots = buildHotspots(diff.data, actual.width, actual.height);
  const notes = buildLikelyIssues(mismatchPercent, hotspots);

  let status = "pass";
  if (mismatchPercent > thresholds.warn) {
    status = "fail";
  } else if (mismatchPercent > thresholds.pass) {
    status = "warn";
  }

  return {
    route,
    viewport: viewportName,
    width: actual.width,
    height: actual.height,
    threshold: thresholds.pass,
    warningThreshold: thresholds.warn,
    mismatchPercent,
    pixelsDifferent,
    status,
    hotspots,
    notes,
  };
}
