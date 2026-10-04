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
assert chat.codex_live_prompt_text(pane("› 1. Yes, proceed", "  2. No", " ", "  Press enter to confirm", "  or esc to cancel")) is None
assert chat.codex_live_prompt_text(pane("› Ask Codex to do anything", " ", "  / for commands", "  ! for shell", hints)) is None

cursor = chat.PROFILES["cursor"]
assert cursor.pane == "left" and cursor.command == "cursor-agent"
assert cursor.empty_cursor_column == 0
assert chat.parse_args(["--to", "cursor", "--stdin"]).to == "cursor"
with contextlib.redirect_stderr(io.StringIO()):
    try:
        chat.parse_args(["--to", "cursor", "--stdin", "--queue"])
    except SystemExit as err:
        assert err.code == 2
    else:
        raise AssertionError("Cursor must not inherit Codex's Tab queue key")
assert chat.target_profile("codex", None, queue=True).submit == "\t"

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
            if self.reads == 2 and self.delayed_draft is not None:
                self.draft = self.delayed_draft
            return cursor_screen(self.draft or "Add a follow-up", mode=None, busy=self.busy and not self.draft)
        if args[:2] == ("surface", "cursor"):
            return "0"
        if args[:2] != ("session", "type"):
            raise AssertionError(args)
        self.events.append(input_text)
        if input_text in {"\x1b[I", "\x1b[O"}:
            return "ok"
        if input_text == "\n":
            self.accepted.append(self.draft)
            self.draft = ""
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
        assert chat.send(fake.sid, cursor, message, fake.window) == len(message)
        assert fake.accepted == [chat.normalize(cursor, message)]
        assert fake.events.count("\n") == 1
        assert fake.events[0] == "\x1b[I" and fake.events[-1] == "\x1b[O"
        assert all(event == "\x7f" for event in fake.events if "\x7f" in event)

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
    for command, label in (("cursor-agent", "Cursor"), ("claude", "Claude")):
        fake.node["foreground"] = [command]
        assert chat.with_sender_label(fake.sid, codex, fake.window).label == f"Chat from {label}: "
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
        assert json.loads(output.getvalue()) == {"sent": len("reply to Cursor")}
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
finally:
    chat.ctl = original_ctl
    for name, value in saved_commands.items():
        os.environ.pop(name, None)
        if value is not None:
            os.environ[name] = value
PY

echo "peer-chat tests passed"
