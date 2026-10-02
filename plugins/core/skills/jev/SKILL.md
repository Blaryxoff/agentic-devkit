---
name: devkit-jev
description: >-
  find the right lines in a large file or rank bulky output with Jev, a typed-decision model (choice,
  score, yes/no probability; no prose). Use when you need one place in a file over about 500 lines that no keyword
  pins down, when ordering a long grep or log by relevance before reading it, or when classifying many items in
  one call. Invoke on "ask jev". Not for writing text, arithmetic, or judging a few lines already in context.
---

# Jev

Jev (TypeSafe System One) answers typed questions about a `state`: `choice` picks one named option with a
probability per option, `score` places the state on an ordered scale of at most 10 levels, and `noul` returns
the probability of yes. It writes no text. A call takes 0.5-3 s and costs a fraction of a cent.

```
JEV="$DEVKIT_HOME/plugins/core/skills/jev/scripts/jev.py"
```

Jev pays only when you give it a precise question. Write `--task` as the exact thing you are looking for, not as
the purpose of the command.

## Locate inside a large file

When you need one place in a file longer than about 500 lines and grep returns nothing or dozens of hits, rank
the file's blocks instead of reading the whole file:

```bash
"$JEV" locate app/Services/Billing.php --task "where is a failed renewal retried?"
```

- Output: `path:start-end<TAB>score<TAB>first line of the block`, best first, at most `--top` (default 3).
- Read the returned ranges in order with an offset and limit, and stop once you have the answer. The first line
  is the block's start, not necessarily the matching symbol.
- No output with a low best score: the answer is probably not in this file. Search elsewhere before reading it.

## Order bulky output before reading it

`filter` scores each input line against `--task` and prints the best lines first:

```bash
grep -rn "retry" src | "$JEV" filter --task "where are HTTP 429 responses retried?" --scores --top 30
```

- It orders output; it does not replace reading it. It misses the answer line about a third of the time.
- Read the top lines first. If they do not answer the task, narrow the search or read the rest.
- When `filter` returns nothing, broaden the search or read the original output before concluding the answer is absent.
- Keep options: `--top` (default 15), `--threshold` (default 0.5), `--scores`.

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
- Counting, arithmetic, dates or exact matching. `grep -F` on a literal string beats it.
- A decision about a few lines already in your context. Deciding it yourself is cheaper than the call.
- Choosing models, skills or conduct docs, checking browser pages against a reference, or filtering output
  automatically. Each was measured as no better than the current approach; the evidence is in
  `references/benchmarks.md`, which you read only before proposing a new Jev use.
- Anything holding secrets. Every call sends the state to TypeSafe. Never pipe `.env` files, key files,
  credential output or customer data.

## Failures

`jev: no API key`, an HTTP error, or `request failed` (no network, for example a read-only sandbox): proceed
without Jev and mention it once. The script already retries 429 and 5xx.

Configuration: the key is read from `JEV_API_KEY` or `~/.config/jev/typesafe-key`. `JEV_BASE_URL` and
`JEV_MODEL` override the endpoint and the pinned model (`jev-1.13.0`).
