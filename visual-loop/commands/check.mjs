import {
  createPaths,
  baselinePath as getBaselinePath,
  outputPath as getOutputPath,
  loadVisualConfig,
  loadPageMeta,
  getViewports,
} from "../lib/config.mjs";
import { captureViewport } from "../lib/capture.mjs";
import { runDiff } from "../lib/diff.mjs";
import { fileExists, writeJson } from "../lib/io.mjs";
import { ensureServer } from "../lib/server.mjs";

export async function runVisualCheck({ page, viewport = null, projectRoot, configPath }) {
  if (!page) {
    throw new Error("Missing --page. Usage: visual-loop check --project-root <path> --page <page> [--viewport <name>]");
  }

  const paths = createPaths(projectRoot);
  const resolvedConfigPath = configPath || paths.configPath;
  const config = await loadVisualConfig(resolvedConfigPath);

  const pageFromConfig = config.pages?.[page];
  if (!pageFromConfig) {
    throw new Error(`Page '${page}' is not configured in visual/config.json`);
  }

  const pageMeta = await loadPageMeta(paths.baselinesDir, page, pageFromConfig);
  const route = pageMeta.route;
  if (!route) {
    throw new Error(`Page '${page}' does not define a route.`);
  }

  const selectedViewports = getViewports(config, viewport);
  const thresholds = config.thresholds ?? { pass: 0.3, warn: 1.5 };
  const serverProcess = await ensureServer(config, { cwd: projectRoot });

  const reports = [];

  try {
    for (const current of selectedViewports) {
      const currentBaselinePath = getBaselinePath(paths.baselinesDir, page, current.name);
      const currentActualPath = getOutputPath(paths.outputDir, page, current.name, "actual.png");
      const currentDiffPath = getOutputPath(paths.outputDir, page, current.name, "diff.png");
      const currentReportPath = getOutputPath(paths.outputDir, page, current.name, "report.json");

      await captureViewport({
        baseUrl: config.baseUrl,
        route,
        viewport: current,
        waitFor: pageMeta.waitFor,
        clip: pageMeta.clip,
        outputPath: currentActualPath,
        theme: pageMeta.theme ?? "light",
        locale: pageMeta.locale ?? "en",
        timezone: pageMeta.timezone ?? "UTC",
      });

      const hasBaseline = await fileExists(currentBaselinePath);
      if (!hasBaseline) {
        const missingBaselineReport = {
          route,
          viewport: current.name,
          width: current.width,
          height: current.height,
          threshold: thresholds.pass,
          warningThreshold: thresholds.warn,
          mismatchPercent: 100,
          pixelsDifferent: current.width * current.height,
          status: "fail",
          hotspots: [],
          notes: [
            `Missing baseline image: visual/baselines/${page}/${current.name}.png`,
            "Run: visual-loop approve --project-root <path> --page <page> --viewport <viewport>",
          ],
          files: {
            baseline: currentBaselinePath,
            actual: currentActualPath,
            diff: currentDiffPath,
            report: currentReportPath,
          },
        };

        await writeJson(currentReportPath, missingBaselineReport);
        reports.push(missingBaselineReport);
        continue;
      }

      const diffReport = await runDiff({
        baselinePath: currentBaselinePath,
        actualPath: currentActualPath,
        diffPath: currentDiffPath,
        route,
        viewportName: current.name,
        thresholds,
        pixelmatchOptions: config.pixelmatch,
      });

      diffReport.files = {
        baseline: currentBaselinePath,
        actual: currentActualPath,
        diff: currentDiffPath,
        report: currentReportPath,
      };

      await writeJson(currentReportPath, diffReport);
      reports.push(diffReport);
    }
  } finally {
    if (serverProcess) {
      serverProcess.kill("SIGTERM", { forceKillAfterTimeout: 5000 });
    }
  }

  const failed = reports.some(
    (entry) => entry.mismatchPercent > entry.threshold || entry.status === "fail",
  );
  return { ok: !failed, reports };
}
