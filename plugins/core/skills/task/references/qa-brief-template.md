# QA brief template

The peer agent runs browser QA in a fresh context with an isolated browser profile. It has your repository and nothing
else: not your session, not your cookies, not what you already clicked. Every section below exists because omitting it
sent a real run into a wall.

Write agent-facing technical instructions in English, fill every section, and delete nothing. Preserve exact product
copy, user-provided literals, URLs, and commands in their source language because the peer must verify them verbatim.

---

```markdown
# Browser QA: <feature>

Test the local environment in a real browser. You are the QA reviewer; return findings and leave code unchanged. For
every item, return `passed | failed | blocked` and identify skipped/missing coverage with reasons. Follow
`plugins/core/conduct/runtime-qa-evidence.md` §§1–3 and applicable `browser-qa-rules.md` sections. Collect structured evidence
in this order: accessibility snapshot identity, DOM/layout audit, console/network
result, existing Playwright Test assertion/diff, then a saved screenshot crop only for a design comparison or confirmed
visual finding. Attach screenshots only for design comparisons or confirmed visual findings.

## Environment

- Frontend: **<url>** (<why this host and not localhost — proxy, API base, CORS>).
- Backend: <url>, repository <path>.
- Evidence pins: <repository revision and independently deployed frontend/API/worker revisions, relevant configuration
  and module/entry-point readiness; unknown identity at each unavailable boundary; browser engine/profile>.
- Dev server is already running / start it with: <command>.
- Known environment signatures: <observed symptom and evidence supporting a setup/environment cause; capture the first
  failure, verify that cause before recovery, and retain all retry outcomes under browser-qa-rules.md §7.5>.
- **Deferred work runs immediately:** <queue driver, e.g. QUEUE_CONNECTION=sync; identify timeout-driven statuses that
  therefore look different locally>.
- Console/artisan: <exact command>.
- Revision checks: <available component/configuration signals checked before/after the lane, between waves and before
  acceptance; reuse or invalidate only affected evidence under runtime-qa-evidence.md §2>.

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

## Already verified — reuse only with matching evidence

<For each reusable case: criterion/source and scope; original run ID/time; execution method and actual engine/device;
component/configuration, role/tenant and fixture IDs/state; action, expected and observed result, outcome and evidence
reference. Share matching pins by reference. State why evidence remains valid or which dependency invalidated it.>

<Missing source/method/build/role/fixture/evidence pins leave prior claims unusable for acceptance. Keep unknowns explicit
and recheck the affected case when possible. A report edit, screenshot or code inspection is not a new runtime run.>

## Checks

### 1. <area>

<Route(s). Exact expected string in quotes — "Комментарий для врача по адресу", not
"the updated hint". A string the peer must match exactly cannot be paraphrased.>

<Stable case and criterion/source IDs; actor, fixture state, implementation variant and method; action and expected
visible, persisted and side-effect outcomes. Challenge missing applicable scenarios under browser-qa-rules.md §4.12
before execution; load output/device references only for assigned risks.>

<Name the negative case too: what must NOT have changed elsewhere.>

### 2. <area>

<...>

### N. <access control>

<Map applicable actor × operation × resource/state cases, including allowed actors and alternate write paths. For
every new route reading someone's data, use the proven foreign fixture: assert its sourced route/API denial contract,
no protected response data, and no disallowed persisted changes or side effects.>

## Response format

Return each case record under runtime-qa-evidence.md §3 with `passed | failed | blocked`, source/run/method/pin references,
observed evidence, cause, cleanup and reuse/invalidation reason. List skipped/missing checks as coverage gaps and retain
individual suite skips and expected failures. For failures include expected versus observed result and reproduction
steps; a successful retry does not erase an earlier failure. Save screenshots only for a design-reference comparison or
confirmed visual defect. Report styling/design findings only when in scope; test the named items and report omissions.
```

---

## Section notes

| Section | Why it is mandatory |
|---|---|
| Stand URL + why | A dev server reachable on two hosts fails silently on the wrong one (API base derived from host). |
| Environment signatures and revisions | Verify setup causes and component drift without erasing the first failure or combining incompatible builds. |
| Queue driver | A synchronous queue runs delayed listeners inline, so timeout-driven state (auto-cancel, expiry, reminders) lands the instant a record is created. The peer sees a "wrong" status and files a major defect against untouched code. |
| Data preconditions | A scenario that needs a bookable slot, a second account, or a published entity comes back BLOCKED without them — and BLOCKED items cost a second full QA run. |
| Auth recipe | Local codes never leave the machine. The peer cannot guess which log line holds them. |
| Already verified | Reuse matching evidence without promoting an unsupported old claim to a fresh runtime result. |
| Exact expected strings | A copy change is only verifiable character by character. |
| Negative cases | A rename that also hit the wrong surface passes a positive-only check. |
| Access-control probe | Cover allowed and denied operations, foreign data and alternate routes against the sourced contract. |
| Response format | Keeps the report triageable instead of narrative. |

## Invocation

Launch the peer with a sandbox that permits browser control, and point it at the brief by path so both agents use the
same source.

Flags, stdin handling (`< /dev/null`), and failure modes: `plugins/core/conduct/cross-agent-review.md` →
"Peer CLI invocation".
