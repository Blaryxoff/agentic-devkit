import { chromium } from "playwright";
import { ensureDirForFile } from "./io.mjs";

const STABILIZE_STYLES = `
*, *::before, *::after {
  animation: none !important;
  transition: none !important;
  caret-color: transparent !important;
}
html {
  scroll-behavior: auto !important;
}
`;

export async function captureViewport({
  baseUrl,
  route,
  viewport,
  waitFor,
  clip,
  outputPath,
  theme = "light",
  locale = "en",
  timezone = "UTC",
  timeoutMs = 30000,
}) {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: {
      width: viewport.width,
      height: viewport.height,
    },
    locale,
    timezoneId: timezone,
    colorScheme: theme === "dark" ? "dark" : "light",
  });
  const page = await context.newPage();

  try {
    await page.goto(new URL(route, baseUrl).toString(), {
      waitUntil: "domcontentloaded",
      timeout: timeoutMs,
    });

    if (waitFor) {
      await page.waitForSelector(waitFor, { timeout: timeoutMs });
    }

    try {
      await page.waitForLoadState("networkidle", { timeout: 3000 });
    } catch {
      // Some pages maintain long-lived connections.
    }

    await page.addStyleTag({ content: STABILIZE_STYLES });
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.evaluate(async (pageTheme) => {
      await document.fonts.ready;
      document.documentElement.dataset.theme = pageTheme;
      document.documentElement.classList.toggle("dark", pageTheme === "dark");
    }, theme);

    await ensureDirForFile(outputPath);
    await page.screenshot({
      path: outputPath,
      clip: clip || undefined,
      fullPage: false,
    });
  } finally {
    await context.close();
    await browser.close();
  }
}
