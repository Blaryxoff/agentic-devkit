#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHONPATH="$ROOT" python3 - <<'PY'
import json
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

from project_manager import core


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
