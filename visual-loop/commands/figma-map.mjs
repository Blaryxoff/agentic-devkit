import fs from "node:fs/promises";
import path from "node:path";
import { createPaths } from "../lib/config.mjs";

export async function exportFigmaMap({ projectRoot }) {
  const paths = createPaths(projectRoot);
  const mapPath = path.join(paths.baselinesDir, "figma-map.json");

  const example = {
    generatedAt: new Date().toISOString(),
    notes: [
      "Populate this map from Figma export metadata in phase 2.",
      "Keep page keys aligned with visual/config.json pages.",
    ],
    pages: {
      home: {
        frame: "Home",
        viewports: {
          mobile: "mobile.png",
          tablet: "tablet.png",
          desktop: "desktop.png",
        },
      },
    },
  };

  await fs.mkdir(path.dirname(mapPath), { recursive: true });
  await fs.writeFile(mapPath, `${JSON.stringify(example, null, 2)}\n`, "utf8");
  console.log(`Wrote ${mapPath}`);
}
