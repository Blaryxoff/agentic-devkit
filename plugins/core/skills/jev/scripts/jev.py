#!/usr/bin/env python3
"""Ask Jev (TypeSafe System One) typed questions about a state and print the typed answers."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

DEFAULT_BASE_URL = "https://api.typesafe.ai"
DEFAULT_MODEL = "jev-1.13.0"
DEFAULT_KEY_FILE = Path.home() / ".config/jev/typesafe-key"
USAGE_LOG = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "jev/usage.jsonl"
PRICE_PER_MTOK = 0.042
MAX_SCORE_LEVELS = 10
RETRYABLE = {408, 425, 429, 500, 502, 503, 504}
ATTEMPTS = 3
TIMEOUT = 60


class JevError(Exception):
    pass


def load_key() -> str:
    key = os.environ.get("JEV_API_KEY", "").strip()
    if key:
        return key
    path = Path(os.environ.get("JEV_KEY_FILE", DEFAULT_KEY_FILE)).expanduser()
    try:
        key = path.read_text().strip()
    except OSError as error:
        raise JevError(f"no API key: set JEV_API_KEY or create {path} (mode 600)") from error
    if not key:
        raise JevError(f"API key file is empty: {path}")
    return key


def validate(payload: Any) -> dict[str, Any]:
    if not isinstance(payload, dict):
        raise JevError("request must be a JSON object with state and questions")
    if "state" not in payload or payload["state"] in ("", None, {}):
        raise JevError("request needs a non-empty state")
    questions = payload.get("questions")
    if not isinstance(questions, dict) or not questions:
        raise JevError("request needs a non-empty questions object")
    for name, question in questions.items():
        kind = question.get("type") if isinstance(question, dict) else None
        if kind not in ("choice", "score", "noul"):
            raise JevError(f"{name}: type must be choice, score or noul")
        if not str(question.get("instructions", "")).strip():
            raise JevError(f"{name}: instructions must be non-empty")
        criteria = question.get("criteria")
        if kind == "choice" and (not isinstance(criteria, dict) or len(criteria) < 2):
            raise JevError(f"{name}: choice criteria must be an object with at least two options")
        if kind == "score" and (not isinstance(criteria, list) or not 2 <= len(criteria) <= MAX_SCORE_LEVELS):
            raise JevError(f"{name}: score criteria must be a list of 2-{MAX_SCORE_LEVELS} levels, low to high")
    for forbidden in ("temperature", "top_p", "seed", "stream"):
        payload.pop(forbidden, None)
    return payload


def post(payload: dict[str, Any]) -> tuple[dict[str, Any], float]:
    base = os.environ.get("JEV_BASE_URL", DEFAULT_BASE_URL).rstrip("/")
    url = base if base.endswith("/systemone") else f"{base}/v1/systemone"
    body = json.dumps(payload).encode()
    headers = {
        "Authorization": f"Bearer {load_key()}",
        "Content-Type": "application/json",
        "User-Agent": "devkit-jev/1",
    }
    for attempt in range(1, ATTEMPTS + 1):
        started = time.monotonic()
        request = urllib.request.Request(url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
                return json.load(response), time.monotonic() - started
        except urllib.error.HTTPError as error:
            message = error_message(error)
            if error.code not in RETRYABLE or attempt == ATTEMPTS:
                raise JevError(f"HTTP {error.code}: {message}") from error
            time.sleep(retry_delay(error.headers.get("Retry-After"), attempt))
        except (urllib.error.URLError, TimeoutError) as error:
            if attempt == ATTEMPTS:
                raise JevError(f"request failed: {error}") from error
            time.sleep(retry_delay(None, attempt))
    raise JevError("unreachable")


def error_message(error: urllib.error.HTTPError) -> str:
    try:
        details = json.load(error)
        return details.get("error", {}).get("message") or str(details)
    except (ValueError, AttributeError):
        return str(error.reason)


def retry_delay(header: str | None, attempt: int) -> float:
    try:
        return min(float(header), 90.0) if header else 2.0 ** attempt
    except ValueError:
        return 2.0 ** attempt


def record_usage(model: str, tokens: int, seconds: float) -> None:
    try:
        USAGE_LOG.parent.mkdir(parents=True, exist_ok=True)
        with USAGE_LOG.open("a") as log:
            log.write(json.dumps({"ts": int(time.time()), "model": model, "input_tokens": tokens,
                                  "ms": round(seconds * 1000)}) + "\n")
    except OSError:
        pass


def compact(answer: dict[str, Any]) -> dict[str, Any]:
    kind = answer.get("type")
    if kind == "noul":
        return {"noul": round(answer["noul"], 3)}
    if kind == "choice":
        ranked = sorted(answer.get("probabilities", {}).items(), key=lambda item: -item[1])
        return {"choice": answer["choice"], "confidence": round(answer.get("confidence", 0), 3),
                "ranked": [[key, round(p, 3)] for key, p in ranked if p >= 0.01]}
    if kind == "score":
        legend = answer.get("legend", {})
        nearest = legend.get(str(round(answer["score"])), "")
        return {"score": round(answer["score"], 2), "nearest": nearest,
                "confidence": round(answer.get("confidence", 0), 3)}
    return answer


def run(payload: dict[str, Any]) -> tuple[dict[str, Any], int, float]:
    payload = validate(payload)
    payload.setdefault("model", os.environ.get("JEV_MODEL", DEFAULT_MODEL))
    result, seconds = post(payload)
    tokens = int(result.get("usage", {}).get("input_tokens", 0))
    record_usage(payload["model"], tokens, seconds)
    return result.get("answers", {}), tokens, seconds


def noul_scores(answers: dict[str, Any], questions: dict[str, Any]) -> dict[int, float]:
    scores: dict[int, float] = {}
    for name in questions:
        answer = answers.get(name)
        value = answer.get("noul") if isinstance(answer, dict) else None
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise JevError(f"response has no noul answer for {name}")
        scores[int(name[1:])] = float(value)
    return scores


def cmd_ask(args: argparse.Namespace) -> int:
    raw = sys.stdin.read() if args.request == "-" else Path(args.request).read_text()
    answers, tokens, seconds = run(json.loads(raw))
    if not args.full:
        answers = {name: compact(answer) for name, answer in answers.items()}
    print(json.dumps({"answers": answers, "input_tokens": tokens, "ms": round(seconds * 1000)},
                     ensure_ascii=False))
    return 0


def chunks(lines: list[str], budget: int) -> list[list[int]]:
    groups: list[list[int]] = [[]]
    size = 0
    for index, line in enumerate(lines):
        cost = len(line) + 80
        if groups[-1] and size + cost > budget:
            groups.append([])
            size = 0
        groups[-1].append(index)
        size += cost
    return groups


def cmd_filter(args: argparse.Namespace) -> int:
    lines = [line[: args.max_line] for line in sys.stdin.read().splitlines() if line.strip()]
    if not lines:
        print("jev filter: no input lines", file=sys.stderr)
        return 0
    scores: dict[int, float] = {}
    tokens = 0
    seconds = 0.0
    for group in chunks(lines, args.chunk_chars):
        state = {"task": args.task, "items": {f"i{n}": lines[n] for n in group}}
        questions = {f"i{n}": {"type": "noul", "instructions": f"Is item i{n} directly useful for the task?"}
                     for n in group}
        answers, used, took = run({"state": state, "questions": questions})
        tokens += used
        seconds += took
        scores.update(noul_scores(answers, questions))
    ranked = sorted(scores, key=lambda n: -scores[n])
    kept = [n for n in ranked if scores[n] >= args.threshold][: args.top]
    for n in kept:
        print(f"{scores[n]:.2f}\t{lines[n]}" if args.scores else lines[n])
    print(f"jev filter: kept {len(kept)}/{len(lines)} lines (best score {scores[ranked[0]]:.2f}), "
          f"{tokens} input tokens, {round(seconds * 1000)} ms", file=sys.stderr)
    return 0


def blocks(lines: list[str], target: int = 40, hard: int = 80) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []
    start = 0
    for end in range(1, len(lines) + 1):
        size = end - start
        following = lines[end] if end < len(lines) else ""
        top_level_start = (not lines[end - 1].strip() and following.strip()
                           and len(following) - len(following.lstrip()) <= 4)
        if end == len(lines) or size >= hard or (size >= target // 2 and top_level_start):
            spans.append((start, end))
            start = end
    return spans


def cmd_locate(args: argparse.Namespace) -> int:
    lines = Path(args.file).read_text(errors="replace").splitlines()
    if not lines:
        print(f"jev locate: {args.file} is empty", file=sys.stderr)
        return 0
    spans = blocks(lines)
    scores: dict[int, float] = {}
    tokens = 0
    seconds = 0.0
    group: list[int] = []
    size = 0

    def score(members: list[int]) -> None:
        nonlocal tokens, seconds
        state = {"task": args.task, "file": args.file,
                 "blocks": {f"b{k}": f"lines {spans[k][0] + 1}-{spans[k][1]}:\n"
                            + "\n".join(lines[spans[k][0]:spans[k][1]])[: args.block_chars] for k in members}}
        questions = {f"b{k}": {"type": "noul", "instructions": f"Does block b{k} contain the code or text that answers the task?"}
                     for k in members}
        answers, used, took = run({"state": state, "questions": questions})
        tokens += used
        seconds += took
        scores.update(noul_scores(answers, questions))

    for k, (first, last) in enumerate(spans):
        cost = min(args.block_chars, sum(len(line) + 1 for line in lines[first:last])) + 80
        if group and size + cost > args.chunk_chars:
            score(group)
            group, size = [], 0
        group.append(k)
        size += cost
    score(group)
    ranked = sorted(scores, key=lambda k: -scores[k])
    kept = [k for k in ranked if scores[k] >= args.threshold][: args.top]
    for k in kept:
        first, last = spans[k]
        print(f"{args.file}:{first + 1}-{last}\t{scores[k]:.2f}\t{lines[first].strip()[:100]}")
    print(f"jev locate: {len(kept)}/{len(spans)} blocks (best score {scores[ranked[0]]:.2f}), "
          f"{tokens} input tokens, {round(seconds * 1000)} ms", file=sys.stderr)
    return 0


def cmd_usage(_: argparse.Namespace) -> int:
    calls = tokens = 0
    try:
        for line in USAGE_LOG.read_text().splitlines():
            entry = json.loads(line)
            calls += 1
            tokens += entry.get("input_tokens", 0)
    except OSError:
        pass
    print(json.dumps({"calls": calls, "input_tokens": tokens,
                      "estimated_usd": round(tokens / 1e6 * PRICE_PER_MTOK, 5), "log": str(USAGE_LOG)}))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="jev", description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    ask = sub.add_parser("ask", help="send {state, questions[, model]} JSON from a file or - for stdin")
    ask.add_argument("request")
    ask.add_argument("--full", action="store_true", help="print raw answers with full probability maps")
    ask.set_defaults(func=cmd_ask)
    filt = sub.add_parser("filter", help="keep only the stdin lines that are useful for --task, best first")
    filt.add_argument("--task", required=True, help="what the lines are being searched for")
    filt.add_argument("--top", type=int, default=15, help="keep at most this many lines (default 15)")
    filt.add_argument("--threshold", type=float, default=0.5, help="minimum usefulness 0-1 (default 0.5)")
    filt.add_argument("--scores", action="store_true", help="prefix each kept line with its score")
    filt.add_argument("--max-line", type=int, default=400, help="truncate each input line to this many chars")
    filt.add_argument("--chunk-chars", type=int, default=45000, help="input characters per request")
    filt.set_defaults(func=cmd_filter)
    locate = sub.add_parser("locate", help="rank the blocks of one large file for --task and print their line ranges")
    locate.add_argument("file")
    locate.add_argument("--task", required=True, help="what you need to find in the file")
    locate.add_argument("--top", type=int, default=3, help="print at most this many blocks (default 3)")
    locate.add_argument("--threshold", type=float, default=0.3, help="minimum score 0-1 (default 0.3)")
    locate.add_argument("--block-chars", type=int, default=1500, help="characters of each block sent to Jev")
    locate.add_argument("--chunk-chars", type=int, default=45000, help="input characters per request")
    locate.set_defaults(func=cmd_locate)
    usage = sub.add_parser("usage", help="print call count, input tokens and estimated spend")
    usage.set_defaults(func=cmd_usage)
    args = parser.parse_args()
    try:
        return args.func(args)
    except (JevError, json.JSONDecodeError, OSError) as error:
        print(f"jev: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
