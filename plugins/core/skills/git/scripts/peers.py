#!/usr/bin/env python3
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlsplit

UUID = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
SHELLS = {"sh", "bash", "zsh", "fish", "dash", "login", "tcsh", "ksh"}


def control(*args):
    command = os.environ.get("AGTERMCTL", "agtermctl")
    env = os.environ.copy()
    socket = env.get("AGTERM_SOCKET")
    argv = [command, *args, *(["--socket", socket] if socket else [])]
    try:
        return subprocess.run(
            argv, capture_output=True, text=True, stdin=subprocess.DEVNULL,
            timeout=15, env=env, check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return subprocess.CompletedProcess(argv, 127, "", "")


def git(*args, cwd):
    command = ["git", "-C", str(cwd), *args]
    try:
        return subprocess.run(
            command, capture_output=True, text=True, stdin=subprocess.DEVNULL,
            timeout=8, check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return subprocess.CompletedProcess(command, 127, "", "")


def clean_remote(raw):
    raw = raw.strip()
    if raw.startswith(("/", "./", "../")):
        return ""
    match = re.match(r"^(?:[^/@:]+@)?([^/:]+):(.+)$", raw)
    if match and "://" not in raw:
        host, path = match.groups()
    elif "://" in raw:
        try:
            parsed = urlsplit(raw)
            host, path = parsed.hostname or "", parsed.path
        except ValueError:
            return ""
    else:
        return ""
    host = host.lower().rstrip(".")
    path = path.split("?", 1)[0].split("#", 1)[0].strip("/")
    if path.endswith(".git"):
        path = path[:-4]
    if host == "github.com":
        path = path.casefold()
    return f"{host}/{path}" if host and path else ""


def git_identity(cwd):
    if not cwd:
        return None
    root = git("rev-parse", "--show-toplevel", cwd=cwd)
    common = git("rev-parse", "--git-common-dir", cwd=cwd)
    if root.returncode or common.returncode:
        return None
    root_path = Path(root.stdout.strip()).resolve()
    common_path = Path(common.stdout.strip())
    if not common_path.is_absolute():
        common_path = Path(cwd) / common_path
    common_path = common_path.resolve()
    remote = git("remote", "get-url", "origin", cwd=cwd)
    return {"root": str(root_path), "common_dir": str(common_path), "remote": clean_remote(remote.stdout) if remote.returncode == 0 else ""}


def basename(value):
    return os.path.basename(str(value).rstrip("/"))


def classify(argv):
    if not isinstance(argv, list) or not argv:
        return None
    command = basename(argv[0])
    if not command or command.lower() in SHELLS:
        return None
    lowered = [str(item).lower() for item in argv]
    if command == "agent" and any("cursor-agent" in item and "index.js" in item for item in lowered[1:]):
        return command, "cursor"
    if command in ("cursor-agent",):
        return command, "cursor"
    if command == "codex":
        return command, "codex"
    if command == "claude":
        return command, "claude"
    return command, ""


def sessions(value):
    if isinstance(value, dict):
        if "foreground" in value or "splitForeground" in value or "surfaces" in value:
            yield value
        for child in value.values():
            yield from sessions(child)
    elif isinstance(value, list):
        for child in value:
            yield from sessions(child)


def panes(session):
    surfaces = session.get("surfaces")
    found = set()
    if isinstance(surfaces, list):
        for surface in surfaces:
            if not isinstance(surface, dict):
                continue
            pane = surface.get("kind")
            if pane not in ("left", "right"):
                continue
            found.add(pane)
            yield pane, surface.get("paneID"), session.get("foreground" if pane == "left" else "splitForeground") or [], surface
    for pane, field in (("left", "foreground"), ("right", "splitForeground")):
        argv = session.get(field) or []
        if argv and pane not in found:
            yield pane, None, argv, {}


def endpoint(window, session, pane, pane_id, command, harness, info):
    return {
        "window": window, "session": session, "pane": pane, "pane_id": pane_id,
        "command": command, "harness": harness,
        "cwd": info.get("cwd" if pane == "left" else "splitCwd") or info.get("cwd") or "",
        "label": info.get("context") or info.get("name") or info.get("title") or "",
        "status": info.get("status", ""), "status_pane": info.get("statusPane", ""),
    }


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--self-session")
    parser.add_argument("--self-pane-id")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    self_session = args.self_session if args.self_session is not None else os.environ.get("AGTERM_SESSION_ID")
    self_pane = args.self_pane_id if args.self_pane_id is not None else os.environ.get("AGTERM_PANE_ID")
    errors, unresolved, peers = [], [], []
    repo = git_identity(args.repo)
    if not repo:
        repo = {"root": str(Path(args.repo).resolve()), "common_dir": "", "remote": ""}
        errors.append("repository identity unavailable")
    windows_result = control("window", "list", "--json")
    windows = []
    available = windows_result.returncode == 0
    if available:
        try:
            payload = json.loads(windows_result.stdout)
            result = payload.get("result") if isinstance(payload, dict) and payload.get("ok") is not False else None
            windows = result.get("windows") if isinstance(result, dict) else None
        except (ValueError, AttributeError):
            available = False
        if not isinstance(windows, list):
            available, windows = False, []
    if not available:
        errors.append("window inventory unavailable")
    self_endpoint = None
    selectors_supplied = self_session is not None or self_pane is not None
    selectors_valid = not selectors_supplied or bool(self_session and self_pane and UUID.fullmatch(self_session) and UUID.fullmatch(self_pane))
    self_session_key = self_session.lower() if selectors_valid and self_session else None
    self_pane_key = self_pane.lower() if selectors_valid and self_pane else None
    if selectors_supplied and not selectors_valid:
        errors.append("self selectors must include full session and pane UUIDs")
    identities = {}
    for window_info in windows:
        window = window_info.get("id") if isinstance(window_info, dict) else None
        if not isinstance(window, str) or not UUID.fullmatch(window):
            errors.append("window inventory contains a missing or invalid window UUID")
            continue
        if window_info.get("open") is False:
            continue
        tree_result = control("tree", "--json", "--window", window)
        if tree_result.returncode:
            errors.append(f"tree inventory unavailable for window {window}")
            continue
        try:
            payload = json.loads(tree_result.stdout)
            result = payload.get("result") if isinstance(payload, dict) and payload.get("ok") is not False else None
            tree = result.get("tree") if isinstance(result, dict) else None
        except (ValueError, AttributeError):
            errors.append(f"tree inventory invalid for window {window}")
            continue
        if not isinstance(tree, dict) or not isinstance(tree.get("workspaces"), list):
            errors.append(f"tree inventory invalid for window {window}")
            continue
        for session in sessions(tree):
            sid = session.get("id")
            for pane, pane_id, observed, surface in panes(session):
                identity = classify(observed)
                if identity is None and observed and basename(observed[0]).lower() in SHELLS:
                    continue
                command, harness = identity if identity else ("", "")
                cwd = session.get("cwd" if pane == "left" else "splitCwd") or session.get("cwd")
                if cwd and cwd not in identities:
                    identities[cwd] = git_identity(cwd)
                repo_id = identities.get(cwd) if cwd else None
                same_repo = bool(repo_id and (
                    repo_id["common_dir"] and repo["common_dir"] and repo_id["common_dir"] == repo["common_dir"]
                    or repo_id["remote"] and repo["remote"] and repo_id["remote"] == repo["remote"]
                ))
                if not same_repo:
                    continue
                stable_session = isinstance(sid, str) and bool(UUID.fullmatch(sid))
                stable_pane = isinstance(pane_id, str) and bool(UUID.fullmatch(pane_id))
                stable = stable_session and stable_pane
                endpoint_value = endpoint(window, sid if stable_session else None, pane, pane_id if stable_pane else None, command, harness, session)
                if identity is None or not harness or not stable:
                    reasons = []
                    if identity is None:
                        reasons.append("unreadable foreground")
                    elif not harness:
                        reasons.append("unknown process")
                    if not stable:
                        reasons.append("missing stable session or pane identity")
                    unresolved.append({**endpoint_value, "reason": "; ".join(reasons)})
                    continue
                if selectors_valid and stable and self_session_key == sid.lower() and self_pane_key == pane_id.lower():
                    self_endpoint = endpoint_value
                else:
                    peers.append(endpoint_value)
    if selectors_supplied and selectors_valid and self_endpoint is None:
        errors.append("pinned self pane was not found")
    report = {
        "repository": repo, "available": available,
        "complete": available and not errors and not unresolved,
        "self": self_endpoint, "peers": peers, "unresolved": unresolved, "errors": errors,
    }
    print(json.dumps(report, sort_keys=True))
    return 0 if report["complete"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
