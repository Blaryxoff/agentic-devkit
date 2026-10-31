# Probability and recommendation

## Estimate the automatic-reset risk

Refresh 180 complete UTC days when sources permit, and report actual coverage for 60/90/180-day baselines. Exclude today's partial UTC day
from exposure and event counts; still show a confirmed delivery today as current news. Count one rollout once.
Show calendar months and recent 14/30-day windows so promotion-driven bursts remain visible.
Exclude explicit unsurveyed `coverage.gaps` from both events and exposure. Zero surveyed exposure produces unavailable
probabilities, not a zero-risk estimate. Flag partial recent/prior periods instead of claiming a full-month comparison.

Use `scripts/history.py` for the transparent baseline `lambda = event_count / observed_days` and
`P(at least one automatic reset within h hours) = 1 - exp(-lambda * h / 24)`.
Label this a constant-rate Poisson scenario, not a calibrated probability or official prediction.
The calculator also reports exact Poisson rate confidence bounds transformed to the horizon. Those bounds describe
sampling uncertainty under that same model; they do not cover missing events, eligibility or changing behavior.

Compare pooled and recent scenarios; do not select the window that supports a preferred recommendation.
Read the calculator's `recent_change`: it compares nonoverlapping recent/prior 30-day rates, marks incomplete comparisons,
and describes rising/falling cadence without claiming statistical proof of a regime change.
Read its `dynamic` estimates too: calendar-day weights decay with 14/30/60-day half-lives, including event-free observed
days in weighted exposure and excluding known survey gaps. Normalize the newest surveyed day's weight to one; this
constant scaling preserves the rate and prevents numeric underflow for short half-lives. This makes estimates react
to bursts and quiet periods instead of treating all
180 days equally. The model holds each current weighted rate constant over the forecast horizon; it does not predict
the date of the next reset. Treat half-life spread as sensitivity, not a confidence interval.
Compare those estimates with monthly and pooled rates before choosing a practical collision-risk range. Keep announced
campaign endings and outages as explicit contextual scenarios; recency alone does not prove causality or future persistence.
Separate observed facts from adjustments based on announcements, promotions, outages or new launches.
Explain any subjective adjustment and retain the unadjusted scenario alongside it; never invent a correction factor.
With sparse, stale or incomplete history, widen the practical uncertainty and lower confidence in the recommendation.
Zero observed events do not establish zero risk. The calculator's nonzero upper bound is useful, not a guarantee.

Distinguish a public automatic reset from one applicable to this account. Present known-eligible and unknown-scope
counts separately; use their difference as applicability sensitivity, not evidence that unknown events applied.
Check recent announcements for actual delivery before stating a reset is live. Do not import tracker odds blindly.

Do not call the allowance overdue or claim that waiting reduces the next day's risk: this model is memoryless.
Ending a promotion may change frequency, but historical averages cannot establish the new rate.
Use a short wait to observe events and preserve options; describe its purpose and cost explicitly.

## Compare useful capacity

Check current official/account rules each run. Distinguish redemption deadline from the lifetime of the refreshed
allowance. Where a reset tops an allowance up to 100%, only the consumed portion is recovered; the unused remainder
is not an additional refill. Where redemption restarts the period, the old scheduled refresh is replaced, not stacked.
Do not promise an exact new refresh timestamp before the provider reports it.

Estimate how long the person needs to consume the restored portion from comparable account usage and working
sessions. Use account percentage change per observed day/session where trustworthy; prompt counts alone are inadequate.
Calculate collision risk over that consumption horizon, not just over an arbitrary 24 hours.
An automatic reset after redemption only wastes the restored portion still unused; the useful work already done stays
useful. Do not equate a collision with losing the entire manual reset.

Compare at least these choices when feasible:

| Choice | Value to assess | Cost or risk to assess |
| --- | --- | --- |
| Redeem before the next long session | Immediate useful refill of a depleted allowance | Unused refill superseded by an automatic reset; changed ordinary schedule |
| Use credits for a bounded observation window | Preserve the reset while awaiting possible free capacity | Measured credit spend, expiry and no guarantee of lower later hazard |
| Redeem after the next ordinary refresh | Recover consumption since that refresh | Time available to consume the ordinary allowance before redemption deadline |
| Redeem at the last useful session | Preserve options longest | Missed redemption, low eligible usage and little remaining human availability |

Check credit grant expiry and remaining useful work before treating one credit as worth its purchase price.
Compare measured net credit burn after included usage with the balance and days until expiry. Exclude new grants,
refunds, expired grants and cross-account artifacts before deriving a rate. Missing measurements remain missing.
Credits projected to expire unused make a short wait cheaper; credits likely to run out favor earlier useful redemption.
Keep usage credits separate from cash, API credits and reset credits. Follow explicit user exclusions for future grants.

When consumption can be approximated as uniform, report the reset's expected useful fraction under this model as
`(1 - exp(-lambda * T)) / (lambda * T)`, where `T` is days needed to consume its restored capacity; use 1 for lambda=0.
Label uniform consumption and constant hazard as assumptions. Prefer actual scheduled working blocks when available;
do not apply this formula across idle nights as if work continued. Avoid converting it to credits without a valid rate.
If missing data prevent ranking candidates, give a conditional recommendation or ask for the one decisive measurement.

## Return a bounded action

State an exact local review time and the evidence that triggers redemption: still exhausted, beginning a substantial
session, no confirmed/announced imminent applicable automatic reset, and enough time before the existing deadline.
If a free automatic reset arrives, consume that allowance and reassess the old reset before its expiry.
Prefer the oldest eligible reset when multiple current resets cover the same allowance and the user has not excluded it.
Keep a practical deadline buffer based on the person's session times and access requirements; avoid last-minute timing.
Do not recommend consuming an entire fresh weekly quota in one or two days without usage evidence supporting it.
Avoid a fixed rule such as "wait until Monday" or "always use the earliest expiry": use current evidence and explain
the tradeoff. Recompute when account state, delivery evidence or the user's work schedule changes materially.
