# Evidence and cache

## Live account

Prefer a purpose-built read-only account capability, then the user's authorized usage page or quota manager.
For Codex app-server clients, inspect the installed version's schema before using `account/rateLimits/read`.
Refresh once and read the resulting state; never call `account/rateLimitResetCredit/consume` during this workflow.
Use an existing normal login session; do not extract credentials or replay an undocumented authentication flow.

When the user uses a quota manager, read its current authorized UI and refresh only the quota information.
Read allowlisted response fields if required to disambiguate the display: plan, allowance windows, credit balances,
reset details and response time. Never print raw network requests, headers, cookies or full account responses.
Interpret `used_percent` as used, not remaining. Identify each window by its duration or ID, not array position.
Keep an absent window absent; do not assume every plan has both a five-hour and weekly window.

Verify current semantics before recommending redemption. Start with official OpenAI documentation:

- [Codex reset rules](https://help.openai.com/en/articles/20001498-how-resets-work-in-codex)
- [Personal usage credits](https://help.openai.com/en/articles/12642688-using-credits-for-flexible-usage-in-chatgpt-personal-plans)
- [Codex pricing and limits](https://learn.chatgpt.com/docs/pricing)
- [App-server account methods](https://learn.chatgpt.com/docs/app-server)

Check the offer/account for redemption eligibility, covered allowances, expiry timezone and effects on regular refreshes.
Do not freeze today's plan names, thresholds, promotions or reset rules into future advice.

## Public events

Find the source announcement and, separately, evidence of actual delivery. Current discovery examples include
[@thsottiaux](https://x.com/thsottiaux), official OpenAI posts/release notes, and independent archives:
[Codex Limits](https://codexlimits.com/reset-history), [Codex Reset](https://codex-reset.com/timeline),
[When Next Reset](https://whennextreset.com/history), [ResetPing](https://reset-ping.com/resets/).
These are discovery paths, not a provider API contract or interchangeable sources of truth.

Open the matched records; do not rely only on search snippets, headlines, "reset today" badges or published odds.
Follow pagination through the requested window. Compare classifications with actual source wording.
Treat a banked-reset announcement mislabelled as an automatic reset as a correction, not another event.
Do not count archives sharing one upstream feed as independent confirmations.
State when original retrieval failed and which archive preserves the evidence; respect blocked-action tool rules.
Keep date precision and timezone uncertainty, especially when announcement and delivery fall on different days.

## Cache contract

Use `${XDG_CACHE_HOME:-$HOME/.cache}/agentic-devkit/quota/codex/history.json` for public history by default.
Use a separate private scratch directory for account and activity aggregates. Honor the user's chosen destination.
Create parent directories on demand; no service, scheduled refresh or deployment is required.

Read the existing cache, fetch updates plus the preceding event for boundary reconciliation, then merge by canonical
semantic event ID. Preserve source links; correct misclassifications explicitly. Re-fetch older missing months when
coverage is shorter than 180 days. Validate the merged document before replacing the old cache atomically.
Advance `updated_at` only after a successful refresh; keep failed feeds and coverage gaps in `notes`.
With unavailable sources, retain the previous cache, report its age and label the result stale.

Use this JSON shape (dates below illustrate a synthetic event, not a current grant):

```json
{
  "provider": "codex",
  "updated_at": "2000-04-01T12:00:00Z",
  "coverage": {"start": "2000-01-01", "end": "2000-04-01", "complete": false, "gaps": []},
  "notes": ["Independent archives may omit events"],
  "events": [{
    "id": "codex-2000-03-28-main",
    "kind": "automatic",
    "status": "observed",
    "effective_at": "2000-03-28T06:29:00Z",
    "announced_at": "2000-03-28T02:42:00Z",
    "plans": ["pro"],
    "scope": "main",
    "source_urls": ["https://example.org/synthetic-record"]
  }]
}
```

- Set `coverage.start` inclusive and `coverage.end` exclusive, using UTC dates actually surveyed.
- Set `complete` false unless completeness is established; a tracker calling itself complete is insufficient.
- Record known unsurveyed intervals in `coverage.gaps` as inclusive `start`/exclusive `end` UTC dates within coverage.
  The calculator excludes those dates from event counts and exposure instead of treating them as event-free days.
  Unknown omissions within a surveyed archive still require `complete: false` and explicit uncertainty.
- Normalize `kind` to `automatic | banked | paid | allowance_change | scheduled | unknown`.
- Normalize `status` to `announced | observed | confirmed | retracted`; only delivered automatic events count.
- Set `effective_at` to delivery time, or an ISO UTC date if only the delivery date is established.
- Keep `effective_at` null for announcement-only events; a promised deadline is not a delivery timestamp.
- Set `plans` to normalized eligible families such as `plus`, `pro`, `business`; use an empty list for unknown scope.
- Set `scope` to `main | model | feature | unknown`; keep unverified scope explicit.
- Retain one event per actual reset, including announcement and completion links; deduplicate date variants of one rollout.
- Keep restricted/model/feature resets separate. Do not silently treat unknown eligibility as confirmed applicability.
- Store public facts only: no user identity, account IDs, balances, authentication, transcripts or private URLs.
