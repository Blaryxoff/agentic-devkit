---
name: devkit-quota
description: >-
  Plan Codex quota, expiring credits and manual resets. Use for "reset strategy", "when to use my reset",
  "стратегия лимитов" or "когда сбросить квоту". Produces dated recommendations; does not redeem resets or buy usage.
---

# Quota

Recommend when to redeem an existing manual reset from current account evidence, refreshed public history and the
person's actual usage pattern. Run read-only; recommend an action without redeeming, purchasing or changing settings.

## 1. Collect the account first

Read [sources.md](references/sources.md). Resolve the actual current timestamp, user's timezone and intended account.
Refresh the authorized quota surface before researching history. Report:

- plan and workspace; included windows with used/remaining percentages and next refresh timestamps;
- credit balances by grant and expiry, including unknown expiry timezone or mixed grants;
- each existing reset's type, applicable allowance, grant time and redemption deadline;
- collection time, source and any stale, conflicting or inaccessible fields.

Inspect authorized normal sign-in paths when required. Ask only for facts the available sources cannot establish.
Treat screenshots as dated evidence; distinguish token/file expiry from subscription or credit expiry.
Apply explicit user preferences, including ignoring future reset grants. Default to preserving useful capacity and
avoiding an early manual reset superseded by a general reset; use expiring credits as a buffer when sufficient.

## 2. Refresh and reconcile public history

Refresh up to 180 complete days, even when a previous report already contains numbers. Target the full 180-day
window; disclose shorter source retention and the actual observed span rather than filling gaps with zero events.
Maintain the public-only cache and provenance defined in [sources.md](references/sources.md); record fetch failures.
Separate delivered automatic resets from banked grants, paid redemptions, ordinary refreshes, allowance increases,
announcements and unknown events. Consolidate announcement, rollout and completion into one canonical event.
Verify eligibility for this plan where known. A tracker label saying "all users" does not establish account coverage.
Retain corrections and unresolved conflicts. Missing records are not evidence that nothing happened.

Run the bundled calculator after updating the cache:

Set `SKILL_DIR` to this loaded skill's directory, `QUOTA_CACHE` to the public cache directory in
[sources.md](references/sources.md), `QUOTA_RUN` to a private scratch directory, and `QUOTA_TZ` to the resolved IANA
timezone. Set `QUOTA_PLAN` to the normalized plan family and refresh `QUOTA_NOW` to an aware ISO timestamp after the
history fetch, at least as recent as `updated_at`. Create the cache/run directories before writing their files.

```bash
python3 "$SKILL_DIR/scripts/history.py" --history "$QUOTA_CACHE/history.json" \
  --as-of "$QUOTA_NOW" --plan "$QUOTA_PLAN" --days 14 30 60 90 180 --horizon-hours 24 48
```

Keep personal account snapshots and reports outside the repository.

## 3. Update the usage pattern

Read [usage.md](references/usage.md). Collect the latest 14 complete local days plus today separately; compare the last
seven complete days with the longer period. Collect account consumption history or trustworthy balance snapshots too.

```bash
python3 "$SKILL_DIR/scripts/usage.py" --as-of "$QUOTA_NOW" --timezone "$QUOTA_TZ" \
  --days 15 --out "$QUOTA_RUN/usage.json"
```

Use other authorized agent sources only when they materially fill a coverage gap. Report source coverage and distinguish
human availability from autonomous compute. Derive burn rates only from reconciled account consumption; never convert
prompt hours or stale rollout balances into credit charges.

## 4. Compare redemption choices

Apply [method.md](references/method.md). Compare redeeming now, the next substantial working session, one bounded wait
and the last useful session before expiry. Add a candidate after an ordinary refresh only when remaining working time
can realistically consume enough of that allowance before redemption. Follow the current offer's eligibility rules.

For each viable choice, show the intervening credit requirement when measurable, expected useful refill, affected
ordinary refresh and collision risk over the time needed to use the refill. Unknown burn rates stay unknown.
Exclude future manual grants when requested. New banked grants alone do not supersede the current allowance.
Choose one practical action and an exact review time; specify what observed event changes that action.
Refresh account state again if analysis took long enough for an allowance, deadline or balance to change materially.

## 5. Return a short decision

Lead with "use the current reset now" or "use credits until [local date/time], then [condition]". Include:

- a timestamped account snapshot and the existing reset's exact redemption deadline;
- monthly and 60/90/180-day automatic-reset counts, plus recent-window sensitivity;
- changing cadence from nonoverlapping recent/prior months and recency-weighted estimates, with assumptions;
- 24/48-hour probability scenarios, their assumptions and coverage limits;
- observed usage pattern, the recommended redemption window and one fallback before expiry.

Name third-party trackers as independent archives and link supporting source posts or official rules when available.
Call a checkpoint a checkpoint, not a statistically safer day. Keep recommendations in the user's language.
Never invent a precise forecast, promise that a global reset will cover the account, or manufacture work to consume
benefits. Stop collecting once new evidence is unlikely to change the decision.
