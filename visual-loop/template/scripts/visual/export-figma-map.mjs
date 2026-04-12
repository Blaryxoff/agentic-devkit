import fs from "node:fs/promises";
import path from "node:path";

const outputPath = path.resolve(process.cwd(), "visual-baselines", "figma-map.json");

const example = {
  generatedAt: new Date().toISOString(),
  notes: [
    "Populate this map from Figma export metadata in phase 2.",
    "Keep page keys aligned with visual.config.json pages.",
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

await fs.mkdir(path.dirname(outputPath), { recursive: true });
await fs.writeFile(outputPath, `${JSON.stringify(example, null, 2)}\n`, "utf8");
console.log(`Wrote ${outputPath}`);
