---
name: devkit-xlsx
description: create, read, edit, validate, or summarize spreadsheets (.xlsx, .xlsm, .csv, .tsv) on demand. Use for data cleanup, tabular reports, inventory exports, reconciliation, lightweight analysis, and preserving existing workbook formulas/formatting. Uses Python/CLI tools only; no background services.
---

# XLSX / Spreadsheet Workflows

Use this skill for spreadsheet files. Keep the workflow boring, verifiable, and loss-aware: spreadsheets are tiny databases with a GUI and a long history of ruining afternoons.

## Decision tree

1. **CSV/TSV or simple analysis** → use Python `csv`/`pandas` if available.
2. **Read `.xlsx` values** → use `openpyxl` with `data_only=True` for cached formula results, and `data_only=False` when inspecting formulas.
3. **Create a new workbook** → use `openpyxl`; keep formulas simple and documented.
4. **Edit an existing workbook** → preserve workbook structure, sheets, formulas, styles, merged cells, filters, and named ranges unless the user explicitly wants a rebuild.
5. **Need recalculated formula values** → use LibreOffice headless if available; otherwise state that formulas were written but cached values may not be recalculated until opened by Excel/LibreOffice.

## Reading workbook structure

```python
from openpyxl import load_workbook

wb = load_workbook('input.xlsx', data_only=False)
print(wb.sheetnames)
for ws in wb.worksheets:
    print(ws.title, ws.max_row, ws.max_column)
```

Read values:

```python
from openpyxl import load_workbook

wb = load_workbook('input.xlsx', data_only=True)
ws = wb.active
for row in ws.iter_rows(values_only=True):
    print(row)
```

## Creating a workbook

```python
from openpyxl import Workbook
from openpyxl.styles import Font

wb = Workbook()
ws = wb.active
ws.title = 'Report'
ws.append(['Name', 'Count'])
ws.append(['Example', 1])
ws['A1'].font = Font(bold=True)
ws['B1'].font = Font(bold=True)
wb.save('output.xlsx')
```

## Editing rules

- Save to a new file unless the user explicitly asks to overwrite.
- Inspect sheets, dimensions, formulas, merged ranges, tables, and named styles before editing.
- Preserve existing style conventions; do not impose new formatting on templates.
- When adding formulas, verify references and fill-down ranges.
- For user-facing models, check for formula errors: `#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A`, `#NAME?`.

Formula inspection:

```python
from openpyxl import load_workbook

wb = load_workbook('input.xlsx', data_only=False)
for ws in wb.worksheets:
    for row in ws.iter_rows():
        for cell in row:
            if isinstance(cell.value, str) and cell.value.startswith('='):
                print(ws.title, cell.coordinate, cell.value)
```

## Recalculation check

If LibreOffice exists:

```bash
soffice --headless --convert-to xlsx --outdir /tmp/recalc output.xlsx
```

If not, verify workbook opens with `openpyxl` and warn that formula cache is not recalculated.

## Output discipline

Report:
- files read/written;
- sheets changed;
- formulas added/changed;
- validation performed;
- known limitations, especially formula recalculation and formatting preservation.

## Hard rules

- Never overwrite a source workbook without explicit instruction.
- Never claim formula results are recalculated unless you actually recalculated or opened with a compatible engine.
- Never drop hidden sheets/macros/formatting silently. For `.xlsm`, preserve VBA by loading with `keep_vba=True` when editing.
