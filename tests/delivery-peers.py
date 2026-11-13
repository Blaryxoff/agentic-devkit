import contextlib
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

script = Path(__file__).resolve().parents[1] / "plugins/core/skills/git/scripts/peers.py"
spec = importlib.util.spec_from_file_location("delivery_peers", script)
peers = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = peers
spec.loader.exec_module(peers)

UUIDS = {
    "window": "11111111-1111-1111-1111-111111111111",
    "other_window": "22222222-2222-2222-2222-222222222222",
    "self_session": "33333333-3333-3333-3333-333333333333",
    "peer_session": "44444444-4444-4444-4444-444444444444",
    "unknown_session": "55555555-5555-5555-5555-555555555555",
    "self_pane": "66666666-6666-6666-6666-666666666666",
    "peer_pane": "77777777-7777-7777-7777-777777777777",
    "unknown_pane": "88888888-8888-8888-8888-888888888888",
}


def run_cli(args, env=None, run=None):
    out, err = io.StringIO(), io.StringIO()
    with mock.patch.dict(os.environ, env or {}, clear=True), contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        with mock.patch.object(peers.subprocess, "run", run or subprocess.run):
            code = peers.main(args)
    return code, out.getvalue(), err.getvalue()


def result(value):
    return SimpleNamespace(returncode=0, stdout=json.dumps(value), stderr="")


def inventory_fixture():
    left = {"paneID": UUIDS["self_pane"], "kind": "left", "id": f"surface:{UUIDS['self_session']}:left"}
    right = {"paneID": UUIDS["peer_pane"], "kind": "right", "id": f"surface:{UUIDS['self_session']}:right"}
    other = {"paneID": UUIDS["peer_pane"], "kind": "left", "id": f"surface:{UUIDS['peer_session']}:left"}
    missing = {"paneID": UUIDS["unknown_pane"], "kind": "left", "id": f"surface:{UUIDS['unknown_session']}:left"}
    return {
        "windows": [
            {"id": UUIDS["window"]},
            {"id": UUIDS["other_window"]},
        ],
        "trees": {
            UUIDS["window"]: {"result": {"tree": {"workspaces": [{"sessions": [
                {"id": UUIDS["self_session"], "cwd": "/repo/worktree", "context": "untrusted label", "foreground": ["codex"], "splitForeground": ["claude"], "surfaces": [left, right]},
                {"id": UUIDS["unknown_session"], "cwd": "/repo", "foreground": ["mystery-agent"], "surfaces": [missing]},
                {"id": "99999999-9999-9999-9999-999999999993", "cwd": "/repo", "status": "active", "surfaces": [{"paneID": "99999999-9999-9999-9999-999999999994", "kind": "left"}]},
            ]}]}}},
            UUIDS["other_window"]: {"result": {"tree": {"workspaces": [{"sessions": [
                {"id": UUIDS["peer_session"], "cwd": "/repo/clone", "name": "other project", "foreground": ["/usr/local/bin/agent", "--use-system-ca", "/Users/me/.local/share/cursor-agent/versions/1/index.js"], "status": "idle", "surfaces": [other]},
                {"id": "99999999-9999-9999-9999-999999999991", "cwd": "/tmp/unrelated", "context": "untrusted label", "foreground": ["claude"], "surfaces": [{"paneID": "99999999-9999-9999-9999-999999999992", "kind": "left"}]},
            ]}]}}},
        },
    }


with tempfile.TemporaryDirectory() as tmp:
    repo = Path(tmp) / "repo"
    worktree = repo / "worktree"
    clone = repo / "clone"
    unrelated = Path("/tmp/unrelated")
    # Git identity is mocked so each fixture exercises normalized identity matching.
    fixture = inventory_fixture()
    calls = []
    def mocked_run(args, **kwargs):
        calls.append((args, kwargs))
        if args[0] == "agtermctl":
            command_args = args[1:]
            socket = kwargs.get("env", {}).get("AGTERM_SOCKET")
            if socket:
                if command_args[-2:] != ["--socket", socket] or command_args[0] not in {"window", "tree"}:
                    return SimpleNamespace(returncode=1, stdout="", stderr="socket not forwarded")
                command_args = command_args[:-2]
            args = [args[0], *command_args]
        if args[1:4] == ["window", "list", "--json"]:
            return result({"result": {"windows": fixture["windows"]}})
        if args[1:3] == ["tree", "--json"]:
            return result(fixture["trees"][args[-1]])
        if "rev-parse" in args:
            cwd = Path(args[args.index("-C") + 1])
            if "--show-toplevel" in args:
                return result_text(str(repo if cwd in (worktree, repo) else clone if cwd == clone else unrelated))
            common = Path("/git/common/repo.git") if cwd in (worktree, repo) else Path("/git/common/clone.git") if cwd == clone else Path("/git/common/unrelated.git")
            return result_text(str(common))
        if args[-3:] == ["remote", "get-url", "origin"]:
            cwd = Path(args[args.index("-C") + 1])
            if cwd == clone:
                remote = "git@github.com:org/repo.git?noise=hidden#fragment"
            elif cwd == unrelated:
                remote = "https://example.com/private/other.git"
            else:
                remote = "https://secret:token@GitHub.com/Org/Repo.git?private=x#frag"
            return result_text(remote)
        raise AssertionError(args)

    def result_text(value):
        return SimpleNamespace(returncode=0, stdout=value + "\n", stderr="")

    code, stdout, stderr = run_cli([
        "--repo", str(worktree), "--self-session", UUIDS["self_session"], "--self-pane-id", UUIDS["self_pane"]
    ], {"AGTERM_SOCKET": "/tmp/test.sock"}, mocked_run)
    report = json.loads(stdout)
    assert code != 0, stderr
    assert set(report) == {"repository", "available", "complete", "self", "peers", "unresolved", "errors"}
    assert report["available"] and not report["complete"]
    assert report["repository"]["remote"] == "github.com/org/repo"
    assert report["self"]["pane_id"] == UUIDS["self_pane"]
    assert len(report["peers"]) == 2, report["peers"]
    assert {peer["harness"] for peer in report["peers"]} == {"claude", "cursor"}
    assert next(peer for peer in report["peers"] if peer["harness"] == "cursor")["command"] == "agent"
    assert len(report["unresolved"]) == 2
    assert any(item["reason"] == "unreadable foreground" for item in report["unresolved"])
    assert "secret" not in stdout and "token" not in stdout and "?private" not in stdout
    assert all(kwargs.get("stdin") == subprocess.DEVNULL for _, kwargs in calls)
    assert all(kwargs.get("timeout") for _, kwargs in calls)
    ctl_calls = [args for args, _ in calls if args[0] == "agtermctl"]
    assert len(ctl_calls) == 3
    def ctl_args(args):
        return args[1:-2] if args[-2:-1] == ["--socket"] else args[1:]
    assert all(ctl_args(args)[:3] == ["window", "list", "--json"] or ctl_args(args)[:2] == ["tree", "--json"] for args in ctl_calls)
    assert all(args[0] == "git" and ("rev-parse" in args or args[-3:] == ["remote", "get-url", "origin"]) for args, _ in calls if args[0] == "git")
    assert all("--window" in args for args in ctl_calls if "tree" in ctl_args(args))
    assert all(args[-2:] == ["--socket", "/tmp/test.sock"] for args in ctl_calls)

    # An unknown process without a stable pane identity prevents a complete absence claim.
    fixture["trees"][UUIDS["window"]]["result"]["tree"]["workspaces"][0]["sessions"][1]["surfaces"][0].pop("paneID")
    code, stdout, _ = run_cli(["--repo", str(worktree), "--self-session", UUIDS["self_session"], "--self-pane-id", UUIDS["self_pane"]], {}, mocked_run)
    assert code != 0 and not json.loads(stdout)["complete"]

    # A stale explicit pin is an error and is never replaced by a guessed self.
    code, stdout, _ = run_cli(["--repo", str(worktree), "--self-session", "99999999-9999-9999-9999-999999999999", "--self-pane-id", UUIDS["self_pane"]], {}, mocked_run)
    assert code != 0 and json.loads(stdout)["self"] is None and json.loads(stdout)["errors"]

    # Inventory failure remains distinguishable from a successful empty roster.
    def unavailable(args, **kwargs):
        if args[1] == "window":
            return SimpleNamespace(returncode=1, stdout="", stderr="secret failure")
        return mocked_run(args, **kwargs)
    code, stdout, _ = run_cli(["--repo", str(worktree)], {}, unavailable)
    assert code != 0 and not json.loads(stdout)["available"] and not json.loads(stdout)["complete"]
    assert "secret failure" not in stdout

    # Successful process exits with RPC errors or malformed inventories are incomplete, even without self selectors.
    def rpc_error(args, **kwargs):
        if args[1:4] == ["window", "list", "--json"]:
            return result({"ok": False, "error": "hidden detail"})
        return mocked_run(args, **kwargs)
    code, stdout, _ = run_cli(["--repo", str(worktree)], {}, rpc_error)
    error_report = json.loads(stdout)
    assert code != 0 and not error_report["available"] and not error_report["complete"]
    assert "hidden detail" not in stdout

    def missing_windows(args, **kwargs):
        if args[1:4] == ["window", "list", "--json"]:
            return result({"result": {}})
        return mocked_run(args, **kwargs)
    code, stdout, _ = run_cli(["--repo", str(worktree)], {}, missing_windows)
    assert code != 0 and not json.loads(stdout)["complete"]

    def missing_tree(args, **kwargs):
        if args[1:3] == ["tree", "--json"]:
            return result({"result": {}})
        return mocked_run(args, **kwargs)
    code, stdout, _ = run_cli(["--repo", str(worktree)], {}, missing_tree)
    assert code != 0 and not json.loads(stdout)["complete"]

    def tree_rpc_error(args, **kwargs):
        if args[1:3] == ["tree", "--json"]:
            return result({"ok": False, "error": "hidden tree detail"})
        return mocked_run(args, **kwargs)
    code, stdout, _ = run_cli(["--repo", str(worktree)], {}, tree_rpc_error)
    assert code != 0 and not json.loads(stdout)["complete"] and "hidden tree detail" not in stdout

    # A closed window is ignored and its stale tree is not queried.
    fixture["windows"][1]["open"] = False
    before = len(calls)
    code, stdout, _ = run_cli(["--repo", str(worktree)], {}, mocked_run)
    used = calls[before:]
    assert all(args[-1] != UUIDS["other_window"] for args, _ in used if args[0] == "agtermctl" and "tree" in args)
    fixture["windows"][1].pop("open")

    # Self UUIDs are compared case-insensitively to agterm's observed IDs.
    code, stdout, _ = run_cli([
        "--repo", str(worktree), "--self-session", UUIDS["self_session"].upper(), "--self-pane-id", UUIDS["self_pane"].upper()
    ], {}, mocked_run)
    assert json.loads(stdout)["self"] is not None

    # Git identity is cached once per cwd, despite several panes sharing that cwd.
    before = len(calls)
    run_cli(["--repo", str(worktree)], {}, mocked_run)
    new_repo_calls = [args for args, _ in calls[before:] if args[0] == "git" and "-C" in args and args[args.index("-C") + 1] == str(worktree)]
    assert len(new_repo_calls) == 3

    assert peers.clean_remote("../local/repo") == ""
    assert peers.clean_remote("https://[bad-host/repo") == ""

    # Partial tree enumeration reports an error and keeps other windows' candidates.
    def partial(args, **kwargs):
        if args[1:3] == ["tree", "--json"] and args[-1] == UUIDS["other_window"]:
            return SimpleNamespace(returncode=1, stdout="", stderr="secret failure")
        return mocked_run(args, **kwargs)
    code, stdout, _ = run_cli(["--repo", str(worktree), "--self-session", UUIDS["self_session"], "--self-pane-id", UUIDS["self_pane"]], {}, partial)
    partial_report = json.loads(stdout)
    assert code != 0 and not partial_report["complete"] and partial_report["errors"]
    assert "secret failure" not in stdout
