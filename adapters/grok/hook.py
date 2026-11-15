#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
ALIASES = {
    "read_file": "Read",
    "search_replace": "Edit",
    "edit_file": "Edit",
    "write_file": "Write",
    "write": "Write",
    "delete_file": "Delete",
    "run_terminal_command": "Bash",
    "run_terminal_cmd": "Bash",
}
EDITS = {"Edit", "Write", "MultiEdit", "apply_patch", "StrReplace", "Delete", "EditNotebook"}


def deny(reason):
    print(json.dumps({"decision": "deny", "reason": reason}))
    return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--server-config", type=Path)
    parser.add_argument("--require-server-config", action="store_true")
    args = parser.parse_args()
    try:
        payload = json.load(sys.stdin)
        if not isinstance(payload, dict):
            return deny("devkit: Grok supplied an invalid hook payload.")
        tool = payload.get("tool_name", payload.get("toolName", ""))
        if not isinstance(tool, str):
            return deny("devkit: Grok supplied an invalid tool name.")
        tool = ALIASES.get(tool, tool)
        inputs = payload.get("tool_input", payload.get("toolInput", {}))
        if not isinstance(inputs, dict):
            return deny("devkit: Grok supplied invalid tool inputs.")
        inputs = dict(inputs)
        target = inputs.get("file_path", inputs.get("target_file", inputs.get("path")))
        if target is not None:
            inputs.update(path=target, file_path=target)
        payload.update(tool_name=tool, tool_input=inputs)
        sid = payload.get("session_id", payload.get("sessionId", ""))
        payload["session_id"] = sid
        commands = []
        if tool == "Read" or tool in EDITS:
            if tool in EDITS:
                safe_sid = re.sub(r"[^A-Za-z0-9._-]", "_", str(sid))
                marker = Path(os.environ.get("TMPDIR", tempfile.gettempdir())) / f"devkit-coder-active-{safe_sid}"
                if not sid or not marker.is_file():
                    return deny("Read the devkit-coder SKILL.md before editing in this Grok session: " + str(ROOT / "plugins/core/skills/coder/SKILL.md"))
            commands.append(["sh", str(ROOT / "plugins/core/hooks/coder-gate.sh")])
        if tool in EDITS:
            commands.append(["sh", str(ROOT / "plugins/core/hooks/comment-gate.sh")])
        if tool == "Bash":
            server = ["sh", str(ROOT / "plugins/core/hooks/dev-server-gate.sh")]
            if args.server_config:
                server.extend(["--config", str(args.server_config)])
            if args.require_server_config:
                server.append("--require-config")
            commands.extend([["sh", str(ROOT / "plugins/core/hooks/peer-cli-gate.sh")], server])
        for command in commands:
            result = subprocess.run(command, input=json.dumps(payload), capture_output=True, text=True, timeout=12)
            output = json.loads(result.stdout) if result.stdout.strip() else {}
            if not isinstance(output, dict) or not isinstance(output.get("hookSpecificOutput", {}), dict):
                return deny("devkit: invalid decision from " + Path(command[1]).name)
            details = output.get("hookSpecificOutput", {})
            decision = details.get("permissionDecision", output.get("decision"))
            if result.returncode or decision in {"deny", "block"}:
                reason = details.get("permissionDecisionReason", output.get("reason"))
                return deny(reason or result.stderr.strip() or "devkit: hook failed: " + Path(command[1]).name)
        return 0
    except (OSError, ValueError, TypeError, subprocess.TimeoutExpired) as error:
        return deny("devkit: could not verify this Grok tool call: " + str(error))


if __name__ == "__main__":
    sys.exit(main())
