#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PYTHONDONTWRITEBYTECODE=1 python3 - "$ROOT/plugins/core/skills/pair/scripts/peer-chat.py" <<'PY'
import importlib.util
import contextlib
import io
import json
import os
import sys
import tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location("peer_chat", sys.argv[1])
chat = importlib.util.module_from_spec(spec)
sys.modules["peer_chat"] = chat
spec.loader.exec_module(chat)
claude, codex = chat.PROFILES["claude"], chat.PROFILES["codex"]
original_clear_composer = chat.clear_composer

room = chat.CLAUDE_MAX_MESSAGE_UNITS - len(claude.label)
assert chat.normalize(claude, "x" * room).endswith("x")
try:
    chat.normalize(claude, "x" * (room + 1))
except ValueError as err:
    assert "nothing was typed" in str(err), err
else:
    raise AssertionError("a message past Claude's truncation limit was accepted")
try:
    chat.normalize(claude, "\U0001F600" * (room // 2 + 1))
except ValueError:
    pass
else:
    raise AssertionError("the Claude limit must count UTF-16 units, as the composer does")
assert chat.normalize(codex, "x" * (room + 1))

calls = []
def flaky_clear(*_args):
    calls.append(1)
    if len(calls) < 3:
        raise RuntimeError("agterm.sock: Connection refused")
    return True
chat.clear_composer = flaky_clear
chat.time.sleep = lambda _seconds: None
dirty = chat.ComposerDirty("message chunk 7/13 failed", "owned")
try:
    chat.raise_after_composer_dirty("sid", codex, ("", 2), dirty)
except chat.ComposerDirty as err:
    assert str(err).endswith("composer cleared"), err
assert len(calls) == 3, calls

calls.clear()
def unrecognisable(*_args):
    calls.append(1)
    return False
chat.clear_composer = unrecognisable
try:
    chat.raise_after_composer_dirty("sid", codex, ("", 2), dirty)
except chat.ComposerDirty as err:
    assert str(err).endswith("composer cleanup failed"), err
assert len(calls) == 1, "an unrecognisable composer must not be retried"

status = "  Codex Sol high · Context 0% used · weekly 88% left …"
hints = "  ← for agents · ? for shor  ⚠ 1 warning · f2 to view"
def pane(*rows):
    return "\n".join(["  >_ OpenAI Codex (v0.158.0)", "", *rows])
assert chat.codex_live_prompt_text(pane("› Ask Codex to do anything", " ", hints)) == "Ask Codex to do anything"
assert chat.codex_live_prompt_text(pane("› Ask Codex to do anything", " ", status, hints)) == "Ask Codex to do anything"
assert chat.codex_live_prompt_text(pane("› first half", "  second half", " ", status, hints)) == "first half\nsecond half"
typing = pane(
    "› Chat from Claude: Pair channel smoke test from the",
    "  Claude pane after fixing the two-row footer parser. No",
    "  task, nothing to change; please reply through peer-",
    "  chat.py with one line [peer-check:0]",
    " ",
    "  Codex Sol high · Context 0% used · weekly 88% left · 0…",
    "                                ⚠ 1 warning · f2 to view",
)
assert chat.codex_live_prompt_text(typing).endswith("chat.py with one line [peer-check:0]")
scrolled = pane(
    "› hidden material   ↑",
    "  prior confirmed context before this final segment",
    "  unique-end [peer-check:0]",
    " ",
    status,
    hints,
)
visible = chat.codex_live_prompt_text(scrolled)
assert visible == "prior confirmed context before this final segment\nunique-end [peer-check:0]"
assert chat.composer_has_expected_tail(
    visible,
    "old hidden material prior confirmed context before this final segment unique-end [peer-check:0]",
    "unique-end [peer-check:0]",
    True,
)
assert chat.codex_live_prompt_text(pane("› 1. Yes, proceed", "  2. No", " ", "  Press enter to confirm", "  or esc to cancel")) is None
assert chat.codex_live_prompt_text(pane("› Ask Codex to do anything", " ", "  / for commands", "  ! for shell", hints)) is None

cursor = chat.PROFILES["cursor"]
assert cursor.pane == "left" and cursor.command == "cursor-agent"
assert cursor.empty_cursor_column == 0
assert chat.parse_args(["--to", "cursor", "--stdin"]).to == "cursor"
assert chat.parse_args(["--to", "cursor", "--stdin", "--queue"]).queue
assert chat.parse_args(["--to", "cursor", "--stdin", "--steer"]).steer
for argv in (
    ["--to", "cursor", "--stdin", "--steer", "--queue"],
    ["--to", "claude", "--stdin", "--steer"],
    ["--to", "claude", "--stdin", "--queue"],
    ["--prepare-message", "peer-chat-codex-options.txt", "--steer"],
):
    with contextlib.redirect_stderr(io.StringIO()):
        try:
            chat.parse_args(argv)
        except SystemExit as err:
            assert err.code == 2
        else:
            raise AssertionError(f"invalid delivery options accepted: {argv}")
assert chat.target_profile("codex", None, queue=True).submit == "\t"
assert chat.target_profile("cursor", None, queue=True).submit == "\n"
assert chat.target_profile("codex", None, pane="left").pane == "left"
assert chat.parse_args(["--to", "codex", "--pane", "left", "--sender", "Gemini", "--command", "codex-wrapper", "--stdin"]).target_command == "codex-wrapper"
with contextlib.redirect_stderr(io.StringIO()):
    try:
        chat.parse_args(["--to", "codex", "--supervisor", "--stdin"])
    except SystemExit as err:
        assert err.code == 2
    else:
        raise AssertionError("supervisor delivery must pin a session and pane")

def cursor_screen(content, mode="Ask", busy=False):
    rows = content.splitlines() or [""]
    if busy:
        rows[0] += "    ctrl+c to stop"
    return "\n".join([
        "  Cursor Agent",
        " " + "▄" * 74,
        "  → " + rows[0],
        *("    " + row for row in rows[1:]),
        " " + "▀" * 78,
        *([f"  {mode} (shift+tab to cycle)"] if mode else []),
        "  Auto · 7.5%",
        "  /tmp/pair-qa",
    ])

for mode in (None, "Ask", "Plan", "Debug"):
    for placeholder in chat.CURSOR_EMPTY_PROMPTS:
        for busy in (False, True):
            screen = cursor_screen(placeholder, mode, busy)
            content = chat.live_prompt_text(cursor, screen)
            assert content == placeholder, (mode, busy, content)
            assert chat.composer_is_empty(cursor, content)
wrapped = "Chat from Codex: a wrapped message\nwith a second row"
assert chat.live_prompt_text(cursor, cursor_screen(wrapped)) == wrapped
idle_screen = cursor_screen("Add a follow-up")
assert chat.live_prompt_text(cursor, idle_screen + "\n\n  1. Allow\n  2. Deny") is None
assert chat.live_prompt_text(cursor, idle_screen + "\n  Error: model unavailable") is None
assert chat.live_prompt_text(cursor, idle_screen.replace("  →", "  !")) is None
assert chat.live_prompt_text(cursor, idle_screen.replace("  Auto · 7.5%", "  1. Allow")) is None
assert chat.live_prompt_text(cursor, idle_screen.replace("shift+tab", "unknown+tab")) is None

for mode in (None, "Ask", "Plan", "Debug"):
    for busy in (False, True):
        for draft in ("Add a follow-up", wrapped):
            modern_screen = cursor_screen(draft, mode, busy).replace(
                "  Auto · 7.5%\n  /tmp/pair-qa",
                "  Grok 4.7 500K High  ctx 66%  weekly 88% left",
            )
            assert chat.live_prompt_text(cursor, modern_screen) == draft, "single-row Cursor footer rejected"
            for tasks in ("1 task", "2 tasks"):
                task_screen = modern_screen.replace("\n  Grok", f"\n  {tasks}\n  Grok")
                assert chat.live_prompt_text(cursor, task_screen) == draft, "Cursor background-task status rejected"
                assert chat.live_prompt_text(cursor, task_screen + "\n  1. Allow") is None
            for trailing in ("\n  1. Allow\n  2. Deny", "\n  Error: model unavailable"):
                assert chat.live_prompt_text(cursor, modern_screen + trailing) is None
            assert chat.live_prompt_text(cursor, modern_screen.replace("  →", "  !")) is None
            assert chat.live_prompt_text(cursor, modern_screen.replace("  Grok 4.7 500K High  ctx 66%  weekly 88% left", "  Unrecognised status")) is None

plain = "Русский текст пары"
assert chat.normalize(cursor, plain) == cursor.label + plain
for message in ("Emoji 😊 and текст", "中文", "Cafe\u0301", chat.CURSOR_JSON_PREFIX + "literal text"):
    encoded = chat.normalize(cursor, message)
    assert encoded.isascii()
    envelope = encoded.removeprefix(cursor.label + chat.CURSOR_JSON_PREFIX)
    assert json.loads(envelope)["message"] == message
assert chat.normalize(claude, "Emoji 😊").endswith("Emoji 😊")
assert not chat.composer_probe_marker("text", cursor).startswith(" ")
assert chat.composer_probe_marker("[peer-check:0]", cursor) == "[peer-check:1]"

def cursor_followups(messages, action="steer", steering=False):
    rows = [" ┌─ follow-ups " + "─" * 58 + "┐"]
    for message in messages:
        words = (message + (" · steering" if steering else "")).split()
        wrapped = [""]
        for word in words:
            if len(wrapped[-1]) + len(word) + 1 > 60:
                wrapped.append("")
            wrapped[-1] += (" " if wrapped[-1] else "") + word
        rows.extend(" │ " + ("○ " if i == 0 else "  ") + row + " │" for i, row in enumerate(wrapped))
    rows += [f" │ enter {action} · ↑ select/edit · esc cancel │", " └" + "─" * 72 + "┘"]
    return "\n".join(rows) + "\n"


class FakeAgterm:
    sid = "pair-session"
    window = "pair-window"

    def __init__(self, draft="", busy=False, truncate=False, delayed_draft=None):
        self.draft = draft
        self.busy = busy
        self.truncate = truncate
        self.events = []
        self.accepted = []
        self.delayed_draft = delayed_draft
        self.reads = 0
        self.queued = []
        self.steering = False
        self.action = "steer"
        self.confirm_steer = True
        self.after_queue_read = None
        self.queue_reads = 0
        self.node = {
            "id": self.sid, "hasSplit": True, "active": False,
            "foreground": ["/opt/bin/cursor-agent"], "splitForeground": ["codex"],
        }

    def ctl(self, *args, input_text=None):
        if args[:2] == ("tree", "--json"):
            return json.dumps({"sessions": [self.node]})
        if args[:2] == ("window", "list"):
            return json.dumps({"result": {"windows": [{
                "id": self.window, "open": True, "active": True,
            }]}})
        if args[:2] == ("session", "text"):
            self.reads += 1
            if self.queued and not self.draft:
                self.queue_reads += 1
                if self.after_queue_read:
                    self.after_queue_read(self)
            if self.reads == 2 and self.delayed_draft is not None:
                self.draft = self.delayed_draft
            tray = cursor_followups(self.queued, self.action, self.steering) if self.queued else ""
            return tray + cursor_screen(self.draft or "Add a follow-up", mode=None, busy=self.busy and not self.draft)
        if args[:2] == ("surface", "cursor"):
            return "0"
        if args[:2] != ("session", "type"):
            raise AssertionError(args)
        self.events.append(input_text)
        if input_text in {"\x1b[I", "\x1b[O"}:
            return "ok"
        if input_text == "\n":
            if self.draft:
                self.accepted.append(self.draft)
                if self.busy:
                    self.queued.append(self.draft)
                self.draft = ""
            elif self.queued and self.confirm_steer:
                assert self.action == "steer", "an empty Return would interrupt Cursor"
                self.steering = True
                self.action = "interrupt and send"
        elif input_text == "\x7f":
            self.draft = self.draft[:-1]
        elif self.truncate:
            self.truncate = False
            self.draft += input_text[:30]
        else:
            self.draft += input_text
        return "ok"

chat.clear_composer = original_clear_composer
chat.CHUNK_SETTLE_DELAY = 0
chat.COMPOSER_SETTLE_DELAY = 0
chat.PROBE_TIMEOUT = 0.01
saved_commands = {name: os.environ.pop(name, None) for name in (
    "PEER_CHAT_CLAUDE_COMMAND", "PEER_CHAT_CURSOR_COMMAND", "PEER_CHAT_CODEX_COMMAND",
)}
original_ctl = chat.ctl
try:
    for busy in (False, True):
        fake = FakeAgterm(busy=busy)
        chat.ctl = fake.ctl
        message = "transport check " + " ".join(f"item-{i}" for i in range(50))
        if busy:
            message += " 😊"
        progress = chat.DeliveryProgress()
        assert chat.send(fake.sid, cursor, message, fake.window, delivery=progress) == len(message)
        assert fake.accepted == [chat.normalize(cursor, message)]
        assert fake.events.count("\n") == (2 if busy else 1), "busy Cursor messages must be steered out of the follow-up queue"
        assert fake.steering == busy
        assert progress.outcome == ("steering" if busy else "submitted")
        assert fake.events[0] == "\x1b[I" and fake.events[-1] == "\x1b[O"
        assert all(event == "\x7f" for event in fake.events if "\x7f" in event)

    for action in ("steer", "interrupt and send", "send now"):
        fake = FakeAgterm(busy=True)
        fake.queued = ["a user's earlier follow-up"]
        fake.action = action
        chat.ctl = fake.ctl
        try:
            chat.send(fake.sid, cursor, "must not steer another message", fake.window)
        except chat.PromptBlocked as err:
            assert "--queue" in str(err)
        else:
            raise AssertionError("an occupied Cursor follow-up queue was steered")
        assert not fake.events and fake.queued == ["a user's earlier follow-up"]

        queued = chat.target_profile("cursor", None, queue=True)
        progress = chat.DeliveryProgress()
        assert chat.send(fake.sid, queued, "an informational note", fake.window, delivery=progress)
        assert progress.outcome == "queued"
        assert fake.events.count("\n") == 1 and not fake.steering
        assert fake.queued[0] == "a user's earlier follow-up"

    for failure in ("no ack", "other message", "new draft", "send now", "already steering", "consumed"):
        fake = FakeAgterm(busy=True)
        fake.confirm_steer = failure != "no ack"
        def race(transport):
            if transport.queue_reads != 4:
                return
            if failure == "other message":
                transport.queued.insert(0, "an unrelated follow-up")
            elif failure == "new draft":
                transport.draft = "a new user draft"
            elif failure == "send now":
                transport.action = "send now"
            elif failure == "already steering":
                transport.action = "interrupt and send"
            elif failure == "consumed":
                transport.queued.clear()
        fake.after_queue_read = race
        chat.ctl = fake.ctl
        try:
            chat.send_with_retry(fake.sid, cursor, "one finding", fake.window)
        except chat.DeliveryAmbiguous as err:
            assert "do not resend" in str(err)
        else:
            raise AssertionError(f"unverified Cursor steering reported success: {failure}")
        assert fake.events.count("\n") == (2 if failure == "no ack" else 1), failure
        assert len(fake.accepted) == 1, "ambiguous delivery must not resend the message"
        if failure == "new draft":
            assert fake.draft == "a new user draft", "a raced user draft was changed"

    long_message = ("Chat from Codex: " + "a long finding " * 30).strip()
    preview = long_message[:100].rstrip() + "…"
    for shown in (long_message, preview, preview + " · steering"):
        screen = cursor_followups([shown]) + cursor_screen("Add a follow-up", busy=True)
        state = chat.cursor_followup_state(screen)
        assert state is not None and chat.cursor_owns_followup(state[0], long_message)
        assert chat.cursor_followup_state(screen.replace("│ enter", "│ +12 more lines · enter")) == state
        assert chat.cursor_followup_state(screen.split("\n", 1)[1]) is None, "clipped queues must fail closed"
    split_word = long_message.replace("finding", "find ing", 1)
    assert chat.cursor_owns_followup((split_word,), long_message), "terminal wrapping may split a word"
    assert not chat.cursor_owns_followup(("Chat…",), long_message)
    assert not chat.cursor_owns_followup((long_message, "another message"), long_message)
    assert not chat.cursor_owns_followup(("Chat from another agent: wrong message",), long_message)

    original_run_main = chat.run_main
    try:
        def ambiguous_main(_progress):
            raise chat.DeliveryAmbiguous("unconfirmed steering; do not resend")
        chat.run_main = ambiguous_main
        output, errors = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
            assert chat.main() == 1
        assert json.loads(output.getvalue()) == {"delivery": "ambiguous"}
        assert "do not resend" in errors.getvalue()
    finally:
        chat.run_main = original_run_main

    for draft in ("a user draft", "Waiting for decision (y/n/p)..."):
        fake = FakeAgterm(draft=draft)
        chat.ctl = fake.ctl
        try:
            chat.send(fake.sid, cursor, "must not overwrite input", fake.window)
        except chat.PromptBlocked:
            pass
        else:
            raise AssertionError("occupied Cursor input was accepted")
        assert not fake.events and fake.draft == draft

    fake = FakeAgterm(delayed_draft="queued user keystrokes")
    chat.ctl = fake.ctl
    try:
        chat.send(fake.sid, cursor, "must not race pending input", fake.window)
    except chat.PromptBlocked:
        pass
    else:
        raise AssertionError("queued user input was overwritten")
    assert not fake.events and fake.draft == "queued user keystrokes"

    fake = FakeAgterm(truncate=True)
    chat.ctl = fake.ctl
    try:
        chat.send(fake.sid, cursor, "a truncated transport message must never submit", fake.window)
    except chat.ComposerDirty as err:
        assert "composer cleared" in str(err), err
    else:
        raise AssertionError("a truncated message was submitted")
    assert not fake.accepted and not fake.draft
    assert fake.events[-1] == "\x1b[O"

    fake = FakeAgterm()
    chat.ctl = fake.ctl
    fake.node["hasSplit"] = False
    fake.node["splitForeground"] = []
    supervised = chat.target_profile("cursor", None, pane="left", supervisor=True)
    assert not chat.has_target(fake.node, cursor)
    assert chat.has_target(fake.node, supervised)
    supervised = chat.with_sender_label(fake.sid, supervised, fake.window)
    assert supervised.label.startswith("[Supervisor ")
    assert chat.send(fake.sid, supervised, "continue the selected task", fake.window)
    assert len(fake.accepted) == 1 and fake.accepted[0].startswith("[Supervisor ")
    fake = FakeAgterm()
    chat.ctl = fake.ctl
    for command, label in (("cursor-agent", "Cursor"), ("claude", "Claude")):
        fake.node["foreground"] = [command]
        assert chat.with_sender_label(fake.sid, codex, fake.window).label == f"Chat from {label}: "
    for command in ("codex", "grok", "gemini", "custom-agent"):
        fake.node["foreground"] = [command]
        expected = "Codex" if command == "codex" else command
        assert chat.with_sender_label(fake.sid, codex, fake.window).label == f"Chat from {expected}: "
        assert chat.has_target(fake.node, codex)
    fake.node["foreground"] = ["codex"]
    fake.node["splitForeground"] = ["gemini-wrapper"]
    left_codex = chat.target_profile("codex", None, pane="left")
    assert chat.has_target(fake.node, left_codex)
    assert chat.with_sender_label(fake.sid, left_codex, fake.window, "Gemini", "gemini-wrapper").label == "Chat from Gemini: "
    try:
        chat.with_sender_label(fake.sid, left_codex, fake.window, "Gemini", "wrong-wrapper")
    except RuntimeError as err:
        assert "nothing was typed" in str(err)
    else:
        raise AssertionError("a changed sender foreground was accepted")
    fake.node["splitForeground"] = ["codex"]
    launched = [
        "/Users/me/.local/bin/agent",
        "--use-system-ca",
        "/Users/me/.local/share/cursor-agent/versions/2026.10.01/index.js",
    ]
    fake.node["foreground"] = launched
    assert chat.with_sender_label(fake.sid, codex, fake.window).label == "Chat from Cursor: "
    assert chat.has_target(fake.node, cursor)
    fake.node["foreground"] = ["agent"]
    assert not chat.has_target(fake.node, cursor)
    try:
        chat.with_sender_label(fake.sid, codex, fake.window)
    except RuntimeError as err:
        assert "nothing was typed" in str(err)
    else:
        raise AssertionError("a bare agent process was treated as Cursor")
    os.environ["PEER_CHAT_CURSOR_COMMAND"] = "cursor-wrapper"
    fake.node["foreground"] = ["cursor-wrapper"]
    assert chat.with_sender_label(fake.sid, codex, fake.window).label == "Chat from Cursor: "
    fake.node["foreground"] = ["cursor-wrapper", "--", "discuss claude and codex"]
    assert chat.with_sender_label(fake.sid, codex, fake.window).label == "Chat from Cursor: "
    fake.node["foreground"] = ["zsh"]
    try:
        chat.with_sender_label(fake.sid, codex, fake.window)
    except RuntimeError as err:
        assert "nothing was typed" in str(err)
    else:
        raise AssertionError("an unknown sender was labelled as Claude")

    fake.node["foreground"] = ["cursor-wrapper"]
    observed = []
    original_send_with_retry = chat.send_with_retry
    original_argv, original_stdin = sys.argv, sys.stdin
    try:
        def capture_send(sid, profile, message, window, progress):
            observed.append((sid, profile.label, message))
            return len(message)
        chat.send_with_retry = capture_send
        sys.argv = [sys.argv[0], "--to", "codex", "--stdin", "--session", fake.sid, "--window", fake.window]
        sys.stdin = io.StringIO("reply to Cursor")
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            assert chat.run_main(chat.DeliveryProgress()) == 0
        assert observed == [(fake.sid, "Chat from Cursor: ", "reply to Cursor")]
        assert json.loads(output.getvalue()) == {"sent": len("reply to Cursor"), "delivery": "submitted"}
    finally:
        chat.send_with_retry = original_send_with_retry
        sys.argv, sys.stdin = original_argv, original_stdin

    fake.node["active"] = True
    original_platform, original_run = sys.platform, chat.subprocess.run
    try:
        sys.platform = "darwin"
        foreground_bundle = '"CFBundleIdentifier"="com.umputun.agterm"'
        def front_app(args, **kwargs):
            assert args[0] == "/usr/bin/lsappinfo", args
            output = "ASN:0x0-0x2002:" if args[1] == "front" else foreground_bundle
            return chat.subprocess.CompletedProcess(args, 0, stdout=output)
        chat.subprocess.run = front_app
        assert chat.target_is_focused(fake.sid, cursor, fake.window)
        foreground_bundle = '"CFBundleIdentifier"="com.apple.loginwindow"'
        assert not chat.target_is_focused(fake.sid, cursor, fake.window)
        foreground_bundle = '"CFBundleIdentifier"="com.umputun.agterm"'
        fake.node["splitFocused"] = True
        assert not chat.target_is_focused(fake.sid, cursor, fake.window)
    finally:
        sys.platform, chat.subprocess.run = original_platform, original_run

    class FakeResolver:
        def ctl(self, *args, input_text=None):
            if args[:2] == ("window", "list"):
                return json.dumps({"result": {"windows": [
                    {"id": "old-window", "open": True, "active": False},
                    {"id": "new-window", "open": True, "active": True},
                ]}})
            if args[:2] == ("tree", "--json"):
                window = args[args.index("--window") + 1]
                sessions = [{
                    "id": "live-session", "hasSplit": True,
                    "foreground": ["claude"], "splitForeground": ["codex"],
                }] if window == "new-window" else []
                return json.dumps({"sessions": sessions})
            raise AssertionError(args)

    saved_selectors = {name: os.environ.get(name) for name in (
        "AGTERM_SESSION_ID", "AGTERM_WINDOW_ID",
    )}
    original_spool = chat.MESSAGE_SPOOL
    original_send_with_retry = chat.send_with_retry
    original_argv = sys.argv
    try:
        chat.ctl = FakeResolver().ctl
        os.environ["AGTERM_SESSION_ID"] = "old-session"
        os.environ["AGTERM_WINDOW_ID"] = "old-window"
        with tempfile.TemporaryDirectory() as directory:
            chat.MESSAGE_SPOOL = Path(directory) / "spool"
            name = "peer-chat-codex-recovery.txt"
            path = chat.prepare_message(name)
            path.write_text("review findings", encoding="utf-8")
            sys.argv = [sys.argv[0], "--to", "claude", "--message-file", name]
            try:
                chat.run_main(chat.DeliveryProgress())
            except RuntimeError as err:
                assert "AGTERM_SESSION_ID is stale" in str(err), err
                assert "--session ID" in str(err), err
            else:
                raise AssertionError("a stale session was accepted")
            assert path.read_text(encoding="utf-8") == "review findings"

            os.environ["AGTERM_SESSION_ID"] = "live-session"
            assert chat.resolve_target(None, None, claude) == ("new-window", "live-session")

            os.environ["AGTERM_SESSION_ID"] = "old-session"
            delivered = []
            def capture_recovery(sid, profile, message, window, progress):
                delivered.append((sid, profile.agent, message, window))
                return len(message)
            chat.send_with_retry = capture_recovery
            sys.argv += ["--session", "live-session"]
            with contextlib.redirect_stdout(io.StringIO()):
                assert chat.run_main(chat.DeliveryProgress()) == 0
            assert delivered == [("live-session", "claude", "review findings", "new-window")]
            assert not path.exists()

        wrong_peer = {
            "hasSplit": True, "foreground": ["claude"],
            "splitForeground": ["cursor-agent"],
        }
        assert chat.has_target(wrong_peer, claude), "a known non-Codex peer must not invalidate the target"
    finally:
        chat.MESSAGE_SPOOL = original_spool
        chat.send_with_retry = original_send_with_retry
        sys.argv = original_argv
        for name, value in saved_selectors.items():
            os.environ.pop(name, None)
            if value is not None:
                os.environ[name] = value
finally:
    chat.ctl = original_ctl
    for name, value in saved_commands.items():
        os.environ.pop(name, None)
        if value is not None:
            os.environ[name] = value
PY

echo "peer-chat tests passed"
