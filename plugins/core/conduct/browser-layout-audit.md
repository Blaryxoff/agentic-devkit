# Browser Layout Audit

Use this probe after the page, fonts, and intended data state are stable. It finds candidates; confirm them against the
design and interaction intent before reporting a defect.

## Probe

Run one `evaluate_script` call and keep the JSON result as text evidence:

```js
() => {
  const tolerance = 1;
  const maxSamplesPerType = 5;
  const maxSamples = 40;
  const issues = [];
  const counts = {};
  const sampled = {};
  const sampledElements = {};
  let truncated = false;
  const all = [...document.body.querySelectorAll("*")];
  const actionable = "a,button,input,select,textarea,summary,[role='button'],[role='link'],[tabindex]";

  const rendered = (element) => {
    const style = getComputedStyle(element);
    const rect = element.getBoundingClientRect();
    const visible = typeof element.checkVisibility === "function"
      ? element.checkVisibility({ checkOpacity: true, checkVisibilityCSS: true })
      : style.display !== "none" && style.visibility !== "hidden" && Number(style.opacity) > 0;
    return visible && rect.width > 0 && rect.height > 0 ? { rect, style } : null;
  };

  const identity = (element) => {
    const testId = element.getAttribute("data-testid");
    const label = element.getAttribute("aria-label");
    const role = element.getAttribute("role");
    if (testId) return `[data-testid="${testId}"]`;
    if (element.id) return `#${element.id}`;
    if (label) return `${role || element.tagName.toLowerCase()}[aria-label="${label}"]`;
    const text = (element.innerText || element.getAttribute("alt") || "").trim().replace(/\s+/g, " ").slice(0, 60);
    return `${role || element.tagName.toLowerCase()}${text ? ` “${text}”` : ""}`;
  };

  const details = (element, rect, style) => {
    return {
      element: identity(element),
      rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height,
        right: rect.right, bottom: rect.bottom },
      client: { width: element.clientWidth, height: element.clientHeight },
      scroll: { width: element.scrollWidth, height: element.scrollHeight },
      style: { display: style.display, position: style.position, zIndex: style.zIndex,
        overflowX: style.overflowX, overflowY: style.overflowY, whiteSpace: style.whiteSpace,
        textOverflow: style.textOverflow }
    };
  };

  const add = (type, element, rect, style, extra = {}) => {
    counts[type] = (counts[type] || 0) + 1;
    sampled[type] = sampled[type] || 0;
    sampledElements[type] = sampledElements[type] || [];
    const duplicatesNestedSample = sampledElements[type].some(
      sampledElement => sampledElement.contains(element) || element.contains(sampledElement)
    );
    if (!duplicatesNestedSample && sampled[type] < maxSamplesPerType && issues.length < maxSamples) {
      issues.push({ type, ...details(element, rect, style), ...extra });
      sampled[type] += 1;
      sampledElements[type].push(element);
    } else {
      truncated = true;
    }
  };

  for (const element of all) {
    const renderedElement = rendered(element);
    if (!renderedElement) continue;
    const { rect, style } = renderedElement;

    if (rect.left < -tolerance || rect.right > innerWidth + tolerance)
      add("viewport-horizontal-escape", element, rect, style);

    if (element.scrollWidth > element.clientWidth + tolerance)
      add(["auto", "scroll"].includes(style.overflowX) ? "horizontal-scroll-region" :
        ["hidden", "clip"].includes(style.overflowX) ? "horizontal-clipping" :
        "horizontal-content-overflow", element, rect, style);

    if (element.scrollHeight > element.clientHeight + tolerance)
      add(["auto", "scroll"].includes(style.overflowY) ? "vertical-scroll-region" :
        ["hidden", "clip"].includes(style.overflowY) ? "vertical-clipping" :
        "vertical-content-overflow", element, rect, style);

    if (element.matches(actionable) && !element.matches(":disabled,[aria-disabled='true']")) {
      const x = rect.left + rect.width / 2;
      const y = rect.top + rect.height / 2;
      if (x >= 0 && x < innerWidth && y >= 0 && y < innerHeight) {
        const top = document.elementFromPoint(x, y);
        if (top && !element.contains(top))
          add("actionable-centre-occluded", element, rect, style, { occludedBy: identity(top) });
      }
    }

    if (element instanceof HTMLImageElement && element.complete && element.naturalWidth === 0)
      add("broken-image", element, rect, style, { src: (element.currentSrc || element.src).slice(0, 200) });

    const marker = `${element.id} ${element.getAttribute("class") || ""}`;
    if (element.getAttribute("aria-busy") === "true" || /(^|[\s_-])(skeleton|spinner|shimmer|loader)([\s_-]|$)/i.test(marker))
      add("visible-loading-marker", element, rect, style);
  }

  return {
    viewport: { width: innerWidth, height: innerHeight, deviceScaleFactor: devicePixelRatio },
    document: { clientWidth: document.documentElement.clientWidth,
      scrollWidth: document.documentElement.scrollWidth,
      horizontalOverflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + tolerance },
    issueCount: Object.values(counts).reduce((sum, count) => sum + count, 0),
    returnedIssueCount: issues.length,
    counts,
    truncated,
    issues
  };
}
```

## Reference geometry

For design-reference work, build a small ledger before testing: reference node, live accessible identity or test ID,
expected box or alignment relationship, and tolerance. Compare the live `getBoundingClientRect()` values in one batched
call.

- Use exact boxes only when the reference frame and live viewport dimensions match.
- For fluid layouts, compare order, containment, aligned edges/centres, inter-element gaps, and relative proportions.
- Treat a one-CSS-pixel geometry delta as the default tolerance; document any larger design-specific tolerance.
- Use an existing normalised local pixel diff for paint-level properties when available. Otherwise inspect the smallest
  matching reference/live crops only when cheaper evidence cannot explain the delta.

## Classification

- Confirm viewport escape, clipped content, broken assets, and actionable occlusion unless the design explicitly requires
  them.
- Review scroll regions, off-canvas content, carousels, menus, and code blocks as intentional candidates first.
- Ignore transient markers only when the tested state is intentionally loading; after readiness they are artifact
  candidates.
- When `truncated` is true, use `counts` to select each truncated type and run a focused selector/type probe before
  declaring the viewport clean. The returned samples are not complete evidence in that case.
- Use a cropped visual diff for pseudo-elements, icons, shadows, imagery, font rasterisation, or non-actionable overlap;
  this probe cannot prove those paint-level properties.
