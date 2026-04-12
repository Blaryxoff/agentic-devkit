import path from "node:path";
import { captureViewport } from "./lib/capture.mjs";
import { loadPageMeta, loadVisualConfig, getViewports, resolveFromRoot } from "./lib/config.mjs";
import { runDiff } from "./lib/diff.mjs";
import { fileExists, isMainModule, writeJson } from "./lib/io.mjs";
import { ensureServer } from "./lib/server.mjs";

function parseArgs(argv) {
  const args = argv.slice(2);
  const page = args[0];
  const viewportFlag = args.find((entry) => entry.startsWith("--viewport="));
  const viewport = viewportFlag ? viewportFlag.split("=")[1] : null;

  return { page, viewport };
}

function reportPath(page, viewport) {
  return resolveFromRoot("visual-output", page, viewport, "report.json");
}

function actualPath(page, viewport) {
  return resolveFromRoot("visual-output", page, viewport, "actual.png");
}

function diffPath(page, viewport) {
  return resolveFromRoot("visual-output", page, viewport, "diff.png");
}

function baselinePath(page, viewport) {
  return resolveFromRoot("visual-baselines", page, `${viewport}.png`);
}

export async function runVisualCheck({ page, viewport = null }) {
  if (!page) {
    throw new Error("Usage: pnpm ui:check <page> [--viewport=<name>]");
  }

  const config = await loadVisualConfig();
  const pageFromConfig = config.pages?.[page];
  if (!pageFromConfig) {
    throw new Error(`Page '${page}' is not configured in visual.config.json`);
  }

  const pageMeta = await loadPageMeta(page, pageFromConfig);
  const route = pageMeta.route;
  if (!route) {
    throw new Error(`Page '${page}' does not define a route.`);
  }

  const selectedViewports = getViewports(config, viewport);
  const thresholds = config.thresholds ?? { pass: 0.3, warn: 1.5 };
  const serverProcess = await ensureServer(config);

  const reports = [];

  try {
    for (const current of selectedViewports) {
      const currentBaselinePath = baselinePath(page, current.name);
      const currentActualPath = actualPath(page, current.name);
      const currentDiffPath = diffPath(page, current.name);
      const currentReportPath = reportPath(page, current.name);

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
            `Missing baseline image: ${path.relative(process.cwd(), currentBaselinePath)}`,
            "Run pnpm ui:approve <page> <viewport> only after design approval.",
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
      serverProcess.kill("SIGTERM", {
        forceKillAfterTimeout: 5000,
      });
    }
  }

  const failed = reports.some(
    (entry) => entry.mismatchPercent > entry.threshold || entry.status === "fail",
  );
  return {
    ok: !failed,
    reports,
  };
}

async function main() {
  const { page, viewport } = parseArgs(process.argv);
  const result = await runVisualCheck({ page, viewport });

  for (const report of result.reports) {
    const statusIcon = report.status === "pass" ? "PASS" : report.status.toUpperCase();
    console.log(
      `[${statusIcon}] ${report.viewport}: mismatch=${report.mismatchPercent}% (${report.pixelsDifferent} px)`,
    );
  }

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
