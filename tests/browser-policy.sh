#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
helper = root / "bin/devkit-browser-policy"
module = runpy.run_path(str(helper))

def command(repo, *args):
    return subprocess.check_output(["git", "-C", str(repo), *args], stderr=subprocess.PIPE).decode().strip()

def commit(repo):
    command(repo, "add", "--all")
    command(repo, "-c", "user.name=Policy Test", "-c", "user.email=qa@example.invalid",
            "commit", "--quiet", "-m", "policy fixture")
    return command(repo, "rev-parse", "HEAD")

with tempfile.TemporaryDirectory() as directory:
    repo = Path(directory) / "devkit"
    repo.mkdir()
    command(repo, "init", "--quiet")
    for name, sections in module["SOURCES"].items():
        path = repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        content = "\n\n".join(f"## {section}. Test\nCanonical version one {section}" for section in sections) if sections else "Canonical version one\n"
        path.write_text(content)
    first = commit(repo)
    output = Path(directory) / "run"
    output.mkdir()
    args = [sys.executable, str(helper), "--root", str(repo), "--output-dir", str(output)]
    result = subprocess.run(args, capture_output=True, text=True, check=True)
    policy = (output / "qa-policy.md").read_text()
    manifest = json.loads((output / "qa-policy.json").read_text())
    assert result.stdout == policy
    assert manifest["revision"] == first
    assert manifest["policy_sha256"] == hashlib.sha256(policy.encode()).hexdigest()
    for name, digest in manifest["sources"].items():
        assert digest == hashlib.sha256((repo / name).read_bytes()).hexdigest()
    assert all(path.stat().st_mode & 0o777 == 0o600 for path in output.iterdir())

    changed = repo / "plugins/core/conduct/runtime-qa-evidence.md"
    changed.write_text("Uncommitted policy must not leak\n")
    assert module["snapshot"](repo)[0] == policy
    second = commit(repo)
    latest, current = module["snapshot"](repo)
    assert current["revision"] == second != first
    assert "Uncommitted policy must not leak" in latest
    assert (output / "qa-policy.md").read_text() == policy
    retry = subprocess.run(args, capture_output=True, text=True)
    assert retry.returncode != 0 and retry.stdout == ""
    assert (output / "qa-policy.md").read_text() == policy

    missing = repo / "plugins/core/conduct/browser-qa-rules.md"
    missing.write_text("## 7. Test\nRequired section six missing\n## 9. Test\nSafety\n")
    commit(repo)
    fresh = Path(directory) / "blocked"
    fresh.mkdir()
    blocked = subprocess.run(args[:-1] + [str(fresh)], capture_output=True, text=True)
    assert blocked.returncode != 0 and blocked.stdout == ""
    assert "Missing canonical browser sections: 5, 6" in blocked.stderr
    assert not list(fresh.iterdir())
    missing.unlink()
    commit(repo)
    absent = subprocess.run(args[:-1] + [str(fresh)], capture_output=True, text=True)
    assert absent.returncode != 0 and absent.stdout == ""
    assert not list(fresh.iterdir())

print("browser policy tests passed")
PY
