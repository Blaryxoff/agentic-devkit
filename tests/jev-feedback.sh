#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$ROOT" PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'
import importlib.util
import json
import os
import tempfile
from pathlib import Path
from unittest.mock import patch

root = Path(os.environ["ROOT"])
spec = importlib.util.spec_from_file_location("feedback", root / "plugins/core/hooks/jev-feedback.py")
feedback = importlib.util.module_from_spec(spec)
spec.loader.exec_module(feedback)

with tempfile.TemporaryDirectory() as temporary:
    feedback.STATE = Path(temporary) / "feedback"
    feedback.TICKETS = feedback.STATE / "tickets"
    feedback.BACKLOG = Path(temporary) / "devkit/docs/backlog"
    session = "session-test"
    prompt = "You keep ignoring my preference. Fix the skill. api_key=very-secret"
    payload = {"session_id": session, "prompt": prompt, "cwd": "/tmp/project", "transcript_path": "/tmp/session.jsonl"}
    seen = []

    def positive(text):
        seen.append(text)
        return 0.87, 0.66, "skill", 0.91

    with patch.object(feedback, "classify", side_effect=positive):
        feedback.handle_prompt(payload)
        feedback.handle_prompt(payload)
    paths = list(feedback.TICKETS.glob("*/*.json"))
    assert len(paths) == 1
    path = paths[0]
    ticket = json.loads(path.read_text())
    assert "very-secret" not in seen[0]
    assert "very-secret" not in path.read_text()
    assert ticket["status"] == "untriaged"
    assert ticket["feedback_probability"] == 0.87
    assert ticket["reusable_probability"] == 0.66
    assert ticket["candidate_location"].startswith("plugins/core/skills/")
    assert ticket["transcript_path"] == "/tmp/session.jsonl"
    assert path.stat().st_mode & 0o777 == 0o600
    items = list(feedback.BACKLOG.glob("*.md"))
    assert len(items) == 1
    assert items[0].name == f"agent-feedback-skill-{ticket['id']}.md"
    item = items[0].read_text()
    assert "worth: later" in item
    assert "feedback 0.87, reusable 0.66" in item
    assert "Candidate location: `plugins/core/skills/" in item
    assert str(path) in item
    assert prompt not in item

    items[0].unlink()
    feedback.handle_prompt(payload)
    assert len(list(feedback.BACKLOG.glob("*.md"))) == 1

    with patch.object(feedback, "classify", return_value=(0.45, 0.8, "other", 0.9)) as classify_mock:
        feedback.handle_prompt({"session_id": session, "prompt": "Fix the app's login button"})
        feedback.handle_prompt({"session_id": session, "prompt": "Fix the app's login button"})
    assert classify_mock.call_count == 1
    assert len(list(feedback.BACKLOG.glob("*.md"))) == 1

    with patch.dict(os.environ, {"DEVKIT_FEEDBACK_WORKER": "1"}):
        feedback.handle_prompt({"session_id": session, "prompt": "Why did you ignore my instruction?"})
    assert len(list(feedback.BACKLOG.glob("*.md"))) == 1

    with patch.object(feedback, "classify", return_value=(0.75, 0.55, "other", 0.3)):
        feedback.handle_prompt({"session_id": session, "prompt": "Why didn't you check the source?"})
    assert len(list(feedback.BACKLOG.glob("*.md"))) == 2
    assert not hasattr(feedback, "handle_work")

    cursor_prompt = "Why did you ignore the Cursor rule again?"
    cursor_payload = {
        "hook_event_name": "beforeSubmitPrompt",
        "conversation_id": "cursor-conversation",
        "prompt": cursor_prompt,
        "workspace_roots": ["/tmp/cursor-project"],
        "transcript_path": "/tmp/cursor-transcript.jsonl",
    }
    with patch.object(feedback, "classify", return_value=(0.8, 0.7, "guidance", 0.6)) as classify_mock:
        feedback.handle_prompt(cursor_payload)
        feedback.handle_prompt({
            **cursor_payload,
            "session_id": "claude-compat-session",
        })
    assert classify_mock.call_count == 1
    cursor_tickets = [
        json.loads(path.read_text())
        for path in feedback.TICKETS.glob("*/*.json")
        if json.loads(path.read_text())["session_id"] == "cursor-conversation"
    ]
    assert len(cursor_tickets) == 1
    cursor_ticket = cursor_tickets[0]
    assert cursor_ticket["source_cwd"] == "/tmp/cursor-project"
    assert cursor_ticket["transcript_path"] == "/tmp/cursor-transcript.jsonl"
    assert cursor_ticket["repair_area"] == "guidance"
    assert len(list(feedback.BACKLOG.glob("agent-feedback-guidance-*.md"))) == 1

    normalized = feedback.normalize_prompt_payload({
        "conversation_id": "cid",
        "session_id": "sid",
        "workspace_roots": ["", "/tmp/root"],
        "transcriptPath": "/tmp/t.jsonl",
        "prompt": "x",
    })
    assert normalized["session_id"] == "cid"
    assert normalized["cwd"] == "/tmp/root"
    assert normalized["transcript_path"] == "/tmp/t.jsonl"

    class FakeJev:
        def __init__(self):
            self.calls = []

        def run(self, payload):
            self.calls.append(payload)
            if len(self.calls) == 1:
                return {"feedback": {"noul": 0.2}}, 0, 0
            if len(self.calls) == 2:
                return {"feedback": {"noul": 0.8}}, 0, 0
            return {"reusable": {"noul": 0.6}, "repair_area": {"choice": "other", "confidence": 0.4}}, 0, 0

    fake = FakeJev()
    with patch.object(feedback, "jev_module", return_value=fake):
        assert feedback.classify("ordinary request") == (0.2, 0.0, "other", 0.0)
        assert len(fake.calls) == 1
        assert feedback.classify("agent correction") == (0.8, 0.6, "other", 0.4)
        assert len(fake.calls) == 3

print("jev-feedback tests passed")
PY

response=$(printf '%s\n' '{"hook_event_name":"beforeSubmitPrompt","conversation_id":"probe","prompt":"probe"}' \
  | DEVKIT_FEEDBACK_WORKER=1 python3 "$ROOT/plugins/core/hooks/jev-feedback.py" prompt)
[ "$response" = '{"continue": true}' ] || { echo "Cursor prompt hook did not allow submission" >&2; exit 1; }
