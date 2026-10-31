import argparse
import json
import os
import re
import shlex
import sys
from pathlib import Path


DEFAULT_CONFIG = Path(__file__).resolve().parents[3] / "projects.json"
DENIAL = (
    "Canonical dev-server policy: use projects_status/project_start or devkit-projects "
    "status/start for the registered checkout and runtime profile. Repair a missing or "
    "unavailable shared registry first; do not fall back to an ad hoc server or port. "
    "Register any approved isolated QA runtime with an owner and teardown plan."
)
SHELL_TOOLS = {"Bash", "Shell", "exec_command", "shell_command", "run_terminal_cmd", "RunCommand", "Terminal"}


def shell_text(command):
    output = []
    delimiters = []
    for line in command.splitlines():
        if delimiters:
            if line.strip() == delimiters[0]:
                delimiters.pop(0)
            continue
        output.append(line)
        delimiters.extend(re.findall(r"<<-?\s*['\"]?([A-Za-z_][A-Za-z_0-9]*)['\"]?", line))
    return "\n".join(output)


def without_options(tokens, value_options=()):
    remaining = []
    skip = False
    for token in tokens:
        if skip:
            skip = False
        elif token in value_options:
            skip = True
        elif token == "--":
            continue
        elif not token.startswith("-"):
            remaining.append(token)
    return remaining


def script_arguments(tokens):
    while tokens and tokens[0].startswith("-"):
        count = 2 if tokens[0] in {"--require", "-r", "--import", "--loader"} else 1
        tokens = tokens[count:]
    return tokens


def server_segment(tokens, depth=0):
    if not tokens or depth > 8:
        return False
    while tokens and (re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", tokens[0]) or tokens[0] in {"then", "do", "!", "{"}):
        tokens = tokens[1:]
    if not tokens:
        return False
    name = Path(tokens[0]).name
    args = tokens[1:]
    if any(token in {"--help", "-h", "--version", "-v"} for token in args):
        return False
    if name in {"sh", "bash", "zsh", "fish"}:
        for index, token in enumerate(args):
            if token.startswith("-") and "c" in token and index + 1 < len(args):
                return launches_server(args[index + 1], depth + 1)
        return False
    if name in {"env", "nohup", "time", "command", "exec", "sudo"}:
        return server_segment(without_options(args, {"-u", "--unset", "-C", "--chdir", "-u", "-g"}), depth + 1)
    if name in {"fnm", "mise", "asdf", "volta"} and "--" in args:
        return server_segment(args[args.index("--") + 1:], depth + 1)
    if name == "corepack":
        return server_segment(args, depth + 1)
    if name in {"npm", "pnpm", "yarn", "bun"}:
        clean = without_options(args, {"--dir", "-C", "--cwd", "--prefix", "--filter", "-F", "--workspace", "-w", "--port", "-p"})
        if clean and clean[0] in {"exec", "dlx", "x"}:
            return server_segment(clean[1:], depth + 1)
        if clean and clean[0] in {"run", "run-script"}:
            clean = clean[1:]
        if clean and clean[0] in {"dev", "start", "serve", "preview"}:
            return True
        if name == "bun" and clean:
            return server_segment(script_arguments(args), depth + 1)
        return False
    if name in {"npx", "bunx"}:
        return server_segment(without_options(args, {"--package", "-p", "--cache"}), depth + 1)
    if name in {"node", "nodejs"}:
        return server_segment(script_arguments(args), depth + 1)
    package = name.split("@")[0]
    if package in {"next", "nuxt", "nuxt.mjs", "nuxi", "nuxi.mjs", "vite", "vite.js"}:
        clean = without_options(args, {"--port", "-p", "--host", "--hostname", "--config", "-c"})
        if package in {"vite", "vite.js"}:
            return not clean or clean[0] not in {"build", "optimize"}
        return not clean or clean[0] in {"dev", "start", "serve", "preview"}
    if name == "php":
        return "-S" in args or (len(args) > 1 and Path(args[0]).name == "artisan" and args[1] in {"serve", "octane:start", "reverb:start"})
    return False


def shell_tokens(command):
    word = []
    quote = None
    escaped = False
    comment = False
    for char in shell_text(command):
        if comment and char != "\n":
            continue
        comment = False
        if escaped:
            if char == "\n":
                word.pop()
            else:
                word.append(char)
            escaped = False
        elif char == "\\" and quote != "'":
            word.append(char)
            escaped = True
        elif quote:
            word.append(char)
            if char == quote:
                quote = None
        elif char in {"'", '"'}:
            word.append(char)
            quote = char
        elif char == "#" and not word:
            comment = True
        elif char.isspace() or char in ";&|()":
            if word:
                yield shlex.split("".join(word))[0], False
                word = []
            if char == "\n" or char in ";&|()":
                yield char, True
        else:
            word.append(char)
    if word:
        yield shlex.split("".join(word))[0], False


def launches_server(command, depth=0):
    try:
        tokens = list(shell_tokens(command))
    except ValueError:
        return False
    segment = []
    for token, separator in tokens + [(";", True)]:
        if separator:
            if server_segment(segment, depth):
                return True
            segment = []
        else:
            segment.append(token)
    return False


def check_payload(payload, config_path=None, platform=None, required_config=False):
    if (platform or sys.platform) != "darwin" or not isinstance(payload, dict):
        return None
    tool = payload.get("tool_name", payload.get("toolName", ""))
    if not isinstance(tool, str):
        return None
    if tool and tool.rsplit(".", 1)[-1] not in SHELL_TOOLS:
        return None
    inputs = payload.get("tool_input", payload.get("toolInput", payload))
    if not isinstance(inputs, dict):
        return None
    command = inputs.get("command", inputs.get("cmd", ""))
    if not isinstance(command, str) or not launches_server(command):
        return None
    selected = config_path or os.environ.get("DEVKIT_PROJECTS_CONFIG")
    try:
        config = json.loads(Path(selected or DEFAULT_CONFIG).expanduser().read_text())
        enabled = config.get("canonical_dev_servers", False)
        if type(enabled) is not bool:
            raise ValueError("canonical_dev_servers must be boolean")
    except (OSError, ValueError, AttributeError):
        return DENIAL if required_config else None
    return DENIAL if enabled else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=Path)
    parser.add_argument("--require-config", action="store_true")
    args = parser.parse_args()
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        return 0
    denial = check_payload(payload, args.config, required_config=args.require_config)
    if denial:
        print(denial, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
