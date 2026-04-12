function toRect(cell, cellWidth, cellHeight, width, height) {
  const x = cell.col * cellWidth;
  const y = cell.row * cellHeight;
  const w = Math.min(cellWidth, width - x);
  const h = Math.min(cellHeight, height - y);

  return {
    x,
    y,
    w,
    h,
  };
}

export function buildHotspots(diffData, width, height, options = {}) {
  const rows = options.rows ?? 6;
  const cols = options.cols ?? 6;
  const topN = options.topN ?? 5;

  const cellWidth = Math.ceil(width / cols);
  const cellHeight = Math.ceil(height / rows);
  const cells = [];

  for (let row = 0; row < rows; row += 1) {
    for (let col = 0; col < cols; col += 1) {
      cells.push({
        row,
        col,
        differentPixels: 0,
      });
    }
  }

  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const idx = (y * width + x) * 4;
      const alpha = diffData[idx + 3];
      if (alpha === 0) {
        continue;
      }

      const row = Math.min(rows - 1, Math.floor(y / cellHeight));
      const col = Math.min(cols - 1, Math.floor(x / cellWidth));
      const cellIndex = row * cols + col;
      cells[cellIndex].differentPixels += 1;
    }
  }

  return cells
    .filter((cell) => cell.differentPixels > 0)
    .sort((a, b) => b.differentPixels - a.differentPixels)
    .slice(0, topN)
    .map((cell, index) => ({
      name: `region-${index + 1}`,
      ...toRect(cell, cellWidth, cellHeight, width, height),
      pixelsDifferent: cell.differentPixels,
    }));
}

export function buildLikelyIssues(mismatchPercent, hotspots) {
  if (mismatchPercent === 0) {
    return [];
  }

  const notes = [];
  if (mismatchPercent > 1.5) {
    notes.push("Major layout/spacing drift detected across one or more regions.");
  } else {
    notes.push("Minor visual drift detected; check spacing/typography consistency.");
  }

  if (hotspots.length > 0) {
    notes.push(
      `Top hotspot is ${hotspots[0].name}; align container sizing and spacing first.`,
    );
  }

  return notes;
}
