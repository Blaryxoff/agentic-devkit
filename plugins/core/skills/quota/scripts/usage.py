#!/usr/bin/env python3
"""Estimate human Codex activity time from local rollout timestamps."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import statistics
import sys
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


SENSITIVITIES = ((20, 10), (30, 15), (45, 20))
AUTO_MARKERS = (
    "# AGENTS.md", "<environment_context", "<user_instructions", "<recommended_plugins>",
    "Chat from ", ">>REQ", "<<RPY", "<turn_aborted", "<task-notification", "<system-reminder",
    "<command-", "[Artifact comment", "Caveat:", "<skill>", "<available_skills>",
)
IMAGE_WRAPPER = re.compile(r"^\s*(?:\[image(?:\s+\d+)?\]|image attachment:?|attached image:?|<image(?:\s[^>]*)?>|</image>)\s*$", re.I)
EVENT_TYPE = re.compile(r'"type"\s*:\s*"(?:event_msg|response_item)"')
USER_RECORD = re.compile(r'"type"\s*:\s*"user_message"|"role"\s*:\s*"user"')
TIMESTAMP = re.compile(r'"timestamp"\s*:\s*"([^"\\]+)"')
HUMAN_ORIGINATORS = {"codex-tui", "Codex Desktop"}
HUMAN_SOURCES = {"vscode", "tui", "desktop", "codex-tui", "Codex Desktop"}


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--codex-home", type=Path, default=Path(os.environ.get("CODEX_HOME", "~/.codex")).expanduser())
    p.add_argument("--as-of", required=True, help="Aware ISO timestamp, including UTC offset")
    p.add_argument("--days", type=int, default=14)
    p.add_argument("--timezone", required=True, help="IANA timezone")
    p.add_argument("--out", type=Path, help="Write JSON here instead of stdout")
    a = p.parse_args()
    if a.days < 1:
        p.error("--days must be positive")
    try:
        a.zone = ZoneInfo(a.timezone)
        a.as_of = dt.datetime.fromisoformat(a.as_of.replace("Z", "+00:00"))
        if a.as_of.tzinfo is None or a.as_of.utcoffset() is None:
            raise ValueError
    except (ZoneInfoNotFoundError, ValueError):
        p.error("--as-of must be timezone-aware and --timezone must be a valid IANA timezone")
    a.as_of = a.as_of.astimezone(a.zone)
    a.codex_home = a.codex_home.expanduser().resolve()
    a.first_day = a.as_of.date() - dt.timedelta(days=a.days - 1)
    a.start = dt.datetime.combine(a.first_day, dt.time.min, a.zone).astimezone(dt.timezone.utc)
    a.end = a.as_of.astimezone(dt.timezone.utc)
    return a


def iso_time(value):
    if not isinstance(value, str):
        return None
    try:
        d = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
        return d.astimezone(dt.timezone.utc) if d.tzinfo else None
    except ValueError:
        return None


def source_files(home, args, warnings, coverage):
    files = set()
    dbs = list(home.glob("state_*.sqlite")) if home.exists() else []
    db_ok = False
    for db in dbs:
        try:
            con = sqlite3.connect(db.resolve().as_uri() + "?mode=ro", uri=True, timeout=1)
            columns = {row[1] for row in con.execute("PRAGMA table_info(threads)")}
            if "rollout_path" not in columns or not {"updated_at", "updated_at_ms"} & columns:
                con.close()
                continue
            if {"updated_at_ms", "updated_at"} <= columns:
                rows = con.execute("SELECT rollout_path FROM threads WHERE updated_at_ms >= ? OR updated_at >= ?",
                                   (int(args.start.timestamp() * 1000), int(args.start.timestamp())))
            elif "updated_at_ms" in columns:
                rows = con.execute("SELECT rollout_path FROM threads WHERE updated_at_ms >= ?", (int(args.start.timestamp() * 1000),))
            else:
                rows = con.execute("SELECT rollout_path FROM threads WHERE updated_at >= ?", (int(args.start.timestamp()),))
            db_ok = True
            for (raw,) in rows:
                if not isinstance(raw, str) or not raw:
                    coverage["missing_rollout_paths"] += 1
                    continue
                path = Path(raw).expanduser()
                try:
                    resolved = path.resolve()
                    roots = ((home / "sessions").resolve(), (home / "archived_sessions").resolve())
                except OSError:
                    coverage["missing_rollout_paths"] += 1
                    continue
                if not any(resolved == root or root in resolved.parents for root in roots):
                    coverage["out_of_scope_rollout_paths"] += 1
                    continue
                if path.is_file():
                    files.add(path)
                else:
                    coverage["missing_rollout_paths"] += 1
            con.close()
            coverage["sqlite_databases"] += 1
        except (sqlite3.Error, OSError) as e:
            warnings.append(f"state database unavailable: {type(e).__name__}")
    coverage["fallback_date_scan"] = not db_ok
    coverage["date_scan_supplements_index"] = db_ok
    d = args.start.date() - dt.timedelta(days=1)
    last = args.end.date()
    while d <= last:
        for folder in (home / "sessions", home / "archived_sessions"):
            dated = folder / f"{d:%Y}" / f"{d:%m}" / f"{d:%d}"
            files.update(dated.glob("rollout-*.jsonl"))
        d += dt.timedelta(days=1)
    if not db_ok:
        warnings.append("SQLite unavailable; date-folder fallback can miss sessions started before the prior UTC day")
    coverage["candidate_rollouts"] = len(files)
    return sorted(files)


def text_content(value):
    if isinstance(value, str):
        return value
    if not isinstance(value, list):
        return ""
    return " ".join(x.get("text", "") for x in value if isinstance(x, dict) and x.get("type") in ("text", "input_text"))


def reject_text(text):
    lines = [line for line in text.splitlines() if not IMAGE_WRAPPER.match(line)]
    stripped = "\n".join(lines).lstrip()
    return not stripped or any(stripped.startswith(marker) for marker in AUTO_MARKERS)


def nested_subagent(value):
    if isinstance(value, dict):
        if "parent_thread_id" in value and value["parent_thread_id"] is not None:
            return True
        if "subagent" in value and value["subagent"] not in (None, False, "", {}, []):
            return True
        return any(nested_subagent(v) for v in value.values())
    if isinstance(value, list):
        return any(nested_subagent(v) for v in value)
    return False


def collect(files, args, warnings, coverage):
    sessions = []
    seen = set()
    for path in files:
        coverage["rollouts_read"] += 1
        meta = None
        local = []
        try:
            with path.open(errors="replace") as f:
                first = f.readline()
                try:
                    header = json.loads(first)
                except (ValueError, TypeError):
                    coverage["malformed_lines"] += 1
                    continue
                if not isinstance(header, dict) or header.get("type") != "session_meta" or not isinstance(header.get("payload"), dict):
                    coverage["unknown_source_rollouts"] += 1
                    continue
                meta = header["payload"]
                source = meta.get("source")
                originator = meta.get("originator")
                if (originator == "codex_exec" or meta.get("thread_source") == "subagent"
                        or (isinstance(source, str) and source in {"subagent", "exec", "scheduled", "automation", "cron", "sdk"})
                        or nested_subagent(meta)):
                    coverage["excluded_agent_rollouts"] += 1
                    continue
                if not ((source is None and isinstance(originator, str) and originator in HUMAN_ORIGINATORS)
                        or (isinstance(source, str) and source in HUMAN_SOURCES)):
                    coverage["unknown_source_rollouts"] += 1
                    continue
                for line in f:
                    head = line[:600]
                    if not EVENT_TYPE.search(head) or not USER_RECORD.search(head):
                        continue
                    match = TIMESTAMP.search(head)
                    stamp = iso_time(match.group(1)) if match else None
                    if stamp is None:
                        coverage["missing_timestamps"] += 1
                        continue
                    if not args.start <= stamp <= args.end:
                        continue
                    try:
                        event = json.loads(line)
                    except (ValueError, TypeError):
                        coverage["malformed_lines"] += 1
                        continue
                    if not isinstance(event, dict):
                        continue
                    payload = event.get("payload")
                    if not isinstance(payload, dict):
                        continue
                    kind = payload.get("type")
                    if event.get("type") == "event_msg" and kind == "user_message":
                        raw = payload.get("message")
                    elif event.get("type") == "response_item" and kind == "message" and payload.get("role") == "user":
                        raw = text_content(payload.get("content"))
                    else:
                        continue
                    if not isinstance(raw, str) or reject_text(raw):
                        coverage["filtered_prompts"] += 1
                        continue
                    digest = hashlib.sha256(raw.encode("utf-8", "replace")).digest()
                    local.append((stamp, digest))
        except OSError as e:
            warnings.append(f"rollout unreadable: {type(e).__name__}")
            coverage["unreadable_rollouts"] += 1
            continue
        coverage["accepted_human_rollouts"] += 1
        accepted = []
        for stamp, digest in local:
            key = (stamp, digest)
            if key in seen:
                coverage["duplicate_prompts"] += 1
                continue
            seen.add(key)
            accepted.append(stamp)
        if accepted:
            sessions.append(sorted(set(accepted)))
    return sessions


def union_seconds(intervals):
    total = 0
    end = None
    for start, stop in sorted(intervals):
        if end is None or start > end:
            total += (stop - start).total_seconds()
        elif stop > end:
            total += (stop - end).total_seconds()
        end = max(end, stop) if end else stop
    return total


def model(sessions, args, gap_minutes, tail_minutes):
    intervals = []
    for day_prompts in sessions:
        for i, stamp in enumerate(day_prompts):
            following = day_prompts[i + 1] if i + 1 < len(day_prompts) else None
            gap = (following - stamp).total_seconds() if following else None
            stop = following if gap is not None and gap <= gap_minutes * 60 else stamp + dt.timedelta(minutes=tail_minutes)
            intervals.append((stamp, min(stop, args.end)))
    daily = {}
    for day in (args.first_day + dt.timedelta(days=i) for i in range(args.days)):
        lo = dt.datetime.combine(day, dt.time.min, args.zone).astimezone(dt.timezone.utc)
        hi = min(dt.datetime.combine(day + dt.timedelta(days=1), dt.time.min, args.zone).astimezone(dt.timezone.utc), args.end)
        clipped = [(max(s, lo), min(e, hi)) for s, e in intervals if s < hi and e > lo]
        seconds = union_seconds(clipped)
        daily[day.isoformat()] = round(seconds / 3600, 2)
    return daily


def main():
    args = parse_args()
    warnings, coverage = [], {"sqlite_databases": 0, "candidate_rollouts": 0, "rollouts_read": 0,
                             "accepted_human_rollouts": 0, "excluded_agent_rollouts": 0,
                             "unknown_source_rollouts": 0, "filtered_prompts": 0,
                             "duplicate_prompts": 0, "malformed_lines": 0, "missing_timestamps": 0,
                             "unreadable_rollouts": 0, "missing_rollout_paths": 0,
                             "out_of_scope_rollout_paths": 0, "fallback_date_scan": False}
    files = source_files(args.codex_home, args, warnings, coverage)
    sessions = collect(files, args, warnings, coverage)
    prompts = sorted({p for session in sessions for p in session})
    if coverage["missing_rollout_paths"] or coverage["out_of_scope_rollout_paths"]:
        warnings.append("Some indexed rollouts are missing or outside the supplied Codex home; coverage is partial")
    if coverage["unknown_source_rollouts"]:
        warnings.append("Unknown-origin rollouts were excluded; review source coverage before interpreting idle days")
    if not prompts:
        warnings.append("No eligible human prompts found; missing evidence does not establish inactivity")
    by_day = {}
    for p in prompts:
        by_day.setdefault(p.astimezone(args.zone).date().isoformat(), []).append(p)
    estimates = {f"gap_{gap}_tail_{tail}_hours": model(sessions, args, gap, tail) for gap, tail in SENSITIVITIES}
    complete = [(args.first_day + dt.timedelta(days=i)).isoformat()
                for i in range(args.days) if args.first_day + dt.timedelta(days=i) < args.as_of.date()]
    medians = {}
    for key, days in estimates.items():
        values = sorted(days[d] for d in complete)
        if values:
            medians[key] = round(statistics.median(values), 2)
    active_complete = [d for d in complete if d in by_day]
    def median_clock(which):
        bounds = [by_day[d][0 if which == "first" else -1].astimezone(args.zone) for d in active_complete]
        seconds = [bound.hour * 3600 + bound.minute * 60 + bound.second for bound in bounds]
        if not seconds:
            return None
        return (dt.datetime.min + dt.timedelta(seconds=statistics.median(seconds))).strftime("%H:%M:%S")
    complete_hours = {}
    for key, days in estimates.items():
        complete_hours[key] = {
            "weekday": round(sum(hours for day, hours in days.items()
                                 if day in complete and dt.date.fromisoformat(day).weekday() < 5), 2),
            "weekend": round(sum(hours for day, hours in days.items()
                                 if day in complete and dt.date.fromisoformat(day).weekday() >= 5), 2),
        }
    weekdays = sum(1 for d in by_day if dt.date.fromisoformat(d).weekday() < 5)
    result = {"period": {"from": args.first_day.isoformat(), "as_of": args.as_of.isoformat(), "timezone": args.timezone},
              "daily_prompts": {d: len(v) for d, v in sorted(by_day.items())},
              "daily_estimated_hours": estimates,
              "daily_prompt_bounds": {d: {"first": v[0].astimezone(args.zone).isoformat(),
                                            "last": v[-1].astimezone(args.zone).isoformat()}
                                      for d, v in sorted(by_day.items())},
              "first_prompt": prompts[0].astimezone(args.zone).isoformat() if prompts else None,
              "last_prompt": prompts[-1].astimezone(args.zone).isoformat() if prompts else None,
              "prompt_count": len(prompts), "weekday_days_with_prompts": weekdays,
              "weekend_days_with_prompts": len(by_day) - weekdays,
              "median_complete_day_hours": medians,
              "median_complete_active_day_prompt_clock": {"first": median_clock("first"), "last": median_clock("last")},
              "complete_day_hours_by_weekday_weekend": complete_hours,
              "coverage": coverage, "warnings": warnings}
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(rendered)
    else:
        sys.stdout.write(rendered)


if __name__ == "__main__":
    main()
