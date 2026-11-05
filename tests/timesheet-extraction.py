#!/usr/bin/env python3
"""Exercise timesheet extraction using isolated synthetic agent logs."""

import datetime as dt
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
EXTRACTOR = ROOT / "plugins/core/skills/timesheet/scripts/extract_sessions.py"
UTC = dt.timezone.utc


def iso(value):
    if isinstance(value, str):
        return value
    return value.astimezone(UTC).isoformat(timespec="seconds").replace("+00:00", "Z")


def epoch_seconds(value):
    if isinstance(value, str):
        value = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    return int(value.timestamp())


def epoch_millis(value):
    return epoch_seconds(value) * 1000


def write_jsonl(path, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n" for row in rows))


def codex_meta(sid, cwd, *, source="vscode", thread_source="user", originator="codex-tui",
               branch="main", parent=None):
    return {
        "timestamp": "2026-10-01T09:00:00.000Z",
        "ordinal": 0,
        "type": "session_meta",
        "payload": {
            "session_id": sid,
            "id": sid,
            "cwd": cwd,
            "originator": originator,
            "source": source,
            "thread_source": thread_source,
            "git": {"branch": branch},
            "attached_thread_parent_id": parent,
        },
    }


def codex_message(sid, timestamp, text, *, ordinal=1, role="user", extra=None):
    payload = {
        "type": "message",
        "id": f"{sid}-msg-{ordinal}",
        "role": role,
        "content": [{"type": "input_text", "text": text}],
    }
    if extra:
        payload.update(extra)
    return {
        "timestamp": iso(timestamp),
        "ordinal": ordinal,
        "type": "response_item",
        "payload": payload,
    }


def claude_user(sid, timestamp, text, *, late_timestamp=False, **extra):
    row = {
        "type": "user",
        "isSidechain": False,
        "message": {"role": "user", "content": text},
        "sessionId": sid,
        "cwd": "/fixture/www/grow-place",
    }
    row.update(extra)
    if late_timestamp:
        row["padding"] = "x" * 1200
    row["timestamp"] = iso(timestamp)
    return row


class ExtractorFixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="timesheet-extraction-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.codex_home = self.home / ".codex"
        self.config = self.root / "config.json"
        self.config.write_text(json.dumps({
            "period": {"from": "2026-10-01", "to": "2026-10-31"},
            "tz_offset_hours": 3,
            "transcript_cutoff": "2026-10-05",
            "projects": {},
            "auto_prefixes": [
                "Chat from", "<command-", "<skill>", "<system-reminder>",
                "[CONTEXT COMPACTION", "<send_user_message_question_reply>",
            ],
        }))
        self.out = self.root / "sessions.jsonl"

    def write_history(self, rows):
        write_jsonl(self.codex_home / "history.jsonl", rows)

    def write_state(self, rows):
        path = self.codex_home / "state_5.sqlite"
        path.parent.mkdir(parents=True, exist_ok=True)
        db = sqlite3.connect(path)
        db.execute("""
            CREATE TABLE threads (
                id TEXT PRIMARY KEY,
                rollout_path TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                source TEXT NOT NULL,
                cwd TEXT NOT NULL,
                git_branch TEXT,
                has_user_event INTEGER NOT NULL DEFAULT 0,
                archived INTEGER NOT NULL DEFAULT 0,
                first_user_message TEXT NOT NULL DEFAULT '',
                thread_source TEXT,
                originator TEXT,
                attached_thread_parent_id TEXT
            )
        """)
        db.executemany("""
            INSERT INTO threads
            (id, rollout_path, created_at, updated_at, source, cwd, git_branch,
             has_user_event, archived, first_user_message, thread_source, originator,
             attached_thread_parent_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [(
            row["id"], str(row.get("rollout_path", self.codex_home / "sessions/deleted.jsonl")),
            epoch_seconds(row.get("created_at", "2026-10-06T09:00:00Z")),
            epoch_seconds(row.get("updated_at", "2026-10-23T06:00:00Z")),
            (row.get("source", "vscode") if isinstance(row.get("source", "vscode"), str)
             else json.dumps(row.get("source"), sort_keys=True)),
            row.get("cwd", "/fixture/www/grow-place"),
            row.get("branch", "main"), row.get("has_user_event", 0), row.get("archived", 0),
            row.get("first_user_message", "metadata-only first prompt"),
            row.get("thread_source", "user"), row.get("originator", "codex-tui"),
            row.get("attached_thread_parent_id"),
        ) for row in rows])
        db.commit()
        db.close()
        return path

    def write_thread_history(self, rows):
        path = self.codex_home / "thread_history_1.sqlite"
        path.parent.mkdir(parents=True, exist_ok=True)
        db = sqlite3.connect(path)
        db.execute("""
            CREATE TABLE thread_items (
                thread_id TEXT NOT NULL,
                rollout_ordinal INTEGER NOT NULL,
                created_at_ms INTEGER NOT NULL,
                item_json TEXT NOT NULL,
                item_type TEXT NOT NULL
            )
        """)
        db.execute("""
            CREATE INDEX idx_thread_items_user_messages
            ON thread_items(thread_id, rollout_ordinal)
            WHERE item_type = 'userMessage'
        """)
        db.executemany("""
            INSERT INTO thread_items (thread_id, rollout_ordinal, created_at_ms, item_json, item_type)
            VALUES (?, ?, ?, ?, ?)
        """, [(
            row["session_id"], row.get("ordinal", 0), epoch_millis(row["timestamp"]),
            json.dumps({
                "type": "userMessage",
                "id": row.get("item_id", f"{row['session_id']}-{row.get('ordinal', 0)}"),
                "content": [{"type": "text", "text": row["text"]}],
            }), "userMessage",
        ) for row in rows])
        db.commit()
        db.close()
        return path

    def write_rollout(self, sid, messages, *, cwd="/fixture/www/grow-place", source="vscode",
                      thread_source="user", originator="codex-tui", branch="main", parent=None):
        path = self.codex_home / "sessions/2026/10/15" / f"rollout-{sid}.jsonl"
        rows = [codex_meta(sid, cwd, source=source, thread_source=thread_source,
                           originator=originator, branch=branch, parent=parent)]
        rows.extend(messages)
        write_jsonl(path, rows)
        return path

    def run_extractor(self):
        proc = subprocess.run(
            [sys.executable, str(EXTRACTOR), "--config", str(self.config), "--out", str(self.out),
             "--home", str(self.home), "--codex-home", str(self.codex_home)],
            cwd=ROOT,
            env=dict(os.environ),
            capture_output=True,
            text=True,
            timeout=20,
        )
        self.assertEqual(proc.returncode, 0, f"extractor failed:\n{proc.stderr}\n{proc.stdout}")
        sessions = [json.loads(line) for line in self.out.read_text().splitlines() if line.strip()]
        for session in sessions:
            self.assertTrue({"tool", "id", "cwd", "entry", "branches", "prompts", "bhits"} <= session.keys())
        return sessions

    def prompts_for(self, sessions, sid):
        found = [s for s in sessions if s["id"] == sid]
        self.assertEqual(len(found), 1, f"expected one canonical session {sid}, got {len(found)}")
        return found[0]["prompts"]

    def test_deleted_rollout_recovers_history_without_using_metadata_timestamps(self):
        sid = "deleted-human"
        history_time = "2026-10-06T10:03:00Z"
        self.write_state([{
            "id": sid,
            "cwd": "/fixture/www/grow-place",
            "branch": "feature/recovery",
            "created_at": "2026-10-06T09:00:00Z",
            "updated_at": "2026-10-23T06:00:00Z",
            "has_user_event": 0,
            "first_user_message": "metadata-only first prompt",
        }])
        self.write_history([{"session_id": sid, "ts": epoch_seconds(history_time), "text": "human prompt from history"}])

        sessions = self.run_extractor()
        found = [session for session in sessions if session["id"] == sid]
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0]["prompts"], [[history_time, "human prompt from history"]])
        self.assertEqual(found[0]["cwd"], "/fixture/www/grow-place")
        self.assertEqual(found[0]["branches"], ["feature/recovery"])

    def test_thread_history_supplements_history_and_is_read_only(self):
        sid = "cache-supplement"
        self.write_state([{"id": sid}])
        self.write_history([{"session_id": sid, "ts": epoch_seconds("2026-10-08T08:00:00Z"), "text": "history event"}])
        cache = self.write_thread_history([
            {"session_id": sid, "timestamp": "2026-10-08T08:00:30Z", "text": "same event already in history", "ordinal": 1},
            {"session_id": sid, "timestamp": "2026-10-08T08:05:00Z", "text": "cache-only event", "ordinal": 2},
            {"session_id": sid, "timestamp": "2026-09-30T20:59:59Z", "text": "outside period", "ordinal": 3},
            {"session_id": "decoy-id", "timestamp": "2026-10-08T08:06:00Z", "text": "different thread", "ordinal": 4},
        ])
        before = (cache.read_bytes(), cache.stat().st_mtime_ns)
        sessions = self.run_extractor()
        after = (cache.read_bytes(), cache.stat().st_mtime_ns)
        self.assertEqual(after, before)
        self.assertFalse(Path(str(cache) + "-wal").exists())
        self.assertFalse(Path(str(cache) + "-shm").exists())
        prompts = self.prompts_for(sessions, sid)
        self.assertEqual([item[1] for item in prompts], ["history event", "same event already in history", "cache-only event"])

    def test_cross_source_dedup_preserves_later_repeats_and_distinct_tails(self):
        sid = "canonical-dedup"
        common = "p" * 200
        first = "same event across sources"
        messages = [
            codex_message(sid, "2026-10-09T10:00:00Z", first),
            codex_message(sid, "2026-10-09T10:02:00Z", "continue", ordinal=2),
            codex_message(sid, "2026-10-09T10:04:00Z", "continue", ordinal=3),
            codex_message(sid, "2026-10-09T10:06:00Z", common + " tail A", ordinal=4),
            codex_message(sid, "2026-10-09T10:07:00Z", common + " tail B", ordinal=5),
        ]
        path = self.write_rollout(sid, messages)
        self.write_state([{"id": sid, "rollout_path": path}])
        self.write_history([
            {"session_id": sid, "ts": epoch_seconds("2026-10-09T10:00:30Z"), "text": first},
        ])
        self.write_thread_history([
            {"session_id": sid, "timestamp": "2026-10-09T10:00:40Z", "text": first, "ordinal": 1},
        ])

        prompts = self.prompts_for(self.run_extractor(), sid)
        texts = [item[1] for item in prompts]
        self.assertEqual(texts.count(first), 1)
        self.assertEqual(texts.count("continue"), 2)
        self.assertIn(common + " tail A", texts)
        self.assertIn(common + " tail B", texts)
        self.assertEqual(len(texts), 5)

    def test_cross_source_rendering_aliases_dedup_one_to_one(self):
        wrapup = "wrapup-alias"
        image = "image-alias"
        wrapup_times = [
            "2026-10-15T10:00:00Z",
            "2026-10-15T10:00:20Z",
        ]
        image_time = "2026-10-15T10:05:00Z"
        wrapup_link = "[$wrapup](/tmp/SKILL.md) next"
        image_rendered = "<image name=fixture> </image> [Image #1] review this"

        self.write_state([{"id": wrapup}, {"id": image}])
        self.write_history([
            {"session_id": wrapup, "ts": epoch_seconds(wrapup_times[0]), "text": "$wrapup next"},
            {"session_id": wrapup, "ts": epoch_seconds(wrapup_times[1]), "text": "$wrapup next"},
            {"session_id": image, "ts": epoch_seconds(image_time), "text": "review this"},
        ])
        self.write_rollout(wrapup, [
            codex_message(wrapup, "2026-10-15T10:00:02Z", wrapup_link),
            codex_message(wrapup, "2026-10-15T10:00:22Z", wrapup_link, ordinal=2),
        ])
        self.write_rollout(image, [
            codex_message(image, "2026-10-15T10:05:02Z", image_rendered),
        ])
        self.write_thread_history([
            {"session_id": wrapup, "timestamp": "2026-10-15T10:00:03Z", "text": wrapup_link, "ordinal": 1},
            {"session_id": wrapup, "timestamp": "2026-10-15T10:00:23Z", "text": wrapup_link, "ordinal": 2},
            {"session_id": image, "timestamp": "2026-10-15T10:05:03Z", "text": image_rendered, "ordinal": 1},
        ])

        sessions = self.run_extractor()
        wrapup_prompts = self.prompts_for(sessions, wrapup)
        image_prompts = self.prompts_for(sessions, image)
        self.assertEqual([text for _, text in wrapup_prompts], ["$wrapup next", "$wrapup next"])
        self.assertEqual(len(image_prompts), 1)
        self.assertEqual(image_prompts[0][1], "review this")

    def test_subagents_exec_guardian_and_agent_created_threads_are_not_human(self):
        specs = [
            ("subagent", {"source": {"subagent": {"thread_spawn": {"parent_thread_id": "parent"}}},
                          "thread_source": "subagent", "originator": "codex-tui", "attached_thread_parent_id": "parent"}),
            ("exec", {"source": "exec", "thread_source": "user", "originator": "codex_exec"}),
            ("guardian", {"source": {"subagent": {"other": "guardian"}},
                           "thread_source": "guardian_review", "originator": "Codex Desktop"}),
            ("agent-created", {"source": "vscode", "thread_source": "agent_created_thread",
                                "originator": "Codex Desktop"}),
        ]
        state = []
        history = []
        cache = []
        for sid, meta in specs:
            self.write_rollout(sid, [codex_message(sid, "2026-10-10T10:00:00Z", f"looks human {sid}")],
                               source=meta["source"], thread_source=meta["thread_source"],
                               originator=meta["originator"], parent=meta.get("attached_thread_parent_id"))
            state.append({"id": sid, **meta})
            history.append({"session_id": sid, "ts": epoch_seconds("2026-10-10T10:01:00Z"), "text": f"history {sid}"})
            cache.append({"session_id": sid, "timestamp": "2026-10-10T10:02:00Z", "text": f"cache {sid}"})
        self.write_state(state)
        self.write_history(history)
        self.write_thread_history(cache)

        sessions = self.run_extractor()
        emitted_text = {text for session in sessions for _, text in session["prompts"]}
        self.assertFalse(emitted_text.intersection({f"looks human {sid}" for sid, _ in specs}))
        self.assertFalse(emitted_text.intersection({f"history {sid}" for sid, _ in specs}))
        self.assertFalse(emitted_text.intersection({f"cache {sid}" for sid, _ in specs}))

    def test_machine_events_are_filtered_but_structured_question_reply_survives(self):
        sid = "machine-filtering"
        structured = '<send_user_message_question_reply>{"answers":[{"question_id":"q1","answer":"yes"}]}</send_user_message_question_reply>'
        messages = [
            {"timestamp": "2026-10-11T09:00:00Z", "type": "event_msg", "payload": {"type": "auto_retry", "text": "retry content"}},
            codex_message(sid, "2026-10-11T09:01:00Z", "generated summary flagged as human", ordinal=2,
                          extra={"isCompactSummary": True}),
            codex_message(sid, "2026-10-11T09:02:00Z", "<skill> injected instructions", ordinal=3),
            codex_message(sid, "2026-10-11T09:03:00Z", "system text", ordinal=4, role="developer"),
            codex_message(sid, "2026-10-11T09:04:00Z", structured, ordinal=5),
        ]
        self.write_rollout(sid, messages)
        self.write_state([{"id": sid}])
        self.write_history([{"session_id": sid, "ts": epoch_seconds("2026-10-11T09:05:00Z"), "text": "Chat from peer: machine relay"}])

        texts = [item[1] for item in self.prompts_for(self.run_extractor(), sid)]
        self.assertEqual(texts, ["yes"])

    def test_claude_history_merges_partial_transcript_and_legacy_human_prompt(self):
        sid = "claude-partial"
        project = "/fixture/www/grow-place"
        transcript_path = self.home / ".claude/projects/fixture" / f"{sid}.jsonl"
        transcript_path.parent.mkdir(parents=True)
        history_rows = [
            {"sessionId": sid, "timestamp": int(dt.datetime.fromisoformat("2026-10-12T09:00:00+00:00").timestamp() * 1000),
             "display": "earlier prompt", "project": project},
            {"sessionId": sid, "timestamp": int(dt.datetime.fromisoformat("2026-10-12T10:00:01+00:00").timestamp() * 1000),
             "display": "late transcript prompt", "project": project},
        ]
        self.write_history([])
        claude_history = self.home / ".claude/history.jsonl"
        write_jsonl(claude_history, history_rows)
        late = claude_user(sid, "2026-10-12T10:00:00Z", "late transcript prompt", late_timestamp=True)
        transcript_path.write_text(json.dumps(late) + "\n")

        sessions = self.run_extractor()
        found = [s for s in sessions if s["tool"] == "claude" and s["id"] == sid]
        self.assertEqual(len(found), 1)
        texts = [item[1] for item in found[0]["prompts"]]
        self.assertEqual(texts.count("earlier prompt"), 1)
        self.assertEqual(texts.count("late transcript prompt"), 1)
        self.assertEqual(len(texts), 2)

    def test_local_period_edges_use_utc_plus_three(self):
        sid = "timezone-boundary"
        start = "2026-09-30T21:00:00Z"
        before = "2026-09-30T20:59:59Z"
        end = "2026-10-31T21:00:00Z"
        self.write_state([{"id": sid}])
        self.write_history([
            {"session_id": sid, "ts": epoch_seconds(before), "text": "before local start"},
            {"session_id": sid, "ts": epoch_seconds(start), "text": "at local start"},
            {"session_id": sid, "ts": epoch_seconds(end), "text": "at local end"},
        ])

        sessions = self.run_extractor()
        prompts = self.prompts_for(sessions, sid)
        self.assertEqual([item[1] for item in prompts], ["at local start"])
        self.assertEqual(prompts[0][0], start)

    def test_coverage_sidecar_is_aggregate_and_contains_diagnostics(self):
        sid = "coverage"
        self.write_state([{"id": sid}])
        self.write_history([{"session_id": sid, "ts": epoch_seconds("2026-10-13T08:00:00Z"), "text": "private synthetic prompt"}])
        self.run_extractor()

        coverage_path = Path(str(self.out) + ".coverage.json")
        self.assertTrue(coverage_path.is_file())
        report = json.loads(coverage_path.read_text())
        self.assertIsInstance(report, dict)
        self.assertTrue(report, "coverage sidecar must contain aggregate diagnostics")
        self.assertTrue(any(isinstance(v, (int, float)) for v in report.values()), "expected aggregate numeric counters")
        self.assertNotIn("private synthetic prompt", coverage_path.read_text())


if __name__ == "__main__":
    unittest.main(verbosity=2)
