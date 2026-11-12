#!/usr/bin/env python3
import glob
import json
import os
import re
import subprocess
import sys

UUID = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
HOME = os.path.expanduser("~")
SHELLS = {"sh", "bash", "zsh", "fish", "dash", "login"}


def resumed_id(argv):
    for i, arg in enumerate(argv):
        if arg in ("--resume", "-r") and i + 1 < len(argv) and UUID.match(argv[i + 1]):
            return argv[i + 1]
    return None


def transcript(argv):
    sid = resumed_id(argv or [])
    if not sid:
        return "-"
    hits = glob.glob(f"{HOME}/.claude/projects/*/{sid}.jsonl")
    return max(hits, key=os.path.getmtime) if hits else "-"


def label(info):
    raw = info.get("context") or info.get("name") or info.get("title") or "session"
    slug = re.sub(r"[^\w]+", "-", raw.lstrip("✳◐· ")).strip("-")[:32]
    return slug or "session"


def walk(tree):
    for ws in tree.get("workspaces", []):
        yield from ws.get("sessions", [])


def main():
    own = os.environ.get("AGTERM_SESSION_ID", "")
    out = subprocess.run(["agtermctl", "tree", "--json"], capture_output=True, text=True, check=True)
    tree = json.loads(out.stdout)["result"]["tree"]
    for info in walk(tree):
        if info["id"] == own:
            continue
        for pane, field in (("left", "foreground"), ("right", "splitForeground")):
            argv = info.get(field) or []
            if pane == "right" and not info.get("hasSplit"):
                continue
            command = os.path.basename(argv[0]) if argv else ""
            if not command or command in SHELLS or any(c.isspace() for c in command):
                continue
            path = transcript(argv) if command == "claude" else "-"
            print(f"{info['id']} {label(info)} {path} {pane} {command}")
            print(f"#   cwd={info.get('cwd')} pane={pane} command={command}", file=sys.stderr)


if __name__ == "__main__":
    main()
