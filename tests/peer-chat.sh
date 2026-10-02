#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PYTHONDONTWRITEBYTECODE=1 python3 - "$ROOT/plugins/core/skills/pair/scripts/peer-chat.py" <<'PY'
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("peer_chat", sys.argv[1])
chat = importlib.util.module_from_spec(spec)
sys.modules["peer_chat"] = chat
spec.loader.exec_module(chat)
claude, codex = chat.PROFILES["claude"], chat.PROFILES["codex"]

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
PY

echo "peer-chat tests passed"
