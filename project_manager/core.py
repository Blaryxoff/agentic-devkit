import contextlib
import fcntl
import hashlib
import json
import os
import re
import shutil
import signal
import socket
import subprocess
import tempfile
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener


CONFIG_PATH = Path(os.environ.get("DEVKIT_PROJECTS_CONFIG", Path(__file__).resolve().parent.parent / "projects.json")).expanduser()
STATE_PATH = Path(os.environ.get("XDG_STATE_HOME", "~/.local/state")).expanduser() / "agentic-devkit/projects"
IDENTIFIER = re.compile(r"^[a-z][a-z0-9_-]*$")
PROFILE_IDENTIFIER = re.compile(r"^[A-Za-z][A-Za-z0-9_-]*$")
ENV_KEY = re.compile(r"^[A-Z][A-Z0-9_]*$")
SECRET = re.compile(r'''(?i)(["']?\b[a-z0-9_-]*(?:password|token|secret|(?:api|app|private|access)[_-]?key|authorization|cookie|database[_-]?url|redis[_-]?url|dsn)\b["']?\s*[:=]\s*)(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[^\s,}]+)''')
AUTHORIZATION = re.compile(r"(?i)(\bAuthorization\s*[:=]\s*)[^\r\n]+")
BEARER = re.compile(r"(?i)\bBearer\s+[^\s,}\]]+")
URL_CREDENTIALS = re.compile(r"(?i)(\b[a-z][a-z0-9+.-]*://)[^\s/@]+:[^\s/@]+@")


class ProjectError(Exception):
    pass


class _NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *_):
        return None


HTTP = build_opener(ProxyHandler({}), _NoRedirect)
SPAWNED = {}
PORT_TOKEN = re.compile(r"\{port(\d+)\}")


def redact(value):
    value = AUTHORIZATION.sub(r"\1[redacted]", value)
    value = BEARER.sub("Bearer [redacted]", value)
    value = URL_CREDENTIALS.sub(r"\1[redacted]@", value)
    return SECRET.sub(r"\1[redacted]", value)


def load_config(path=CONFIG_PATH):
    path = Path(path).expanduser()
    try:
        data = json.loads(path.read_text())
    except (OSError, ValueError) as error:
        raise ProjectError(f"Cannot read config {path}: {error}") from error
    if not isinstance(data, dict) or data.get("version") != 1 or not isinstance(data.get("projects"), list):
        raise ProjectError("Config requires version 1 and a projects list")
    projects = data["projects"]
    projects.extend(_discover_worktrees(projects))
    ids = set()
    ports = set()
    for project in projects:
        if not isinstance(project, dict) or not isinstance(project.get("root"), str) or not project["root"]:
            raise ProjectError("Every project needs a root directory")
        identifier = project.get("id")
        if not isinstance(identifier, str) or not IDENTIFIER.fullmatch(identifier) or identifier in ids:
            raise ProjectError(f"Invalid or repeated project ID: {identifier}")
        ids.add(identifier)
        root = Path(project.get("root", "")).expanduser()
        if not root.is_dir():
            raise ProjectError(f"Missing project directory for {identifier}: {root}")
        project["root"] = str(root.resolve())
        if not isinstance(project.get("services"), list) or (not project["services"] and not (project.get("parent_id") and project.get("slot") is None)):
            raise ProjectError(f"Project {identifier} needs services")
        service_ids = set()
        for service in project["services"]:
            if not isinstance(service, dict):
                raise ProjectError(f"Invalid service in {identifier}")
            sid = service.get("id")
            if not isinstance(sid, str) or not IDENTIFIER.fullmatch(sid) or sid in service_ids:
                raise ProjectError(f"Invalid or repeated service ID in {identifier}: {sid}")
            service_ids.add(sid)
            if not isinstance(service.get("argv"), list) or not service["argv"] or not all(isinstance(arg, str) for arg in service["argv"]):
                raise ProjectError(f"Service {identifier}/{sid} needs an argv list")
            if not isinstance(service.get("cwd", "."), str):
                raise ProjectError(f"Invalid working directory for {identifier}/{sid}")
            service["cwd"] = str((root / service.get("cwd", ".")).resolve())
            if not Path(service["cwd"]).is_dir():
                raise ProjectError(f"Missing working directory for {identifier}/{sid}")
            if not isinstance(service.get("ports", []), list):
                raise ProjectError(f"Invalid ports for {identifier}/{sid}")
            for port in service.get("ports", []):
                if not isinstance(port, int) or not 0 < port < 65536 or port in ports:
                    raise ProjectError(f"Invalid or repeated managed port: {port}")
                ports.add(port)
            if not isinstance(service.get("env", {}), dict) or not all(isinstance(key, str) and isinstance(value, str) for key, value in service.get("env", {}).items()):
                raise ProjectError(f"Invalid environment overrides for {identifier}/{sid}")
            if not isinstance(service.get("checks", []), list):
                raise ProjectError(f"Invalid checks for {identifier}/{sid}")
            for check in service.get("checks", []):
                _validate_check(check)
        if not isinstance(project.get("external", []), list):
            raise ProjectError(f"Invalid external checks for {identifier}")
        for check in project.get("external", []):
            _validate_check(check)
        if not isinstance(project.get("links", {}), dict) or any(not isinstance(label, str) or not isinstance(url, str) or urlsplit(url).scheme not in ("http", "https") for label, url in project.get("links", {}).items()):
            raise ProjectError(f"Invalid links for {identifier}")
        if not isinstance(project.get("profiles", {}), dict):
            raise ProjectError(f"Invalid profiles for {identifier}")
        for name, profile in project.get("profiles", {}).items():
            if not isinstance(name, str) or not PROFILE_IDENTIFIER.fullmatch(name):
                raise ProjectError(f"Invalid profile name: {name}")
            if not isinstance(profile, dict):
                raise ProjectError(f"Invalid profile: {identifier}/{name}")
            if not isinstance(profile.get("set"), dict) or not profile["set"]:
                raise ProjectError(f"Profile {identifier}/{name} needs settings")
            for key, value in profile["set"].items():
                if not ENV_KEY.fullmatch(key) or not isinstance(value, str) or "\n" in value or "\r" in value:
                    raise ProjectError(f"Invalid setting in {identifier}/{name}: {key}")
        if project.get("profiles") and not project.get("profile_env_file"):
            raise ProjectError(f"Project {identifier} needs profile_env_file")
        if project.get("profile_env_file") is not None and not isinstance(project["profile_env_file"], str):
            raise ProjectError(f"Invalid profile env file for {identifier}")
        if not isinstance(project.get("profile_hooks", []), list):
            raise ProjectError(f"Invalid profile hooks for {identifier}")
        for argv in project.get("profile_hooks", []):
            if not isinstance(argv, list) or not argv or not all(isinstance(arg, str) for arg in argv):
                raise ProjectError(f"Invalid profile hook for {identifier}")
    ranges = []
    for project in projects:
        settings = project.get("worktrees")
        if settings is None:
            continue
        start = settings["port_base"]
        end = start + settings["slots"] * settings["slot_size"]
        base_ports = (port for parent in projects if not parent.get("parent_id") for service in parent["services"] for port in service.get("ports", []))
        if any(start <= port < end for port in base_ports) or any(start < other_end and other_start < end for other_start, other_end in ranges):
            raise ProjectError(f"Reserved worktree ports overlap in {project['id']}")
        ranges.append((start, end))
    return projects


def _worktree_id(parent_id, path):
    digest = hashlib.sha256(str(path).encode()).hexdigest()[:10]
    return f"{parent_id}-wt-{digest}"


def _worktree_records(root):
    try:
        result = subprocess.run(["git", "-C", str(root), "worktree", "list", "--porcelain"], capture_output=True, text=True, timeout=5, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise ProjectError(f"Cannot list worktrees for {root}: {error}") from error
    if result.returncode:
        raise ProjectError(f"Cannot list worktrees for {root}: {result.stderr.strip()}")
    records = []
    for block in result.stdout.strip().split("\n\n"):
        lines = block.splitlines()
        if not lines or not lines[0].startswith("worktree ") or any(line.startswith("prunable ") for line in lines):
            continue
        path = Path(lines[0][9:]).resolve()
        if path == root or not path.is_dir():
            continue
        branch = next((line[18:] for line in lines if line.startswith("branch refs/heads/")), None)
        head = next((line[5:] for line in lines if line.startswith("HEAD ")), "")
        records.append({"path": path, "branch": branch or f"detached {head[:7]}", "detached": branch is None})
    return sorted(records, key=lambda record: (record["branch"], str(record["path"])))


def _worktree_registry():
    try:
        return json.loads((STATE_PATH / "worktree-slots.json").read_text())
    except FileNotFoundError:
        return {}
    except (OSError, ValueError) as error:
        raise ProjectError(f"Cannot read worktree slots: {error}") from error


def _write_worktree_registry(registry):
    descriptor, temp = tempfile.mkstemp(prefix=".worktree-slots-", dir=STATE_PATH)
    try:
        with os.fdopen(descriptor, "w") as handle:
            json.dump(registry, handle)
        os.chmod(temp, 0o600)
        os.replace(temp, STATE_PATH / "worktree-slots.json")
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def _worktree_settings(project):
    settings = project["worktrees"]
    if not isinstance(settings, dict):
        raise ProjectError(f"Invalid worktree settings for {project['id']}")
    if "slots" not in settings and isinstance(settings.get("slot_size"), int) and settings["slot_size"] > 0:
        settings["slots"] = max(1, 10 // settings["slot_size"])
    for key in ("port_base", "slot_size", "slots"):
        value = settings.get(key)
        if not isinstance(value, int) or isinstance(value, bool) or value <= 0:
            raise ProjectError(f"Invalid worktree {key} for {project['id']}")
    if settings["port_base"] + settings["slots"] * settings["slot_size"] > 65536:
        raise ProjectError(f"Worktree port range exceeds 65535 for {project['id']}")
    if not isinstance(settings.get("services"), list) or not settings["services"]:
        raise ProjectError(f"Worktree services required for {project['id']}")
    for service in settings["services"]:
        if not isinstance(service, dict) or not isinstance(service.get("ports"), list) or not service["ports"]:
            raise ProjectError(f"Worktree services need managed ports for {project['id']}")
        for port in service["ports"]:
            match = PORT_TOKEN.fullmatch(str(port))
            if not match or int(match.group(1)) >= settings["slot_size"]:
                raise ProjectError(f"Worktree managed ports must use a slot offset in {project['id']}")
    return settings


def _render_worktree(value, settings, slot):
    if isinstance(value, str):
        def replace(match):
            offset = int(match.group(1))
            if offset >= settings["slot_size"]:
                raise ProjectError(f"Worktree port offset {offset} exceeds slot size")
            return str(settings["port_base"] + slot * settings["slot_size"] + offset)
        return PORT_TOKEN.sub(replace, value)
    if isinstance(value, list):
        return [_render_worktree(item, settings, slot) for item in value]
    if isinstance(value, dict):
        return {key: _render_worktree(item, settings, slot) for key, item in value.items()}
    return value


def _materialize_worktree(project, slot):
    settings = project["_worktree_template"]
    values = _render_worktree({key: value for key, value in settings.items() if key not in ("port_base", "slot_size", "slots", "id", "name", "root", "parent_id", "branch", "slot")}, settings, slot)
    project.update(values)
    project["slot"] = slot
    for service in project["services"]:
        service["ports"] = [int(port) for port in service.get("ports", [])]
        service["cwd"] = str((Path(project["root"]) / service.get("cwd", ".")).resolve())
        for check in service.get("checks", []):
            if check.get("type") == "tcp":
                check["port"] = int(check["port"])
    for check in project.get("external", []):
        if check.get("type") == "tcp":
            check["port"] = int(check["port"])


def _discover_worktrees(parents):
    registry = _worktree_registry()
    children = []
    for parent in parents:
        if not isinstance(parent, dict) or "worktrees" not in parent:
            continue
        if not isinstance(parent.get("root"), str) or not isinstance(parent.get("id"), str):
            raise ProjectError("Worktree parent needs an ID and root directory")
        root = Path(parent["root"]).expanduser().resolve()
        if not root.is_dir():
            raise ProjectError(f"Missing project directory for {parent['id']}: {root}")
        settings = _worktree_settings(parent)
        records = _worktree_records(root)
        parent["_worktree_count"] = len(records)
        assignments = registry.get(parent["id"], {})
        for record in records:
            path = record["path"]
            slot = assignments.get(str(path), {}).get("slot")
            child = {"id": _worktree_id(parent["id"], path), "name": record["branch"], "root": str(path),
                     "parent_id": parent["id"], "branch": record["branch"], "detached": record["detached"], "slot": None,
                     "_worktree_template": settings, "services": [], "links": {}}
            if isinstance(slot, int) and not isinstance(slot, bool) and 0 <= slot < settings["slots"]:
                _materialize_worktree(child, slot)
            children.append(child)
    return children


def _worktree_slot_ports(settings, slot):
    services = _render_worktree(settings["services"], settings, slot)
    return [int(port) for service in services for port in service.get("ports", [])]


def _worktree_slot_running(parent_id, path, settings):
    identifier = _worktree_id(parent_id, path)
    return any(_owned({"id": identifier}, service) for service in settings["services"])


def _assign_worktree_slot(project):
    settings = project["_worktree_template"]
    parent_id = project["parent_id"]
    path = project["root"]
    with _locked({"id": "worktree-slots"}):
        registry = _worktree_registry()
        assignments = registry.setdefault(parent_id, {})
        existing = assignments.get(path)
        if existing:
            slot = existing["slot"]
        else:
            used = {entry["slot"] for entry in assignments.values()}
            choices = [(slot, None) for slot in range(settings["slots"]) if slot not in used]
            choices += [(entry["slot"], old_path) for old_path, entry in sorted(assignments.items(), key=lambda item: item[1].get("used", 0))
                        if entry.get("pending_until", 0) < time.time() and not _worktree_slot_running(parent_id, old_path, settings)]
            slot = None
            for candidate, old_path in choices:
                if not any(_port_busy(port) for port in _worktree_slot_ports(settings, candidate)):
                    slot = candidate
                    if old_path:
                        del assignments[old_path]
                    break
            if slot is None:
                raise ProjectError(f"No free worktree port slots for {parent_id}")
        assignments[path] = {"slot": slot, "used": time.time(), "pending_until": time.time() + 120}
        _write_worktree_registry(registry)
    if project.get("slot") != slot:
        _materialize_worktree(project, slot)


def _clear_worktree_pending(project):
    with _locked({"id": "worktree-slots"}):
        registry = _worktree_registry()
        entry = registry.get(project["parent_id"], {}).get(project["root"])
        if entry and entry.get("slot") == project["slot"]:
            entry.pop("pending_until", None)
            _write_worktree_registry(registry)


def _validate_check(check):
    if not isinstance(check, dict):
        raise ProjectError(f"Invalid health check: {check}")
    if check.get("type") == "http" and isinstance(check.get("url"), str) and check["url"].startswith(("http://", "https://")):
        allowed = check.get("allow_statuses", [])
        if isinstance(allowed, list) and all(isinstance(code, int) and not isinstance(code, bool) and 400 <= code < 600 for code in allowed):
            return
    if check.get("type") == "tcp" and isinstance(check.get("host"), str) and isinstance(check.get("port"), int) and 0 < check["port"] < 65536:
        return
    raise ProjectError(f"Invalid health check: {check}")


def find_project(projects, identifier):
    for project in projects:
        if project["id"] == identifier:
            return project
    raise ProjectError(f"Unknown project: {identifier}")


def project_status(projects, identifier):
    project = find_project(projects, identifier)
    result = status(project)
    if not project.get("parent_id") and "worktrees" in project:
        result["worktrees"] = [status(child) for child in projects if child.get("parent_id") == identifier]
    return result


def worktree_flags(project):
    if not project.get("parent_id"):
        raise ProjectError("Worktree required")
    root = project["root"]
    try:
        changes = subprocess.run(["git", "-C", root, "status", "--porcelain=v1", "--ignored=matching", "--untracked-files=normal"], capture_output=True, text=True, errors="replace", timeout=15, check=False)
        upstream = subprocess.run(["git", "-C", root, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"], capture_output=True, text=True, timeout=5, check=False)
        if upstream.returncode == 0:
            published = subprocess.run(["git", "-C", root, "rev-list", "--count", f"{upstream.stdout.strip()}..HEAD"], capture_output=True, text=True, timeout=5, check=False)
            unpushed = published.stdout.strip() != "0"
        else:
            published = subprocess.run(["git", "-C", root, "branch", "-r", "--contains", "HEAD", "--format=%(refname)"], capture_output=True, text=True, timeout=5, check=False)
            unpushed = not bool(published.stdout.strip())
    except (OSError, subprocess.TimeoutExpired) as error:
        raise ProjectError(f"Cannot inspect worktree {project['id']}: {error}") from error
    for result in (changes, published):
        if result.returncode:
            raise ProjectError(f"Cannot inspect worktree {project['id']}: {redact(result.stderr.strip())}")
    lines = changes.stdout.splitlines()
    return {"id": project["id"], "dirty": any(not line.startswith(("??", "!!")) for line in lines),
            "untracked": any(line.startswith("??") for line in lines), "ignored": any(line.startswith("!!") for line in lines),
            "unpushed": unpushed, "detached": project["detached"]}


def remove_worktree(project, parent, confirmation=None):
    if project.get("parent_id") != parent["id"]:
        raise ProjectError("Worktree does not belong to this project")
    with _locked({"id": "worktree-slots"}):
        with _locked(project):
            registry = _worktree_registry()
            entry = registry.get(parent["id"], {}).get(project["root"], {})
            if entry.get("pending_until", 0) > time.time() or any(_owned(project, service) for service in project["services"]):
                raise ProjectError("Stop this worktree before deleting it")
            flags = worktree_flags(project)
            if flags["dirty"] or flags["untracked"]:
                raise ProjectError("Worktree has local changes or untracked files")
            if flags["detached"] and flags["unpushed"]:
                raise ProjectError("Detached worktree has commits not found on a remote branch")
            if flags["ignored"] and confirmation != project["branch"]:
                raise ProjectError("Deleting ignored local files requires typing the worktree name")
            try:
                result = subprocess.run(["git", "-C", parent["root"], "worktree", "remove", "--", project["root"]], capture_output=True, text=True, timeout=30, check=False)
            except (OSError, subprocess.TimeoutExpired) as error:
                raise ProjectError(f"Cannot remove worktree: {error}") from error
            if result.returncode:
                raise ProjectError(f"Cannot remove worktree: {redact(result.stderr.strip())}")
            registry.get(parent["id"], {}).pop(project["root"], None)
            _write_worktree_registry(registry)
    return {"id": project["id"], "deleted": True}


def _state_file(project, service):
    return STATE_PATH / f"{project['id']}-{service['id']}.json"


@contextlib.contextmanager
def _locked(project):
    STATE_PATH.mkdir(parents=True, exist_ok=True)
    STATE_PATH.chmod(0o700)
    with (STATE_PATH / f"{project['id']}.lock").open("a+") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        yield


def _birth(pid):
    result = subprocess.run(["ps", "-p", str(pid), "-o", "lstart="], capture_output=True, text=True, check=False)
    return result.stdout.strip() if result.returncode == 0 else ""


def _owned(project, service):
    try:
        state = json.loads(_state_file(project, service).read_text())
        pid = state["pid"]
        if _birth(pid) == state["birth"] and os.getpgid(pid) == pid:
            return state
    except (OSError, ValueError, KeyError, ProcessLookupError):
        pass
    return None


def _port_busy(port):
    for host in ("127.0.0.1", "::1"):
        try:
            with socket.create_connection((host, port), timeout=0.15):
                return True
        except OSError:
            continue
    return False


def _managed_process(pid):
    try:
        group = os.getpgid(pid)
    except ProcessLookupError:
        return False
    for path in STATE_PATH.glob("*.json"):
        try:
            state = json.loads(path.read_text())
            if isinstance(state, dict) and state.get("pid") == group:
                return True
        except (OSError, ValueError):
            continue
    return False


def _port_listeners(port):
    lsof = shutil.which("lsof") or next((path for path in ("/usr/sbin/lsof", "/usr/bin/lsof") if Path(path).is_file()), None)
    if not lsof:
        return []
    try:
        result = subprocess.run([lsof, "-nP", "-a", f"-iTCP:{port}", "-sTCP:LISTEN", "-Fpcun"], capture_output=True, text=True, timeout=3, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return []
    listeners = []
    current = None
    for line in result.stdout.splitlines():
        kind, value = line[:1], line[1:]
        if kind == "p":
            current = {"pid": int(value), "command": "process", "uid": None, "addresses": []} if value.isdigit() and int(value) > 0 else None
            if current:
                listeners.append(current)
        elif current and kind == "c":
            current["command"] = value
        elif current and kind == "u" and value.isdigit():
            current["uid"] = int(value)
        elif current and kind == "n":
            current["addresses"].append(value)
    found = []
    for item in listeners:
        if not any(address.rpartition(":")[0] in ("*", "0.0.0.0", "127.0.0.1", "[::]", "[::1]") and address.rpartition(":")[2] == str(port) for address in item["addresses"]):
            continue
        pid = item["pid"]
        birth = _birth(pid)
        reason = "other_user" if item["uid"] != os.geteuid() else "dashboard" if pid == os.getpid() else "managed" if _managed_process(pid) else "unknown" if not birth else None
        found.append({"port": port, "pid": pid, "command": item["command"], "birth": birth, "stoppable": reason is None, "reason": reason})
    return found


def _check(check):
    if check["type"] == "tcp":
        try:
            with socket.create_connection((check["host"], check["port"]), timeout=0.4):
                return True
        except OSError:
            return False
    try:
        with HTTP.open(Request(check["url"], headers={"User-Agent": "devkit-projects/1"}), timeout=1.5):
            return True
    except HTTPError as error:
        error.close()
        return 300 <= error.code < 400 or error.code in check.get("allow_statuses", [])
    except (OSError, URLError):
        return False


def _profile_file(project):
    path = (Path(project["root"]) / project["profile_env_file"]).resolve()
    if not path.is_relative_to(Path(project["root"])):
        raise ProjectError("Profile env file must be inside the project")
    return path


def _env_values(path):
    values = {}
    if path.exists():
        for line in path.read_text().splitlines():
            match = re.match(r"^([A-Z][A-Z0-9_]*)=(.*)$", line)
            if match:
                values[match.group(1)] = match.group(2).strip().strip('"\'')
    return values


def selected_profile(project):
    if not project.get("profiles"):
        return None
    values = _env_values(_profile_file(project))
    for name, profile in project["profiles"].items():
        if all(values.get(key) == value for key, value in profile["set"].items()):
            return name
    return None


def status(project):
    if project.get("parent_id") and project.get("slot") is None:
        return {"id": project["id"], "name": project["name"], "root": project["root"], "state": "stopped", "services": [], "external": [], "links": {}, "profiles": [], "profile": None,
                "parent_id": project["parent_id"], "branch": project["branch"], "slot": None}
    services = []
    for service in project["services"]:
        owned = _owned(project, service)
        checks = [{"id": c.get("id", c.get("url", str(c.get("port")))), "ok": _check(c)} for c in service.get("checks", [])]
        busy = [port for port in service.get("ports", []) if _port_busy(port)]
        state = "running" if owned and all(c["ok"] for c in checks) else "starting" if owned else "conflict" if busy else "stopped"
        services.append({"id": service["id"], "state": state, "checks": checks, "busy_ports": busy, "listeners": [listener for port in busy for listener in _port_listeners(port)] if not owned else [], "pid": owned["pid"] if owned else None})
    external = [{"id": c.get("id", c.get("url", str(c.get("port")))), "ok": _check(c)} for c in project.get("external", [])]
    states = {s["state"] for s in services}
    overall = "conflict" if "conflict" in states else "stopped" if states == {"stopped"} else "running" if states == {"running"} and all(c["ok"] for c in external) else "degraded"
    result = {"id": project["id"], "name": project.get("name", project["id"]), "root": project["root"], "state": overall, "services": services, "external": external, "links": project.get("links", {}), "profiles": list(project.get("profiles", {})), "profile": selected_profile(project)}
    if project.get("parent_id"):
        result.update(parent_id=project["parent_id"], branch=project["branch"], slot=project["slot"])
    elif "_worktree_count" in project:
        result["worktree_count"] = project["_worktree_count"]
    return result


def _spawn(project, service):
    conflicts = [port for port in service.get("ports", []) if _port_busy(port)]
    if conflicts:
        raise ProjectError(f"{project['id']}/{service['id']}: ports in use by another process: {conflicts}")
    log_path = STATE_PATH / f"{project['id']}-{service['id']}.log"
    env = os.environ.copy()
    env.update(service.get("env", {}))
    with log_path.open("ab", buffering=0) as log:
        log_path.chmod(0o600)
        process = subprocess.Popen(service["argv"], cwd=service["cwd"], env=env, stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    SPAWNED[process.pid] = process
    birth = _birth(process.pid)
    if not birth:
        raise ProjectError(f"{project['id']}/{service['id']} exited immediately; see logs")
    _state_file(project, service).write_text(json.dumps({"pid": process.pid, "birth": birth}))


def start(project, timeout=60):
    if project.get("parent_id"):
        _assign_worktree_slot(project)
    try:
        with _locked(project):
            for service in project["services"]:
                if not _owned(project, service):
                    conflicts = [port for port in service.get("ports", []) if _port_busy(port)]
                    if conflicts:
                        raise ProjectError(f"{project['id']}/{service['id']}: ports in use by another process: {conflicts}")
            for service in project["services"]:
                if not _owned(project, service):
                    _spawn(project, service)
    finally:
        if project.get("parent_id"):
            _clear_worktree_pending(project)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        current = status(project)
        if current["state"] == "running":
            return current
        if current["state"] == "conflict" or any(not _owned(project, s) for s in project["services"]):
            break
        time.sleep(0.5)
    current = status(project)
    if current["state"] == "running":
        return current
    if all(service["state"] == "running" for service in current["services"]):
        failed = ", ".join(check["id"] for check in current["external"] if not check["ok"])
        raise ProjectError(f"{project['id']} started, but external checks did not become healthy: {failed}")
    raise ProjectError(f"{project['id']} did not become healthy ({current['state']}); inspect logs and external checks")


def _stop_locked(project):
    owned = [(service, _owned(project, service)) for service in project["services"]]
    for _, state in owned:
        if state:
            os.killpg(state["pid"], signal.SIGTERM)
    deadline = time.monotonic() + 8
    while time.monotonic() < deadline and any(state and _owned(project, service) for service, state in owned):
        time.sleep(0.2)
    for service, state in owned:
        if state and _owned(project, service):
            os.killpg(state["pid"], signal.SIGKILL)
        if state and state["pid"] in SPAWNED:
            SPAWNED.pop(state["pid"]).wait(timeout=1)
        _state_file(project, service).unlink(missing_ok=True)


def stop(project):
    if project.get("parent_id") and project.get("slot") is None:
        return status(project)
    with _locked(project):
        _stop_locked(project)
    return status(project)


def release_port(project, port, pid, birth):
    if type(port) is not int or type(pid) is not int or not isinstance(birth, str) or not birth:
        raise ProjectError("Port, PID, and process identity required")
    if not any(port in service.get("ports", []) for service in project["services"]):
        raise ProjectError("Port is not managed by this project")
    with _locked(project):
        listener = next((item for item in _port_listeners(port) if item["pid"] == pid and item["birth"] == birth), None)
        if not listener or not listener["stoppable"] or not _port_busy(port):
            raise ProjectError("Port owner changed or cannot be stopped here; refresh status")
        os.kill(pid, signal.SIGTERM)
        deadline = time.monotonic() + 4
        while _port_busy(port) and time.monotonic() < deadline:
            time.sleep(0.1)
    if _port_busy(port):
        raise ProjectError(f"Port {port} is still occupied; inspect the process in a terminal")
    return status(project)


def _write_env(path, original, settings):
    text = original.decode()
    lines = text.splitlines(keepends=True)
    found = set()
    for index, line in enumerate(lines):
        match = re.match(r"^([A-Z][A-Z0-9_]*)=", line)
        if match and match.group(1) in settings:
            key = match.group(1)
            lines[index] = f"{key}={settings[key]}\n"
            found.add(key)
    if lines and not lines[-1].endswith("\n"):
        lines[-1] += "\n"
    lines.extend(f"{key}={value}\n" for key, value in settings.items() if key not in found)
    _atomic_write(path, "".join(lines).encode())


def _atomic_write(path, data):
    descriptor, temp = tempfile.mkstemp(prefix=".devkit-projects-", dir=path.parent)
    try:
        os.fchmod(descriptor, path.stat().st_mode & 0o777)
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(data)
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def select_profile(project, name):
    if name not in project.get("profiles", {}):
        raise ProjectError(f"Unknown profile for {project['id']}: {name}")
    if selected_profile(project) == name:
        return status(project)
    with _locked(project):
        running = any(_owned(project, service) for service in project["services"])
        if any(not _owned(project, service) and any(_port_busy(port) for port in service.get("ports", [])) for service in project["services"]):
            raise ProjectError("Cannot switch profile while an external server uses this project's ports")
        if running:
            _stop_locked(project)
        path = _profile_file(project)
        original = path.read_bytes()
        _write_env(path, original, project["profiles"][name]["set"])
        try:
            for argv in project.get("profile_hooks", []):
                result = subprocess.run(argv, cwd=project["root"], capture_output=True, text=True, timeout=30, check=False)
                if result.returncode:
                    raise ProjectError(f"Profile hook failed: {redact(result.stderr[-500:])}")
        except (OSError, subprocess.TimeoutExpired, ProjectError) as error:
            _atomic_write(path, original)
            for argv in project.get("profile_hooks", []):
                subprocess.run(argv, cwd=project["root"], capture_output=True, timeout=30, check=False)
            if running:
                for service in project["services"]:
                    _spawn(project, service)
            raise ProjectError(str(error)) from error
    if running:
        return start(project)
    return status(project)


def logs(project, service_id, lines=80):
    service = next((item for item in project["services"] if item["id"] == service_id), None)
    if service is None:
        raise ProjectError(f"Unknown service: {service_id}")
    path = STATE_PATH / f"{project['id']}-{service_id}.log"
    if not path.exists():
        return ""
    with path.open("rb") as handle:
        handle.seek(max(0, path.stat().st_size - 65536))
        return redact("\n".join(handle.read().decode(errors="replace").splitlines()[-min(lines, 200):]))
