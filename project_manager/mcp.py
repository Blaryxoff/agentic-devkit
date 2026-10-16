import json
import sys

from . import core


def _schema(fields):
    return {"type": "object", "properties": {"project": {"type": "string"}, **fields}, "required": ["project", *fields], "additionalProperties": False}


def _tools():
    return [
        {"name": "projects_status", "description": "Check local projects and, with a project ID, its discovered worktrees and their IDs before opening or testing pages.", "inputSchema": {"type": "object", "properties": {"project": {"type": "string"}}, "additionalProperties": False}, "annotations": {"readOnlyHint": True}},
        {"name": "project_start", "description": "Start a configured project or discovered worktree and check readiness before browser testing.", "inputSchema": _schema({}), "annotations": {"idempotentHint": True}},
        {"name": "project_stop", "description": "Stop only processes launched by this project manager.", "inputSchema": _schema({}), "annotations": {"destructiveHint": True, "idempotentHint": True}},
        {"name": "project_logs", "description": "Read recent, redacted output for a managed service.", "inputSchema": _schema({"service": {"type": "string"}}), "annotations": {"readOnlyHint": True}},
        {"name": "worktree_flags", "description": "Inspect a discovered worktree for modified, untracked, ignored, or unpublished files and commits.", "inputSchema": _schema({}), "annotations": {"readOnlyHint": True}},
        {"name": "worktree_remove", "description": "Remove a stopped worktree checkout and its local files while keeping its branch. Requires the worktree branch name as confirmation when modified, untracked, or ignored files exist.", "inputSchema": {"type": "object", "properties": {"project": {"type": "string"}, "confirmation": {"type": "string"}}, "required": ["project"], "additionalProperties": False}, "annotations": {"destructiveHint": True}},
        {"name": "project_select_profile", "description": "Persist a project profile's local environment settings and restart managed services if running.", "inputSchema": _schema({"profile": {"type": "string"}}), "annotations": {"destructiveHint": True}},
    ]


def _call(projects, name, arguments):
    if name == "projects_status":
        if arguments.get("project"):
            return core.project_status(projects, arguments["project"])
        return [core.status(project) for project in projects if not project.get("parent_id")]
    project = core.find_project(projects, arguments["project"])
    if name == "project_start":
        return core.start(project)
    if name == "project_stop":
        return core.stop(project)
    if name == "project_logs":
        return core.logs(project, arguments["service"])
    if name == "worktree_flags":
        return core.worktree_flags(project)
    if name == "worktree_remove":
        if not project.get("parent_id"):
            raise core.ProjectError("Worktree required")
        return core.remove_worktree(project, core.find_project(projects, project["parent_id"]), arguments.get("confirmation"))
    if name == "project_select_profile":
        return core.select_profile(project, arguments["profile"])
    raise core.ProjectError(f"Unknown tool: {name}")


def serve(config_path):
    for line in sys.stdin:
        request = None
        try:
            request = json.loads(line)
            identifier = request.get("id")
            method = request.get("method")
            if method == "notifications/initialized":
                continue
            if method == "initialize":
                result = {"protocolVersion": "2025-11-25", "capabilities": {"tools": {}}, "serverInfo": {"name": "devkit-projects", "version": "1.0.0"}}
            elif method == "ping":
                result = {}
            elif method == "tools/list":
                result = {"tools": _tools()}
            elif method == "tools/call":
                params = request.get("params", {})
                try:
                    projects = core.load_config(config_path)
                    value = _call(projects, params["name"], params.get("arguments", {}))
                    result = {"content": [{"type": "text", "text": json.dumps(value, ensure_ascii=False)}]}
                except (core.ProjectError, KeyError, OSError) as error:
                    result = {"content": [{"type": "text", "text": str(error)}], "isError": True}
            else:
                raise ValueError(f"Unknown method: {method}")
            if identifier is not None:
                print(json.dumps({"jsonrpc": "2.0", "id": identifier, "result": result}, ensure_ascii=False), flush=True)
        except (ValueError, TypeError, KeyError) as error:
            if isinstance(request, dict) and request.get("id") is not None:
                print(json.dumps({"jsonrpc": "2.0", "id": request["id"], "error": {"code": -32600, "message": str(error)}}), flush=True)
