#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import fcntl
import importlib.util
import json
import os
import re
import sys
import time
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "devkit/feedback"
TICKETS = STATE / "tickets"
QUEUE = ROOT / "docs/feedback-queue"
SECRET = re.compile(r"(?i)\b(api[_-]?key|password|secret|token)\s*([:=])\s*([^\s,;]+)")
WTF = re.compile(r"(?i)\bwtf\b")
PRIVATE_KEY = re.compile(r"-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----")
AREAS = {
    "skill": "The coding assistant's reusable skill, workflow, or supporting script caused the complaint",
    "guidance": "Coding-agent instructions or preferences: CLAUDE.md, AGENTS.md, branch/worktree handling, approvals, or communication",
    "hook": "The coding assistant's harness hook, installer, or automation caused it",
    "memory": "A remembered user preference or fact was wrong or missing",
    "other": "The complaint is about a one-off task, project code, or an unknown cause",
}
HINTS = {
    "skill": "plugins/core/skills/ and other plugins/*/skills/",
    "guidance": "~/.claude/CLAUDE.md, ~/.codex/AGENTS.md, or their source in bin/devkit-install",
    "hook": "plugins/core/hooks/ or bin/devkit-install",
    "memory": "personal agent memory; inspect its actual storage before changing it",
    "other": "inspect evidence before choosing a file",
}
TITLES = {
    "skill": "Review agent skill feedback",
    "guidance": "Review agent guidance feedback",
    "hook": "Review agent hook feedback",
    "memory": "Review agent memory feedback",
    "other": "Review agent workflow feedback",
}


def private_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    path.chmod(0o700)


def save_ticket(path: Path, ticket: dict) -> None:
    private_dir(path.parent)
    temporary = path.with_name(f"{path.name}.{os.getpid()}.tmp")
    with open(temporary, "w", encoding="utf-8", opener=lambda p, f: os.open(p, f, 0o600)) as file:
        json.dump(ticket, file, ensure_ascii=False, indent=2)
        file.write("\n")
    temporary.replace(path)


def save_queue_entry(ticket: dict, ticket_path: Path) -> None:
    if ticket.get("status") != "untriaged":
        return
    item = QUEUE / f"agent-feedback-{ticket['repair_area']}-{ticket['id']}.md"
    source = "WTF cue" if ticket.get("wtf_signal") else "Jev"
    body = (
        f"---\nstatus: untriaged\nadded: {date.today().isoformat()}\n---\n"
        f"# {TITLES[ticket['repair_area']]} {ticket['id']}\n\n"
        f"{source} flagged possible agent-workflow feedback "
        f"(feedback {ticket['feedback_probability']:.2f}, reusable {ticket['reusable_probability']:.2f}). "
        f"Candidate location: `{ticket['candidate_location']}`.\n\n"
        f"Private evidence: `{ticket_path}`. Verify the session context, then triage this item.\n"
    )
    try:
        QUEUE.mkdir(parents=True, exist_ok=True)
        with open(item, "x", encoding="utf-8", opener=lambda p, f: os.open(p, f, 0o600)) as file:
            file.write(body)
    except FileExistsError:
        pass
    except OSError as error:
        print(f"jev-feedback: cannot write queue entry {item}: {error}", file=sys.stderr)


def jev_module():
    path = ROOT / "plugins/core/skills/jev/scripts/jev.py"
    spec = importlib.util.spec_from_file_location("devkit_jev", path)
    module = importlib.util.module_from_spec(spec)
    sys.dont_write_bytecode = True
    spec.loader.exec_module(module)
    module.TIMEOUT = 6
    module.ATTEMPTS = 1
    return module


def clean_prompt(prompt: str) -> str:
    return SECRET.sub(lambda match: f"{match[1]}{match[2]}[REDACTED]", prompt[:5000])


def feedback_prompt(prompt: str) -> str:
    if re.match(r"Chat from (?:Claude|Codex|Cursor): ", prompt):
        return ""
    if prompt.startswith("<task-notification>"):
        return ""
    if prompt.startswith("<send_user_message_question_reply>"):
        try:
            body = prompt.removeprefix("<send_user_message_question_reply>").removesuffix(
                "</send_user_message_question_reply>"
            )
            replies = json.loads(body)
            return "\n".join(
                reply["answer"] for reply in replies if isinstance(reply.get("answer"), str)
            )
        except (AttributeError, KeyError, TypeError, ValueError):
            return ""
    return prompt


def session_tickets(session: str) -> Path:
    return TICKETS / hashlib.sha256(session.encode()).hexdigest()[:20]


def classify(prompt: str) -> tuple[float, float, str, float]:
    jev = jev_module()
    answers, _, _ = jev.run({
        "state": {"user_prompt": prompt},
        "questions": {
            "target": {
                "type": "choice",
                "instructions": "Classify the object the user wants corrected. The coding assistant and its development tools are assistant; the application it develops is product. A coding-agent hook that blocks commands is assistant. A recruiter bot that forgets answers or cannot reschedule is product, even if its prompt or memory needs fixing. Asking a subagent to fix a product does not change the target. Use other if unclear; frustration or WTF alone supplies no evidence.",
                "criteria": {
                    "assistant": "Coding-assistant behavior or development tooling: skills, peer chat, git worktrees, authorization checks, harness hooks, or agent instructions",
                    "product": "Application runtime behavior: recruiter/candidate conversations, chatbot prompts or memory, business rules, UI, data, or integrations",
                    "other": "An external service, ordinary task request, or unclear target",
                },
            },
            "feedback": {
                "type": "noul",
                "instructions": "Should this user message create a candidate to improve an AI coding agent workflow? Say yes when the user corrects, challenges, or complains about the coding assistant's work, or states a reusable preference for how it should work, and a change to its skills, conduct, hooks, project guidance, or agent memory could prevent recurrence. Branch/worktree handling and peer-update preferences count even when phrased as direct instructions. An indirect question can count when it identifies an omitted check or workflow flaw. Say no for ordinary progress/status questions, current-task product code or data fixes, one-off scope decisions, and external-service problems. Feedback about an application's chatbot or its prompts is product feedback, not feedback about the coding assistant. Do not assume the issue was already fixed after this message.",
            },
        },
    })
    feedback = float(answers["feedback"]["noul"])
    if answers["target"]["choice"] != "assistant":
        return feedback, 0.0, "other", 0.0
    if feedback < 0.5 and not WTF.search(prompt):
        return feedback, 0.0, "other", 0.0
    answers, _, _ = jev.run({
        "state": {"prompt": prompt},
        "questions": {
            "reusable": {
                "type": "noul",
                "instructions": "If this prompt is feedback about this AI assistant, could a reusable change to its personal instructions, skills, hooks, or memory plausibly reduce recurrence across future sessions? Task-specific code/data/content corrections are no. A recurring planning, completeness, coordination, or scope-understanding failure is yes.",
            },
            "repair_area": {
                "type": "choice",
                "instructions": "Which coding-assistant resource should be investigated for this reusable workflow feedback? Branch/worktree, approval, and communication preferences belong to guidance; an explicitly named skill belongs to skill; coding-agent harness hooks belong to hook. Select the best investigation area without requiring proof of the root cause. Choose other for product feedback or when no coding-assistant resource is implicated.",
                "criteria": AREAS,
            },
        },
    })
    reusable = float(answers["reusable"]["noul"])
    area = answers["repair_area"]["choice"]
    confidence = float(answers["repair_area"].get("confidence", 0))
    return feedback, reusable, area, confidence


def first_string(*values) -> str:
    for value in values:
        if isinstance(value, str) and value:
            return value
    return ""


def normalize_prompt_payload(payload: dict) -> dict:
    normalized = dict(payload)
    session = first_string(
        payload.get("conversation_id"),
        payload.get("session_id"),
        payload.get("sessionId"),
    )
    if session:
        normalized["session_id"] = session
    cwd = first_string(payload.get("cwd"))
    if not cwd:
        roots = payload.get("workspace_roots")
        if isinstance(roots, list):
            cwd = first_string(*(root for root in roots))
    if cwd:
        normalized["cwd"] = cwd
    transcript = first_string(payload.get("transcript_path"), payload.get("transcriptPath"))
    if transcript:
        normalized["transcript_path"] = transcript
    return normalized


def handle_prompt(payload: dict) -> None:
    if os.environ.get("DEVKIT_FEEDBACK_WORKER") == "1":
        return
    payload = normalize_prompt_payload(payload)
    prompt = payload.get("prompt")
    session = payload.get("session_id")
    if not isinstance(prompt, str) or not prompt.strip() or not isinstance(session, str) or not session:
        return
    if PRIVATE_KEY.search(prompt):
        return
    extracted = feedback_prompt(prompt)
    if not extracted.strip():
        return
    cleaned = clean_prompt(extracted)
    wtf_signal = bool(WTF.search(cleaned))
    ticket_id = hashlib.sha256(f"{session}\0{prompt}".encode()).hexdigest()[:20]
    path = session_tickets(session) / f"{ticket_id}.json"
    private_dir(path.parent)
    checked_path = path.with_suffix(".checked")
    with open(checked_path, "a+", encoding="utf-8", opener=lambda p, f: os.open(p, f, 0o600)) as checked:
        fcntl.flock(checked, fcntl.LOCK_EX)
        if path.exists():
            save_queue_entry(json.loads(path.read_text()), path)
            return
        checked.seek(0)
        if checked.read() == "done" and time.time() - checked_path.stat().st_mtime < 60:
            return
        try:
            feedback, reusable, area, confidence = classify(cleaned)
        except Exception as error:
            print(f"jev-feedback: classification unavailable: {error}", file=sys.stderr)
            return
        checked.seek(0)
        checked.write("done")
        checked.truncate()
        checked.flush()
        if (feedback < 0.5 and not wtf_signal) or reusable < 0.45 or area not in HINTS or area == "other":
            return
        ticket = {
            "id": ticket_id,
            "session_id": session,
            "status": "untriaged",
            "source_cwd": payload.get("cwd", ""),
            "transcript_path": payload.get("transcript_path", ""),
            "prompt": cleaned,
            "feedback_probability": feedback,
            "wtf_signal": wtf_signal,
            "reusable_probability": reusable,
            "repair_area": area,
            "area_confidence": confidence,
            "candidate_location": HINTS[area],
        }
        save_ticket(path, ticket)
        save_queue_entry(ticket, path)


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] != "prompt":
        return
    payload = json.load(sys.stdin)
    handle_prompt(payload)
    if payload.get("hook_event_name") == "beforeSubmitPrompt":
        print(json.dumps({"continue": True}))


if __name__ == "__main__":
    main()
