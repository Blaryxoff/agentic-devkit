# QA brief template

The peer agent runs browser QA in a fresh context with an isolated browser profile. It has your repository and nothing
else: not your session, not your cookies, not what you already clicked. Every section below exists because omitting it
sent a real run into a wall.

Write agent-facing technical instructions in English, fill every section, and delete nothing. Preserve exact product
copy, user-provided literals, URLs, and commands in their source language because the peer must verify them verbatim.

---

```markdown
# Browser QA: <feature>

Test the local environment in a real browser. You are the QA reviewer and must not edit code. For every item return
PASS/FAIL with structured evidence in this order: accessibility snapshot identity, DOM/layout audit, console/network
result, existing Playwright Test assertion/diff, then a saved screenshot crop only for a design comparison or confirmed
visual finding. Do not open or attach passing screenshots.

## Environment

- Frontend: **<url>** (<why this host and not localhost — proxy, API base, CORS>).
- Backend: <url>, repository <path>.
- Dev server is already running / start it with: <command>.
- Known false failures: <e.g. 504 Outdated Optimize Dep → stale Vite dependency cache; reload once, then report if it persists>.
- **Deferred work runs immediately:** <queue driver, e.g. QUEUE_CONNECTION=sync; identify timeout-driven statuses that
  therefore look different locally>.
- Console/artisan: <exact command>.

## Data preconditions

<What the scenario needs to exist before the first click — free slots, an approved
profile, a second account, a published entity — and the exact command or SQL that
creates it. Without this a whole branch of the brief comes back BLOCKED.>

<For any foreign-data check: name the second account and the ID that belongs to it,
so ownership is proven rather than assumed.>

## Authentication

<Where the auth code actually lands locally — log file, mailhog, DB column — and the
exact steps to get from "code requested" to "logged in", including any post-login
interstitial to dismiss.>

<Which account to use, or how to create one.>

## Already verified — do not repeat

<Verbatim list of what you already verified yourself, with the result. Without this
the peer burns its run re-testing solved ground.>

## Checks

### 1. <area>

<Route(s). Exact expected string in quotes — "Комментарий для врача по адресу", not
"the updated hint". A string the peer must match exactly cannot be paraphrased.>

<Name the negative case too: what must NOT have changed elsewhere.>

### 2. <area>

<...>

### N. <access control>

<Every new endpoint or route that reads someone's data gets a foreign-id probe:
open it as another user, expect 403/redirect and no data on screen.>

## Response format

List every item as PASS/FAIL. For FAIL include observed result, expected result, reproduction steps, and the strongest
structured evidence. Save screenshots only for a design-reference comparison or confirmed visual defect. Do not critique
unscoped styling or design; test only the named items.
```

---

## Section notes

| Section | Why it is mandatory |
|---|---|
| Stand URL + why | A dev server reachable on two hosts fails silently on the wrong one (API base derived from host). |
| Known false failures | Stale bundler caches surface as application errors; without a note the peer files a bug against your code. |
| Queue driver | A synchronous queue runs delayed listeners inline, so timeout-driven state (auto-cancel, expiry, reminders) lands the instant a record is created. The peer sees a "wrong" status and files a major defect against untouched code. |
| Data preconditions | A scenario that needs a bookable slot, a second account, or a published entity comes back BLOCKED without them — and BLOCKED items cost a second full QA run. |
| Auth recipe | Local codes never leave the machine. The peer cannot guess which log line holds them. |
| Already verified | Prevents paying twice for the same coverage. |
| Exact expected strings | A copy change is only verifiable character by character. |
| Negative cases | A rename that also hit the wrong surface passes a positive-only check. |
| Access-control probe | New read endpoints are where IDOR lands; QA is the cheapest place to catch it. |
| Response format | Keeps the report triageable instead of narrative. |

## Invocation

Launch the peer with a sandbox that permits browser control, and point it at the brief by path — do not inline the
brief into the prompt, or the two copies drift.

Flags, stdin handling (`< /dev/null`), and failure modes: `plugins/core/conduct/cross-agent-review.md` →
"Peer CLI invocation".
