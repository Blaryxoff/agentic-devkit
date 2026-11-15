#!/usr/bin/env python3

import argparse
import json
import re
import sys
from pathlib import Path

FRONTMATTER_LIMIT = 16 * 1024


def scalar(value):
    raw = value.strip()
    if not raw:
        return ""
    if raw[0:1] in ("'", '"'):
        if len(raw) < 2 or raw[-1] != raw[0]:
            raise ValueError("unclosed scalar")
        if raw[0] == '"':
            return json.loads(raw)
        return raw[1:-1].replace("''", "'")
    if raw.startswith("[") or raw.startswith("{"):
        raise ValueError("unsupported scalar")
    return raw


def read_metadata(path):
    try:
        with path.open("rb") as stream:
            raw_content = stream.read(FRONTMATTER_LIMIT + 1)
    except OSError:
        return None, "unreadable metadata"
    content = raw_content[:FRONTMATTER_LIMIT].decode("utf-8", errors="replace")
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, "missing frontmatter opener"
    end = next((index for index, line in enumerate(lines[1:], 1) if line.strip() == "---"), None)
    if end is None:
        return None, "oversized frontmatter" if len(raw_content) > FRONTMATTER_LIMIT else "missing frontmatter closer"
    fields = {}
    index = 1
    try:
        while index < end:
            line = lines[index]
            index += 1
            if not line.strip() or line.lstrip().startswith("#") or line[:1].isspace():
                continue
            match = re.match(r"^([A-Za-z_][\w-]*):(?:\s*(.*))?$", line)
            if not match:
                continue
            key, raw = match.group(1), match.group(2) or ""
            if key not in ("name", "description"):
                continue
            if key in fields:
                raise ValueError("duplicate frontmatter field")
            if raw.strip() in (">", ">-", ">+", "|", "|-", "|+"):
                parts = []
                while index < end and (not lines[index].strip() or lines[index][:1].isspace()):
                    parts.append(lines[index].strip())
                    index += 1
                fields[key] = " ".join(part for part in parts if part)
            else:
                fields[key] = scalar(raw)
    except ValueError as error:
        return None, str(error)
    if not fields.get("name") or "description" not in fields:
        return None, "frontmatter requires name and description"
    return {"name": fields["name"], "description": fields["description"]}, None


def path_is_retired(path):
    return any(part.lower() == ".trash" for part in path.parts)


def audit(snapshot):
    if not isinstance(snapshot, dict) or not isinstance(snapshot.get("skills"), list):
        raise ValueError("snapshot must be an object containing a skills array")
    skills = []
    issues = []
    canonical_by_name = {}

    def add_issue(code, skill, source, detail):
        issues.append({"code": code, "name": skill, "source": source, "detail": detail})

    for item in snapshot["skills"]:
        if not isinstance(item, dict) or not isinstance(item.get("source"), dict):
            raise ValueError("each skill must contain source metadata")
        name = item.get("name") if isinstance(item.get("name"), str) else ""
        description = item.get("description") if isinstance(item.get("description"), str) else ""
        source_type = item["source"].get("type")
        source_path = item["source"].get("path")
        source_type = source_type if isinstance(source_type, str) else ""
        source_path = source_path if isinstance(source_path, str) else ""
        row = {"name": name, "description": description, "source": {"type": source_type, "path": source_path}}
        skills.append(row)
        if not description.strip():
            add_issue("empty_description", name, row["source"], "catalog description is empty")
        if not source_path:
            continue
        lexical = Path(source_path).expanduser()
        resolved = lexical.resolve(strict=False)
        if path_is_retired(lexical) or path_is_retired(resolved):
            add_issue("retired_source", name, row["source"], "source path is under .trash")
        skill_file = lexical / "SKILL.md" if lexical.is_dir() else lexical
        if not skill_file.exists():
            add_issue("missing_source", name, row["source"], "source path does not exist")
            continue
        if skill_file.is_file() and skill_file.name == "SKILL.md":
            metadata, error = read_metadata(skill_file)
            if error:
                add_issue("malformed_metadata", name, row["source"], error)
            else:
                if metadata["name"] != name:
                    add_issue("metadata_name_mismatch", name, row["source"], "catalog and SKILL.md names differ")
                if metadata["description"].strip() != description.strip():
                    add_issue("metadata_description_mismatch", name, row["source"], "catalog and SKILL.md descriptions differ")
            canonical_by_name.setdefault(name, set()).add(str(skill_file.resolve(strict=False)))

    for name, paths in canonical_by_name.items():
        if name and len(paths) > 1:
            issues.append({"code": "duplicate_effective_name", "name": name, "sources": sorted(paths), "detail": "same effective name resolves to distinct SKILL.md files"})

    return {
        "skills": skills,
        "mcpServers": [
            {"name": row.get("name", "") if isinstance(row.get("name", ""), str) else "", "type": row.get("type", "") if isinstance(row.get("type", ""), str) else ""}
            for row in snapshot.get("mcpServers", []) if isinstance(row, dict)
        ],
        "plugins": [
            {"name": row.get("name", "") if isinstance(row.get("name", ""), str) else "", "enabled": row.get("enabled") if isinstance(row.get("enabled"), bool) else False}
            for row in snapshot.get("plugins", []) if isinstance(row, dict)
        ],
        "issues": issues,
        "usageEvidence": {"available": False, "disuse": "not assessed; no usage history was provided", "retirementRecommendation": None},
    }


def main():
    parser = argparse.ArgumentParser(description="Audit an explicitly supplied skill catalog snapshot (read only).")
    parser.add_argument("--snapshot", required=True, help="path to a saved catalog JSON snapshot")
    args = parser.parse_args()
    try:
        with open(args.snapshot, encoding="utf-8") as stream:
            result = audit(json.load(stream))
    except (OSError, json.JSONDecodeError, ValueError) as error:
        print(f"catalog audit: {error}", file=sys.stderr)
        return 2
    json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
