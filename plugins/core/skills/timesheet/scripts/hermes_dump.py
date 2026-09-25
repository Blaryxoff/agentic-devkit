#!/usr/bin/env python3
"""Dump one person's messages from a Hermes-style bot state.db (read-only).

Run it where the database lives (inside the bot container), e.g.
  docker cp hermes_dump.py <ctr>:/tmp/ && docker exec <ctr> python3 /tmp/hermes_dump.py /path/to/state.db <telegram-user-id> YYYY-MM-DD > dump.json
  incus file push hermes_dump.py <ct>/tmp/ && incus exec <ct> -- python3 /tmp/hermes_dump.py <db> <user> <since>

Output: {"sources": [[source, user_id, sessions]], "prompts": [[iso_ts, text]]}.
Only role=user rows from sessions whose user_id matches are kept; cron/subagent/webhook sessions are not the person.
"""
import datetime as dt, json, sqlite3, sys

db_path, user, since = sys.argv[1], sys.argv[2], sys.argv[3]
lo = dt.datetime.fromisoformat(since).replace(tzinfo=dt.timezone.utc).timestamp()
db = sqlite3.connect(f'file:{db_path}?mode=ro', uri=True)
sources = db.execute('select source, user_id, count(*) from sessions where user_id = ? and started_at >= ? group by 1, 2', (user, lo)).fetchall()
rows = db.execute("""select m.timestamp, substr(m.content, 1, 800) from messages m join sessions s on s.id = m.session_id
                     where m.role = 'user' and s.user_id = ? and m.timestamp >= ? order by m.timestamp""", (user, lo)).fetchall()
prompts = [[dt.datetime.fromtimestamp(t, dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'), c or ''] for t, c in rows]
json.dump({'sources': sources, 'prompts': prompts}, sys.stdout, ensure_ascii=False)
