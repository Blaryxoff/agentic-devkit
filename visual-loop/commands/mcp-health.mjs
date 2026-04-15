import { execaCommand } from "execa";
import { createPaths, outputPath as getOutputPath } from "../lib/config.mjs";
import { fileExists } from "../lib/io.mjs";
import { runVisualCheck } from "./check.mjs";

export async function mcpHealthCheck({ projectRoot, configPath }) {
  await execaCommand("npx @playwright/mcp@latest --help", {
    shell: true,
    stdio: "inherit",
    cwd: projectRoot,
  });

  try {
    await runVisualCheck({ page: "home", viewport: "desktop", projectRoot, configPath });
  } catch {
    // Visual mismatch should not fail MCP health check.
  }

  const paths = createPaths(projectRoot);
  const reportPath = getOutputPath(paths.outputDir, "home", "desktop", "report.json");
  const reportExists = await fileExists(reportPath);
  if (!reportExists) {
    throw new Error(`MCP health check failed: report not found at ${reportPath}`);
  }

  console.log(`MCP health check complete. Report found at ${reportPath}`);
}
