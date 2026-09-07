#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT/plugins/core/skills/sprint/SKILL.md"
REFERENCE="$ROOT/plugins/core/skills/sprint/references/evidence-and-pitfalls.md"
AUDITOR="$ROOT/plugins/core/skills/sprint/scripts/audit_workbook.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -f "$SKILL" ] || fail "sprint skill is missing"
[ -f "$REFERENCE" ] || fail "sprint evidence reference is missing"
[ -x "$AUDITOR" ] || fail "workbook auditor is not executable"

python3 - "$SKILL" <<'PY'
from pathlib import Path
import sys
import yaml

content = Path(sys.argv[1]).read_text()
_, frontmatter, body = content.split("---\n", 2)
metadata = yaml.safe_load(frontmatter)
assert metadata["name"] == "devkit-sprint"
description = metadata["description"].lower()
normalized_body = " ".join(body.lower().split())
for trigger in ("sprint-planning", "google sheets", "executor assignment", "drive smart chips"):
    assert trigger in description, trigger
for rule in (
    "gpt-5.6-luna",
    "hidden`/`veryhidden",
    "minimize the absolute difference in assigned coding hours",
    "exact equality is required",
    "do not shrink estimates",
    "leave whole tasks or epics unassigned",
    "never use `hyperlink()`",
    "wait until sheets visibly offers",
    "live popover url",
    "xlsx export flattens",
    "chip metadata",
):
    assert rule in normalized_body, rule
PY

python3 - "$TMP_DIR/workbook.xlsx" <<'PY'
from openpyxl import Workbook
from openpyxl.comments import Comment
from openpyxl.worksheet.datavalidation import DataValidation
from pathlib import Path
import sys

path = Path(sys.argv[1])
workbook = Workbook()

current = workbook.active
current.title = "Спринт current"
current.append(["План"])
current_headers = [
    "Эпик", "Название задачи", "Название подзадачи (если есть)", "Описание задачи",
    "Оценка (час)", "Направление", "Исполнитель", "Приоритет", "Задача", "Статус на проде",
]
current.append(current_headers)
current.append(["Epic A", "Task A", "Subtask", "Spec", 4, "back", "Никита", "Высокий", "VTS-1", None])
current.append(["Epic B", "Task B", None, None, 4, "front", "Женя", "Средний", "VTS-2", None])
current.append(["Future placeholder"])
current.append([None, "Итого", "Исполнитель", "Часы по задачам"])
current.append([])
current.append(["Разработка", "Всего (заложено)", "Всего (план по задачам)", "Отклонение"])
current.append(["Никита", 8, 8, 0])
current["B10"] = '=SUMIF(G3:G4,"Никита",E3:E5)'
current["X3"].comment = Comment("Task-specific correction", "Planner")
current["Y3"] = "=#REF!"
current["Z3"] = "Exact spec"
current["Z3"].hyperlink = "https://docs.google.com/document/d/example/edit#heading=h.task"
current.row_dimensions[3].hidden = True
current.column_dimensions["Z"].hidden = True
direction_validation = DataValidation(type="list", formula1='"back,front,full,common"', allow_blank=True)
current.add_data_validation(direction_validation)
direction_validation.add("F3:F4")

transitional = workbook.create_sheet("Спринт transitional")
transitional.sheet_state = "hidden"
transitional.append(["План"])
transitional.append([
    "Название доработки", "Раздел", "Задача", "Оценка (час)", "Реальная оценка",
    "Направление", "Исполнитель", "Важность реализации в рамках спринта", "Статус", "Приоритет внутри спринта", "Задача",
])
transitional.append(["Epic C", "Section", "Details C", 8, 7, "full", "Никита", "Точно реализуем", None, "Высокий", "VTS-3"])
transitional.append(["Epic D", "Section", "Details D", 2, None, "back", "Женя", "Бэклог", None, "Средний", "VTS-4"])
transitional["A5"] = "Итого"
transitional["D5"] = "факт"
transitional.row_dimensions[4].hidden = True

old = workbook.create_sheet("Спринт old")
old.sheet_state = "hidden"
old.append(["План"])
old.append(["Задачи по релизу", "Исполнитель", "Уровень", "Оценка", "Задача", None, None, None, "Часы в спринт"])
old.append(["Epic E", "Никита", "минор", 3, "VTS-1", None, None, None, 8])
old.append(["Epic F", "Женя", "мажор", 3, "VTS-5", None, None, None, 8])
old["H5"] = "Итого"

estimate = workbook.create_sheet("ОЦЕНКА")
estimate.append(["План"])
estimate.append(current_headers)
estimate.append(["Epic G", "Task G", None, None, 5, "back", None, "Высокий", "VTS-6", None])

support = workbook.create_sheet("Assignee map")
support.sheet_state = "veryHidden"
support.append(["Никита", "onishenko"])

workbook.save(path)
PY

python3 "$AUDITOR" "$TMP_DIR/workbook.xlsx" --pretty > "$TMP_DIR/audit.json"
python3 - "$TMP_DIR/audit.json" <<'PY'
import json
from pathlib import Path
import sys

audit = json.loads(Path(sys.argv[1]).read_text())
assert audit["sheet_count"] == 5
assert audit["task_table_count"] == 4
assert audit["sprint_sheet_count"] == 3
assert audit["task_row_count"] == 7
assert audit["all_task_row_count"] == 8
states = {sheet["title"]: sheet["state"] for sheet in audit["sheets"]}
assert states["Спринт current"] == "visible"
assert states["Спринт transitional"] == "hidden"
assert states["Assignee map"] == "veryHidden"

current = next(sheet for sheet in audit["sheets"] if sheet["title"] == "Спринт current")
assert current["last_meaningful_column"] == 26
assert current["hidden_rows"] == [3]
assert current["hidden_columns"] == ["Z"]
assert current["tasks"][0]["hidden"] is True
assert current["tasks"][0]["estimate"]["value"] == 4
assert len(current["task_blocks"][0]["unplanned_rows"]) == 1
assert current["tasks"][-1]["unplanned"] is True
assert current["hyperlinks"][0]["cell"] == "Z3"
assert current["hyperlinks"][0]["target"].endswith("#heading=h.task")
assert current["comments"][0]["cell"] == "X3"
assert current["data_validations"][0]["ranges"] == "F3:F4"
assert current["capacity_blocks"][0]["header_row"] == 8
assert current["capacity_blocks"][0]["start_column"] == 1
assert current["capacity_blocks"][0]["end_column"] == 4
assert current["task_blocks"][0]["end_row"] < current["capacity_blocks"][0]["header_row"]
assert current["formula_errors"][0]["cell"] == "Y3"
assert current["sumif_range_mismatches"][0]["criteria_rows"] == [3, 4]
assert current["sumif_range_mismatches"][0]["sum_rows"] == [3, 5]

transitional = next(sheet for sheet in audit["sheets"] if sheet["title"] == "Спринт transitional")
columns = transitional["task_blocks"][0]["columns"]
assert columns["epic"] == 1
assert columns["task"] == 3
assert columns["task_id"] == 11
assert columns["actual_estimate"] == 5
assert columns["commitment"] == 8
assert columns["priority"] == 10
assert transitional["tasks"][0]["actual_estimate"]["value"] == 7
assert transitional["tasks"][0]["commitment"]["value"] == "Точно реализуем"
assert transitional["tasks"][0]["priority"]["value"] == "Высокий"
assert [task["task_id"]["value"] for task in transitional["tasks"]] == ["VTS-3", "VTS-4"]
assert transitional["task_blocks"][0]["end_row"] == 4

old = next(sheet for sheet in audit["sheets"] if sheet["title"] == "Спринт old")
assert old["task_blocks"][0]["columns"]["task_id"] == 5
assert old["task_blocks"][0]["columns"]["level"] == 3
assert "direction" not in old["task_blocks"][0]["columns"]
assert len(old["tasks"]) == 2
assert old["capacity_blocks"][0]["start_column"] == 9
assert old["capacity_blocks"][0]["end_row"] == 4
assert len(audit["duplicate_task_ids"]["VTS-1"]) == 2
PY

echo "sprint skill tests passed (XLSX preserves exact links; native-chip appearance remains a required live UI check)"
