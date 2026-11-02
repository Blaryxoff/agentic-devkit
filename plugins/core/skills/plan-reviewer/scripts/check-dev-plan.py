#!/usr/bin/env python3
import re
import sys

TITLE = re.compile(r"^# Plan: \S")
TASK_START = re.compile(r"^###\s+(Task|Iteration)\b")
TASK_SHAPE = re.compile(r"^### (Task|Iteration) \d+(\.\d+|[a-z])?: \S")
SECTION = re.compile(r"^#{1,3}\s")
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
CHECKBOX_LIKE = re.compile(r"^\s*[-*+]\s*\[\s*[xX]?\s*\]")
CHECKBOX_VALID = re.compile(r"^\s*- \[[ x]\] \S")
MARK_COMPLETED = re.compile(r"^\s*- \[[ x]\] Mark completed\s*$")
FILES_LABEL = re.compile(r"^\s*(?:[-*+]\s+)?\*\*Files:\*\*")
FILE_TARGET = re.compile(r"^(?:[-*+]\s+)?(?:Create|Modify|Read|Delete)(?:/(?:Create|Modify|Read|Delete))*\s+\S")


class Task:
    def __init__(self, line):
        self.line = line
        self.has_files_label = False
        self.has_file_target = False
        self.checkboxes = []


def read_lines(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read().splitlines()


def check(lines):
    violations = []
    tasks = []
    current = None
    fence_marker = None
    has_overview = False
    has_validation = False

    if not lines or not TITLE.match(lines[0]):
        violations.append((1, "missing-title", "first line must be '# Plan: <Title>'"))

    for number, line in enumerate(lines, start=1):
        fence = FENCE.match(line)
        if fence_marker is not None:
            if fence and fence[1][0] == fence_marker[0] and len(fence[1]) >= len(fence_marker) and not fence[2].strip():
                fence_marker = None
            continue
        if fence:
            fence_marker = fence[1]
            continue
        if TASK_START.match(line):
            current = Task(number)
            tasks.append(current)
            if not TASK_SHAPE.match(line):
                violations.append((number, "bad-task-heading", "expected '### Task N: <title>' or '### Iteration N: <title>'"))
            continue
        if SECTION.match(line):
            current = None
            has_overview = has_overview or line.rstrip() == "## Overview"
            has_validation = has_validation or line.rstrip() == "## Validation Commands"
            continue
        if current is not None:
            label = FILES_LABEL.match(line)
            if label:
                current.has_files_label = True
                current.has_file_target = bool(FILE_TARGET.match(line[label.end():].strip()))
            elif current.has_files_label and FILE_TARGET.match(line.strip()):
                current.has_file_target = True
        if not CHECKBOX_LIKE.match(line):
            continue
        if current is None:
            violations.append((number, "checkbox-outside-task", "checkbox outside a Task or Iteration section"))
            continue
        if not CHECKBOX_VALID.match(line):
            violations.append((number, "bad-checkbox-syntax", "checkbox must be '- [ ] <text>' or '- [x] <text>'"))
            continue
        current.checkboxes.append((number, line))

    if not has_overview:
        violations.append((1, "missing-overview", "missing '## Overview' section"))
    if not has_validation:
        violations.append((1, "missing-validation-commands", "missing '## Validation Commands' section"))
    if not tasks:
        violations.append((1, "missing-tasks", "no '### Task N:' or '### Iteration N:' sections"))

    for task in tasks:
        if not task.has_file_target:
            violations.append((task.line, "missing-file-list", "task needs a '**Files:**' list with a Create/Modify/Read/Delete target"))
        if len(task.checkboxes) < 2:
            violations.append((task.line, "missing-steps", "task needs at least one '- [ ]' step before 'Mark completed'"))
        if not task.checkboxes or not MARK_COMPLETED.match(task.checkboxes[-1][1]):
            violations.append((task.line, "missing-mark-completed", "last checkbox of the task must be '- [ ] Mark completed'"))

    return sorted(violations, key=lambda item: item[0])


def main(argv):
    if len(argv) != 2:
        print("usage: check-dev-plan.py <plan.md>", file=sys.stderr)
        return 2
    path = argv[1]
    try:
        lines = read_lines(path)
    except (OSError, UnicodeDecodeError) as error:
        print(f"check-dev-plan.py: {path}: {error}", file=sys.stderr)
        return 2
    violations = check(lines)
    for line, rule, message in violations:
        print(f"{path}:{line}: {rule}: {message}")
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
