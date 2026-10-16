#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHONPATH="$ROOT" python3 - <<'PY'
import json
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import ProxyHandler, Request, build_opener
from unittest.mock import patch

from project_manager import core, mcp


class ProjectManagerTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.previous_state = core.STATE_PATH
        core.STATE_PATH = self.root / "state"
        self.port = self.free_port()
        (self.root / ".env").write_text("APP_NAME=Platforma\nTENANCY_ENABLED=true\nSECRET=keep\n")
        config = {
            "version": 1,
            "projects": [{
                "id": "sample", "name": "Sample", "root": str(self.root),
                "services": [{"id": "web", "argv": [sys.executable, "-m", "http.server", str(self.port), "--bind", "127.0.0.1"],
                              "ports": [self.port], "checks": [{"type": "tcp", "host": "127.0.0.1", "port": self.port}]}],
                "profile_env_file": ".env",
                "profiles": {"Platforma": {"set": {"APP_NAME": "Platforma", "TENANCY_ENABLED": "true"}},
                             "Kochfit": {"set": {"APP_NAME": "Kochfit", "TENANCY_ENABLED": "false"}}}
            }]
        }
        path = self.root / "projects.json"
        path.write_text(json.dumps(config))
        self.project = core.load_config(path)[0]

    def tearDown(self):
        core.stop(self.project)
        core.STATE_PATH = self.previous_state
        self.temp.cleanup()

    @staticmethod
    def free_port():
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            return sock.getsockname()[1]

    def test_start_and_stop_only_managed_process(self):
        self.assertEqual(core.start(self.project, timeout=5)["state"], "running")
        self.assertEqual(core.stop(self.project)["state"], "stopped")
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", self.port))
            listener.listen()
            with self.assertRaisesRegex(core.ProjectError, "ports in use"):
                core.start(self.project, timeout=1)
            self.assertEqual(core.status(self.project)["state"], "conflict")
            self.assertEqual(core.stop(self.project)["state"], "conflict")
            self.assertEqual(listener.getsockname()[1], self.port)

    def test_release_port_checks_external_process_identity(self):
        if not shutil.which("lsof"):
            self.skipTest("lsof is unavailable")
        process = subprocess.Popen([sys.executable, "-m", "http.server", str(self.port), "--bind", "127.0.0.1"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        try:
            deadline = time.monotonic() + 5
            while not core._port_busy(self.port) and time.monotonic() < deadline:
                time.sleep(0.05)
            self.assertEqual(core.status(self.project)["state"], "conflict")
            owner = next(item for item in core._port_listeners(self.port) if item["pid"] == process.pid)
            self.assertTrue(owner["stoppable"])
            with self.assertRaisesRegex(core.ProjectError, "Port owner changed"):
                core.release_port(self.project, self.port, process.pid, "wrong birth")
            self.assertIsNone(process.poll())
            self.assertEqual(core.release_port(self.project, self.port, process.pid, owner["birth"])["state"], "stopped")
            process.wait(timeout=5)
            self.assertEqual(core.start(self.project, timeout=5)["state"], "running")
            managed = next(item for item in core._port_listeners(self.port) if item["pid"] == core.status(self.project)["services"][0]["pid"])
            self.assertEqual(managed["reason"], "managed")
            with self.assertRaisesRegex(core.ProjectError, "cannot be stopped"):
                core.release_port(self.project, self.port, managed["pid"], managed["birth"])
            self.assertEqual(core.status(self.project)["state"], "running")
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=5)

    def test_profile_preserves_unrelated_env_and_log_redaction(self):
        self.assertEqual(core.select_profile(self.project, "Kochfit")["profile"], "Kochfit")
        self.assertIn("SECRET=keep", (self.root / ".env").read_text())
        self.assertEqual(core.select_profile(self.project, "Platforma")["profile"], "Platforma")
        log = core.STATE_PATH / "sample-web.log"
        log.write_text('TOKEN=private\nSENTRY_AUTH_TOKEN=hidden\nBearer bearer-value\nAuthorization: Bearer auth-secret\n{"token": "json-secret"}\nDATABASE_URL=postgres://user:db-secret@host/db\n')
        output = core.logs(self.project, "web")
        for secret in ("private", "hidden", "bearer-value", "auth-secret", "json-secret", "db-secret"):
            self.assertNotIn(secret, output)

    def test_profile_switch_restarts_and_failed_hook_restores_env(self):
        before = core.start(self.project, timeout=5)["services"][0]["pid"]
        switched = core.select_profile(self.project, "Kochfit")
        self.assertEqual(switched["state"], "running")
        self.assertNotEqual(switched["services"][0]["pid"], before)
        self.project["profile_hooks"] = [[sys.executable, "-c", "raise SystemExit(1)"]]
        with self.assertRaisesRegex(core.ProjectError, "Profile hook failed"):
            core.select_profile(self.project, "Platforma")
        self.assertEqual(core.selected_profile(self.project), "Kochfit")
        deadline = time.monotonic() + 5
        while core.status(self.project)["state"] != "running" and time.monotonic() < deadline:
            time.sleep(0.05)
        self.assertEqual(core.status(self.project)["state"], "running")

    def test_invalid_config_has_actionable_error(self):
        for data in ([], {"version": 1, "projects": [{"id": "sample", "root": str(self.root), "services": ["bad"]}]}):
            with self.subTest(data=data):
                path = self.root / "invalid.json"
                path.write_text(json.dumps(data))
                with self.assertRaises(core.ProjectError):
                    core.load_config(path)

    def test_http_check_rejects_missing_endpoint(self):
        class Handler(BaseHTTPRequestHandler):
            code = 302

            def do_GET(self):
                self.send_response(self.code)
                self.end_headers()

            def log_message(self, *_):
                pass

        server = HTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            check = {"type": "http", "url": f"http://127.0.0.1:{server.server_port}/health"}
            self.assertTrue(core._check(check))
            Handler.code = 404
            self.assertFalse(core._check(check))
            check["allow_statuses"] = [404]
            core._validate_check(check)
            self.assertTrue(core._check(check))
            check["allow_statuses"] = ["404"]
            with self.assertRaises(core.ProjectError):
                core._validate_check(check)
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=2)

    def test_external_check_retries_and_names_persistent_failure(self):
        core.start(self.project, timeout=5)
        self.project["external"] = [{"id": "Mock Herd", "type": "http", "url": "http://example.invalid"}]
        original_check = core._check
        attempts = 0

        def transient(check):
            nonlocal attempts
            if check["type"] == "http":
                attempts += 1
                return attempts > 1
            return original_check(check)

        with patch.object(core, "_check", side_effect=transient):
            self.assertEqual(core.start(self.project, timeout=2)["state"], "running")
        self.assertGreaterEqual(attempts, 2)

        def unavailable(check):
            return False if check["type"] == "http" else original_check(check)

        with patch.object(core, "_check", side_effect=unavailable):
            with self.assertRaisesRegex(core.ProjectError, "Mock Herd"):
                core.start(self.project, timeout=0.6)

    def test_worktrees_get_isolated_reusable_port_slots(self):
        repo = self.root / "repo"
        repo.mkdir()
        subprocess.run(["git", "init", "-q", str(repo)], check=True)
        subprocess.run(["git", "-C", str(repo), "-c", "user.name=Test", "-c", "user.email=test@example.test",
                        "commit", "-qm", "initial", "--allow-empty"], check=True)
        for name in ("one", "two"):
            subprocess.run(["git", "-C", str(repo), "worktree", "add", "--quiet", "--detach", str(self.root / name)], check=True)
        worktree_port = self.free_port()
        while worktree_port == self.port:
            worktree_port = self.free_port()
        config = {"version": 1, "projects": [{
            "id": "sample", "root": str(repo), "services": [{"id": "base", "argv": [sys.executable, "-m", "http.server", str(self.port)], "ports": [self.port]}],
            "worktrees": {"port_base": worktree_port, "slot_size": 1, "slots": 1, "services": [{
                "id": "web", "argv": [sys.executable, "-m", "http.server", "{port0}", "--bind", "127.0.0.1"],
                "ports": ["{port0}"], "checks": [{"type": "tcp", "host": "127.0.0.1", "port": "{port0}"}]
            }], "links": {"Front": "http://127.0.0.1:{port0}"}}
        }]}
        path = self.root / "worktrees.json"
        path.write_text(json.dumps(config))
        projects = core.load_config(path)
        parent = projects[0]
        children = [project for project in projects if project.get("parent_id") == "sample"]
        self.assertEqual(len(children), 2)
        self.assertEqual(parent["_worktree_count"], 2)
        self.assertTrue(all(core.status(child)["state"] == "stopped" for child in children))
        first, second = children
        try:
            started = mcp._call(projects, "project_start", {"project": first["id"]})
            self.assertEqual(started["state"], "running")
            self.assertEqual(started["slot"], 0)
            self.assertEqual(started["links"]["Front"], f"http://127.0.0.1:{worktree_port}")
            self.assertEqual(core.project_status(core.load_config(path), first["id"])["state"], "running")
            with self.assertRaisesRegex(core.ProjectError, "No free worktree port slots"):
                core.start(second, timeout=1)
            self.assertEqual(mcp._call(projects, "project_stop", {"project": first["id"]})["state"], "stopped")
            self.assertEqual(core.start(second, timeout=5)["state"], "running")
            refreshed = core.load_config(path)
            self.assertEqual(core.project_status(refreshed, second["id"])["state"], "running")
            self.assertEqual(core.project_status(refreshed, first["id"])["state"], "stopped")
        finally:
            core.stop(first)
            core.stop(second)

    def test_worktree_flags_and_guarded_removal(self):
        repo = self.root / "repo"
        repo.mkdir()
        subprocess.run(["git", "init", "-q", str(repo)], check=True)
        identity = ["-c", "user.name=Test", "-c", "user.email=test@example.test"]
        (repo / ".gitignore").write_text(".env\n")
        subprocess.run(["git", "-C", str(repo), "add", ".gitignore"], check=True)
        subprocess.run(["git", "-C", str(repo), *identity, "commit", "-qm", "initial"], check=True)
        nested = repo / ".claude" / "worktrees" / "feature"
        sibling = self.root / "sibling"
        subprocess.run(["git", "-C", str(repo), "worktree", "add", "--quiet", "-b", "feature", str(nested)], check=True)
        subprocess.run(["git", "-C", str(repo), "worktree", "add", "--quiet", "--detach", str(sibling)], check=True)
        path = self.root / "worktrees.json"
        path.write_text(json.dumps({"version": 1, "projects": [{
            "id": "sample", "root": str(repo), "services": [{"id": "base", "argv": [sys.executable, "-m", "http.server", str(self.port)], "ports": [self.port]}],
            "worktrees": {"port_base": self.free_port(), "slot_size": 1, "services": [{
                "id": "web", "argv": [sys.executable, "-m", "http.server", "{port0}"], "ports": ["{port0}"]
            }]}
        }]}))
        projects = core.load_config(path)
        children = [project for project in projects if project.get("parent_id")]
        self.assertEqual({project["root"] for project in children}, {str(nested.resolve()), str(sibling.resolve())})
        feature = next(project for project in children if project["root"] == str(nested.resolve()))
        detached = next(project for project in children if project["root"] == str(sibling.resolve()))
        note = nested / "note.txt"
        note.write_text("saved\n")
        self.assertTrue(core.worktree_flags(feature)["untracked"])
        self.assertTrue(mcp._call(projects, "worktree_flags", {"project": feature["id"]})["untracked"])
        with self.assertRaisesRegex(core.ProjectError, "untracked"):
            core.remove_worktree(feature, projects[0])
        subprocess.run(["git", "-C", str(nested), "add", "note.txt"], check=True)
        subprocess.run(["git", "-C", str(nested), *identity, "commit", "-qm", "saved"], check=True)
        note.write_text("changed\n")
        self.assertTrue(core.worktree_flags(feature)["dirty"])
        note.write_text("saved\n")
        self.assertTrue(core.worktree_flags(feature)["unpushed"])
        self.assertTrue(core.worktree_flags(detached)["detached"])
        with self.assertRaisesRegex(core.ProjectError, "Detached worktree"):
            core.remove_worktree(detached, projects[0])
        (nested / ".env").write_text("LOCAL=secret\n")
        self.assertTrue(core.worktree_flags(feature)["ignored"])
        self.assertIn("worktree_remove", {tool["name"] for tool in mcp._tools()})
        with self.assertRaisesRegex(core.ProjectError, "ignored local files"):
            mcp._call(projects, "worktree_remove", {"project": feature["id"]})
        self.assertTrue(mcp._call(projects, "worktree_remove", {"project": feature["id"], "confirmation": "feature"})["deleted"])
        self.assertFalse(nested.exists())
        self.assertIn("feature", subprocess.run(["git", "-C", str(repo), "branch", "--list", "feature"], capture_output=True, text=True, check=True).stdout)
        self.assertNotIn(feature["id"], [project["id"] for project in core.load_config(path)])

    def test_dashboard_offers_current_token_after_stale_action(self):
        path = self.root / "dashboard.json"
        path.write_text(json.dumps({"version": 1, "projects": [self.project]}))
        port = self.free_port()
        origin = f"http://127.0.0.1:{port}"
        proxy_origin = "http://agentic-devkit.test"
        process = subprocess.Popen(
            [sys.executable, str(Path(core.__file__).resolve().parent.parent / "bin/devkit-projects"),
             "--config", str(path), "ui", "--port", str(port), "--origin", proxy_origin],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        opener = build_opener(ProxyHandler({}))
        try:
            deadline = time.monotonic() + 5
            while True:
                try:
                    with opener.open(origin + "/api/projects", timeout=0.2) as response:
                        current_token = response.headers["X-Devkit-Token"]
                    break
                except OSError:
                    if time.monotonic() >= deadline:
                        self.fail("Dashboard did not start")
                    time.sleep(0.05)

            data = json.dumps({"project": "sample", "action": "stop"}).encode()
            def action(token):
                return Request(origin + "/api/action", data=data, headers={
                    "Content-Type": "application/json", "X-Devkit-Token": token, "Origin": origin,
                })

            with self.assertRaises(HTTPError) as denied:
                opener.open(action("stale"), timeout=2)
            self.assertEqual(denied.exception.code, 403)
            self.assertEqual(denied.exception.headers["X-Devkit-Token"], current_token)
            denied.exception.close()
            with opener.open(action(current_token), timeout=2) as response:
                self.assertEqual(json.load(response)["state"], "stopped")
            with opener.open(Request(origin + "/api/projects", headers={"Host": "agentic-devkit.test"}), timeout=2) as response:
                self.assertEqual(response.headers["X-Devkit-Token"], current_token)
            with opener.open(Request(origin + "/api/action", data=data, headers={
                "Content-Type": "application/json", "X-Devkit-Token": current_token,
                "Host": "agentic-devkit.test", "Origin": proxy_origin,
            }), timeout=2) as response:
                self.assertEqual(json.load(response)["state"], "stopped")
            with self.assertRaises(HTTPError) as wrong_origin:
                opener.open(Request(origin + "/api/action", data=data, headers={
                    "Content-Type": "application/json", "X-Devkit-Token": current_token,
                    "Host": "agentic-devkit.test", "Origin": "http://untrusted.test",
                }), timeout=2)
            self.assertEqual(wrong_origin.exception.code, 403)
            wrong_origin.exception.close()
            with self.assertRaises(HTTPError) as untrusted:
                opener.open(Request(origin + "/api/projects", headers={"Host": "other"}), timeout=2)
            self.assertEqual(untrusted.exception.code, 403)
            self.assertIsNone(untrusted.exception.headers.get("X-Devkit-Token"))
            untrusted.exception.close()
        finally:
            process.terminate()
            process.wait(timeout=5)


unittest.main(verbosity=2)
PY
