---
name: devkit-jev
description: >-
  filter, rank and triage with Jev, a sub-second typed-decision model (choice, score, yes/no probability; no
  prose). Use before reading a grep, log or file listing over about 100 lines, when picking files to open, or
  when classifying many items at once, instead of reading it all or spawning an exploration subagent. Invoke
  on "ask jev". Not for writing text, arithmetic, or judging a few lines already in context.
---

# Jev

Jev (TypeSafe System One) answers typed questions about a `state`: `choice` picks one named option with a
probability per option, `score` places the state on an ordered scale of at most 10 levels, and `noul` returns
the probability of yes. It writes no text. A call takes about 0.5 s and costs about $0.00002 per 500 input tokens.

```
JEV="$DEVKIT_HOME/plugins/core/skills/jev/scripts/jev.py"
```

## Filter before you read

Pipe large output through `filter` and read only what it keeps. The full output never enters your context.

```bash
grep -rn "retry" src | "$JEV" filter --task "where are HTTP 429 responses retried?"
git ls-files | "$JEV" filter --task "which files implement the Codex adapter?" --top 5
git log --oneline -300 | "$JEV" filter --task "which commit changed how sessions expire?" --top 5
```

- `--task` names what you are looking for, as a specific question. A vague task keeps vague lines.
- Output: kept lines best first, verbatim. stderr reports `kept K/N lines (best score S)`.
- Nothing kept with a low best score means the input most likely does not contain the answer. Change the search.
  If you still suspect a miss, rerun with `--threshold 0.2 --scores` before reading the raw output.
- Add `--scores` to see each line's probability. Tune with `--top` (default 15) and `--threshold` (default 0.5).
- Input over one request's budget is split into several requests automatically.
- Kept lines are leads. Open the file at the kept location before you rely on it.

## Locate inside a large file

When you need one place in a file longer than about 500 lines and no keyword pins it down, rank its blocks instead
of reading the whole file:

```bash
"$JEV" locate app/Services/Billing.php --task "where is a failed renewal retried?"
```

- Output: `path:start-end<TAB>score<TAB>first line of the block`, best first, at most `--top` (default 3).
- Read only the returned ranges, e.g. with an offset and limit. The first line is the block's start, not
  necessarily the matching symbol.
- No output with a low best score: the file most likely does not contain it.
- A keyword that grep finds in a handful of lines is still cheaper; use `locate` when grep returns nothing or
  dozens of hits.

## Ask typed questions

For judgments over many items — triage 40 failing tests by cause, rank candidate approaches, check a diff
against a rubric — write one request and put every question in it. One call answers all of them.

```bash
"$JEV" ask - <<'JSON'
{"state": {"diff_summary": "..."},
 "questions": {
   "area": {"type": "choice", "instructions": "Which area does this change touch?",
            "criteria": {"auth": "login, sessions, permissions", "billing": "payments, invoices", "other": "anything else"}},
   "risky": {"type": "noul", "instructions": "Could this change lose or corrupt stored data?"}}}
JSON
```

- Put the facts the decision depends on in `state`. Padding lowers accuracy.
- Phrase each question positively and directly. No double negatives.
- Give every `choice` option and `score` level a short meaning, not just a label.
- Treat probabilities as a ranking signal. Before acting automatically on a threshold, check it against real cases.
- `--full` prints the raw probability maps. `usage` prints calls, tokens and spend so far.

## Do not use Jev for

- Writing, summarizing or explaining anything. It returns no text.
- Counting, arithmetic, dates or exact matching. Keep those in code or `grep`.
- A decision about a few lines already in your context. Deciding it yourself is cheaper than the call.
- Picking a subagent's model tier, deciding which skill to activate, or choosing conduct docs. Measured
  against the agent's own choice, the static tier rule and the conduct routing tables, Jev was not better.
- Anything holding secrets. Every call sends the state to TypeSafe. Never pipe `.env` files, key files,
  credential output or customer data.

## Failures

`jev: no API key` or any HTTP error: proceed without Jev, reading the output the normal way, and mention the
failure once. The script already retries 429 and 5xx.

Configuration: the key is read from `JEV_API_KEY` or `~/.config/jev/typesafe-key`. `JEV_BASE_URL` and
`JEV_MODEL` override the endpoint and the pinned model (`jev-1.13.0`).
