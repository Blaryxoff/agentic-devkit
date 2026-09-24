#!/usr/bin/env python3
import json
import sys


def texts(entry):
    kind = entry.get("type")
    if kind not in ("user", "assistant") or entry.get("isSidechain"):
        return
    content = (entry.get("message") or {}).get("content")
    if isinstance(content, str):
        if kind == "user" and not content.startswith("<"):
            yield "USER", content
        return
    for block in content or []:
        text = block.get("text", "") if block.get("type") == "text" else ""
        if text.strip() and not (kind == "user" and text.startswith("<")):
            yield kind.upper(), text


def main():
    path = sys.argv[1]
    count = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    width = int(sys.argv[3]) if len(sys.argv) > 3 else 1500
    lines = []
    with open(path, errors="ignore") as handle:
        for raw in handle:
            try:
                entry = json.loads(raw)
            except ValueError:
                continue
            stamp = (entry.get("timestamp") or "")[11:16]
            for role, text in texts(entry):
                lines.append(f"[{stamp}Z] {role}: {text}")
    for line in lines[-count:]:
        print(line[:width])
        print("---")


if __name__ == "__main__":
    main()
