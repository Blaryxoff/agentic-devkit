import fs from "node:fs/promises";
import path from "node:path";
import { execaCommand } from "execa";

const reportPath = path.resolve(
  process.cwd(),
  "visual-output",
  "home",
  "desktop",
  "report.json",
);

await execaCommand("npx @playwright/mcp@latest --help", {
  shell: true,
  stdio: "inherit",
});

try {
  await execaCommand("node scripts/visual/check.mjs home --viewport=desktop", {
    shell: true,
    stdio: "inherit",
  });
} catch {
  // A visual mismatch should not fail MCP health check.
}

await fs.access(reportPath);
console.log(`MCP health check complete. Report found at ${reportPath}`);
