#!/usr/bin/env python3
import datetime
import json
import math
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
import tomllib


def read_json(path):
    data = json.loads(path.read_text()) if path.exists() else {}
    if not isinstance(data, dict) or not isinstance(data.get("mcpServers", {}), dict):
        raise ValueError(f"{path.name}: expected an object with an mcpServers object")
    return data


def toml_value(value):
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, (int, float)):
        if isinstance(value, float) and not math.isfinite(value):
            return str(value).lower()
        return str(value)
    if isinstance(value, (datetime.datetime, datetime.date, datetime.time)):
        return value.isoformat()
    if isinstance(value, list):
        return "[" + ", ".join(toml_value(item) for item in value) + "]"
    if isinstance(value, dict):
        return "{ " + ", ".join(f"{toml_value(key)} = {toml_value(item)}" for key, item in value.items()) + " }"
    raise ValueError("unsupported value in MCP configuration")


def table_path(header):
    node = tomllib.loads(header)
    path = []
    while isinstance(node, dict) and len(node) == 1:
        key, node = next(iter(node.items()))
        path.append(key)
        if isinstance(node, list):
            node = node[0]
    return tuple(path)


def replace_tables(content, replacements):
    headers = []
    for match in re.finditer(r"(?m)^[ \t]*\[.*\][ \t]*(?:#.*)?$", content):
        try:
            tomllib.loads(content[:match.start()])
            path = table_path(match.group())
        except tomllib.TOMLDecodeError:
            continue
        headers.append((match.start(), path))
    chunks = []
    offset = 0
    emitted = set()
    for index, (start, path) in enumerate(headers):
        end = headers[index + 1][0] if index + 1 < len(headers) else len(content)
        target = next((key for key in replacements if path[:len(key)] == key), None)
        if target is None:
            continue
        chunks.append(content[offset:start])
        if target not in emitted:
            values = replacements[target]
            chunks.append("[" + ".".join(toml_value(key) for key in target) + "]\n")
            chunks.extend(f"{toml_value(key)} = {toml_value(value)}\n" for key, value in values.items())
            chunks.append("\n")
            emitted.add(target)
        offset = end
    chunks.append(content[offset:])
    result = "".join(chunks)
    for path, values in replacements.items():
        if path in emitted:
            continue
        node = tomllib.loads(content)
        for key in path:
            if not isinstance(node, dict) or key not in node:
                break
            node = node[key]
        else:
            raise ValueError("MCP configuration uses inline or dotted tables; use explicit server tables before syncing")
        result = result.rstrip() + "\n\n[" + ".".join(toml_value(key) for key in path) + "]\n"
        result += "".join(f"{toml_value(key)} = {toml_value(value)}\n" for key, value in values.items())
    result = result.rstrip() + "\n"
    tomllib.loads(result)
    return result


def transport(server, project):
    if not isinstance(server, dict):
        raise ValueError("MCP server definitions must be objects")
    if server.get("disabled", False):
        raise ValueError("disabled JSON MCP servers cannot be shared safely; move the entry to a client-specific configuration")
    kind = server.get("type", "http" if "url" in server else "stdio")
    if kind == "stdio":
        if not isinstance(server.get("command"), str) or not server["command"] or "url" in server:
            raise ValueError("stdio MCP servers need a command and no URL")
        server.setdefault("cwd", str(project))
        if not isinstance(server["cwd"], str) or not server["cwd"]:
            raise ValueError("stdio MCP cwd must be a nonempty string")
        if not isinstance(server.get("args", []), list) or not all(isinstance(arg, str) for arg in server.get("args", [])):
            raise ValueError("stdio MCP args must be strings")
        fields = {key: server[key] for key in ("command", "args", "env", "cwd") if key in server}
        mapping = server.get("env", {})
    elif kind == "http":
        if not isinstance(server.get("url"), str) or not server["url"] or "command" in server:
            raise ValueError("HTTP MCP servers need a URL and no command")
        fields = {key: server[key] for key in ("url", "headers") if key in server}
        mapping = server.get("headers", {})
    else:
        raise ValueError("only stdio and Streamable HTTP MCP servers can be shared across all clients")
    if not isinstance(mapping, dict) or not all(isinstance(key, str) and isinstance(value, str) for key, value in mapping.items()):
        raise ValueError("MCP env and headers must map strings to strings")
    return fields


def native_config(path, servers, client):
    content = path.read_text() if path.exists() else ""
    config = tomllib.loads(content)
    existing = config.get("mcp_servers", {})
    if not isinstance(existing, dict):
        raise ValueError("native mcp_servers must be a table")
    replacements = {}
    for name, shared in servers.items():
        current = existing.get(name, {})
        if not isinstance(current, dict):
            raise ValueError("native MCP server must be a table")
        merged = {key: value for key, value in current.items() if key not in ("command", "args", "cwd", "env", "url")}
        if "command" in shared or current.get("url") != shared.get("url"):
            for key in ("headers", "http_headers", "env_http_headers", "http_headers_helper", "bearer_token_env_var", "auth"):
                merged.pop(key, None)
        merged.update(shared)
        if client == "codex" and "headers" in merged:
            merged["http_headers"] = merged.pop("headers")
        merged["enabled"] = True
        replacements[("mcp_servers", name)] = dict(sorted(merged.items()))
    if client == "grok":
        for source in ("claude", "cursor"):
            compat = dict(config.get("compat", {}).get(source, {}))
            compat["mcps"] = False
            replacements[("compat", source)] = compat
    return replace_tables(content, replacements)


def sync(project, defaults):
    canonical_path = project / ".mcp.json"
    cursor_path = project / ".cursor/mcp.json"
    canonical = read_json(canonical_path)
    cursor = read_json(cursor_path)
    canonical_servers = canonical.get("mcpServers", {})
    cursor_servers = cursor.get("mcpServers", {})
    servers = defaults | cursor_servers | canonical_servers
    for name in cursor_servers.keys() - canonical_servers.keys():
        if isinstance(servers[name], dict):
            servers[name] = {key: value for key, value in servers[name].items() if key != "headers"}
    if not servers:
        return
    for server in servers.values():
        transport(server, project)
    private_servers = {name: dict(server) for name, server in servers.items()}
    for name, server in private_servers.items():
        local = cursor_servers.get(name, {})
        if "url" in server and isinstance(local, dict) and local.get("url") == server["url"] and "headers" in local:
            headers = local["headers"]
            if not isinstance(headers, dict) or not all(isinstance(key, str) and isinstance(value, str) for key, value in headers.items()):
                raise ValueError("MCP headers must map strings to strings")
            server["headers"] = headers | server.get("headers", {})
    native = {name: transport(server, project) for name, server in private_servers.items()}
    canonical["mcpServers"] = servers
    cursor["mcpServers"] = private_servers
    outputs = {
        canonical_path: json.dumps(canonical, indent=2, ensure_ascii=False) + "\n",
        cursor_path: json.dumps(cursor, indent=2, ensure_ascii=False) + "\n",
    }
    for client in ("codex", "grok"):
        path = project / f".{client}/config.toml"
        outputs[path] = native_config(path, native, client)
    staged = []
    try:
        for path, content in outputs.items():
            path = path.resolve()
            if path.exists() and path.read_text() == content:
                continue
            path.parent.mkdir(parents=True, exist_ok=True)
            fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.devkit-", dir=path.parent)
            staged.append((temporary, path))
            with os.fdopen(fd, "w") as handle:
                handle.write(content)
            if path.exists():
                os.chmod(temporary, stat.S_IMODE(path.stat().st_mode))
        for temporary, path in staged:
            os.replace(temporary, path)
    finally:
        for temporary, _ in staged:
            if os.path.exists(temporary):
                os.unlink(temporary)
    print(f"    Synced: project MCP catalogues ({len(servers)} server(s); Claude, Cursor, Codex, Grok)")


if __name__ == "__main__":
    try:
        sync(Path(sys.argv[1]).resolve(), json.load(sys.stdin))
    except (ValueError, OSError) as error:
        if isinstance(error, (json.JSONDecodeError, tomllib.TOMLDecodeError)):
            message = "invalid project MCP JSON or TOML; existing configuration was not changed"
        elif isinstance(error, OSError):
            message = "could not read or write project MCP configuration"
        else:
            message = str(error)
        print(f"ERROR: {message}", file=sys.stderr)
        sys.exit(1)
