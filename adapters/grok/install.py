import json
from pathlib import Path
import re
import shlex
import sys
import tempfile


def write_file(path, content):
    path = path.resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        stream.write(content)
    try:
        if path.exists():
            temporary.chmod(path.stat().st_mode & 0o777)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def is_managed(command):
    try:
        return any(value.endswith("/adapters/grok/hook.py") for value in shlex.split(command))
    except ValueError:
        return False


def install(root, grok_home, server_command):
    hooks_file = grok_home / "hooks/devkit-toolkit.json"
    data = json.loads(hooks_file.read_text()) if hooks_file.exists() else {}
    hooks = data.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise ValueError("Grok hooks must be an object")
    for event, groups in hooks.items():
        if not isinstance(groups, list):
            raise ValueError("Grok hook groups must be arrays")
        for group in groups:
            if not isinstance(group, dict) or not isinstance(group.get("hooks", []), list):
                raise ValueError("Invalid Grok hook group")
            handlers = group.get("hooks", [])
            if not all(isinstance(handler, dict) for handler in handlers):
                raise ValueError("Invalid Grok hook handler")
            group["hooks"] = [handler for handler in handlers if not is_managed(handler.get("command", ""))]
        hooks[event] = [group for group in groups if group.get("hooks")]

    server_args = shlex.split(server_command)
    config = server_args[server_args.index("--config") + 1]
    command = ["python3", str(root / "adapters/grok/hook.py"), "--server-config", config]
    if "--require-config" in server_args:
        command.append("--require-server-config")
    hooks.setdefault("PreToolUse", []).append({"hooks": [{
        "type": "command", "command": " ".join(shlex.quote(value) for value in command), "timeout": 60,
    }]})

    agents_file = grok_home / "AGENTS.md"
    current = agents_file.read_text() if agents_file.exists() else ""
    start, end = "<!-- devkit-grok:start -->", "<!-- devkit-grok:end -->"
    if (current.count(start) != current.count(end) or current.count(start) > 1
            or (start in current and current.index(start) > current.index(end))):
        raise ValueError("Grok guidance has malformed devkit markers")
    section = f"""{start}
## devkit in Grok

Use the discovered devkit skills and project instructions. To activate a skill, read its SKILL.md or use Grok's
native skill tool when available. Claude Skill(...) examples mean activate the equivalent skill in Grok;
they do not mean launch Claude or call a Claude-only tool. Before the first code edit, read
`{root}/plugins/core/skills/coder/SKILL.md`.

For work owned by a devkit workflow, follow devkit's routing and authorization gates. Bundled Grok skills can provide
capabilities devkit lacks; they must not silently start a second implementation/review pipeline or change AI providers.

Project stack skills, agents, hooks, and MCP servers use Grok's Claude compatibility. Preserve normal project
folder trust. Do not replace the configured Herd/DBngin runtime; resolve it with devkit-projects before serving.
Keep one writer per checkout and follow devkit-pair's selected-peer and delivery rules for paired work.
Use the agterm skill to resolve live session and pane identities before terminal actions.

Plan mode is not a shell sandbox. For read-only reviews, use an enforced tool boundary and verify the
actual worktree. Before finishing implementation, run the focused verification required by the project.
{end}"""
    if start in current:
        pattern = re.escape(start) + ".*?" + re.escape(end)
        updated = re.sub(pattern, lambda _: section, current, count=1, flags=re.DOTALL)
    else:
        updated = current.rstrip() + ("\n\n" if current.strip() else "") + section + "\n"
    write_file(hooks_file, json.dumps(data, indent=2) + "\n")
    write_file(agents_file, updated)
    print("    Grok: native payload gates and managed activation guidance installed in " + str(grok_home))


if __name__ == "__main__":
    try:
        install(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).expanduser(), sys.argv[3])
    except (OSError, ValueError, TypeError, KeyError, IndexError, AttributeError) as error:
        sys.exit("ERROR: Grok integration was not installed: " + str(error))
