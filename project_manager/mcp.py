import json
import sys

from . import core


def _schema(project_ids, fields):
    return {"type": "object", "properties": {"project": {"type": "string", "enum": project_ids}, **fields}, "required": ["project", *fields], "additionalProperties": False}


def _tools(projects):
    ids = [project["id"] for project in projects]
    return [
        {"name": "projects_status", "description": "Check configured local projects, services, health, ports, and profiles before opening or testing their pages in a browser.", "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False}, "annotations": {"readOnlyHint": True}},
        {"name": "project_start", "description": "Start every configured service for a stopped local project and check readiness before browser testing.", "inputSchema": _schema(ids, {}), "annotations": {"idempotentHint": True}},
        {"name": "project_stop", "description": "Stop only processes launched by this project manager.", "inputSchema": _schema(ids, {}), "annotations": {"destructiveHint": True, "idempotentHint": True}},
        {"name": "project_logs", "description": "Read recent, redacted output for a managed service.", "inputSchema": _schema(ids, {"service": {"type": "string"}}), "annotations": {"readOnlyHint": True}},
        {"name": "project_select_profile", "description": "Persist a project profile's local environment settings and restart managed services if running.", "inputSchema": _schema(ids, {"profile": {"type": "string"}}), "annotations": {"destructiveHint": True}},
    ]


def _call(projects, name, arguments):
    if name == "projects_status":
        return [core.status(project) for project in projects]
    project = core.find_project(projects, arguments["project"])
    if name == "project_start":
        return core.start(project)
    if name == "project_stop":
        return core.stop(project)
    if name == "project_logs":
        return core.logs(project, arguments["service"])
    if name == "project_select_profile":
        return core.select_profile(project, arguments["profile"])
    raise core.ProjectError(f"Unknown tool: {name}")


def serve(projects):
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
                result = {"tools": _tools(projects)}
            elif method == "tools/call":
                params = request.get("params", {})
                try:
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
