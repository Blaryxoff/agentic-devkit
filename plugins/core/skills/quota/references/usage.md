# Human availability and account consumption

Use the bundled `scripts/usage.py` for local Codex activity. Set the actual timezone and an aware `--as-of` timestamp.
Fifteen local dates include 14 complete days plus today; compare the last seven complete days with all complete days.
Keep today separate from completed daily averages and clip modeled tails at the collection time.

Inspect the collector's coverage before using its estimates:

- Include recently updated older-start rollouts through the read-only Codex thread index when available.
- Report date-folder fallback and missing older-start sessions rather than treating missing activity as idle time.
- Exclude `codex_exec`, explicit subagent sources and parent-thread children regardless of originator.
- Exclude injected instructions, scheduled turns and peer protocols. Preserve human text following image wrappers.
- Deduplicate replayed human messages and union overlapping sessions; autonomous runtime creates no human hours.
- Report first/last prompt bounds as spans, not continuous work, and give gap/tail sensitivity rather than exact hours.

Compare weekday and weekend activity, usual first/last prompts, long-session frequency and likely work before each
candidate redemption time. Ask about upcoming time off only when it could change the choice.
Do not extrapolate one exceptionally busy week as a guaranteed schedule or prescribe longer workdays to consume credits.

Use [timesheet source discovery](../../timesheet/references/sources.md) and
[its human-anchor method](../../timesheet/references/method.md) when Claude, Cursor or remote sources materially fill
missing coverage. This is an availability estimate, not a billable timesheet: no client attribution, overhead allocation,
tracker crawl, calls investigation or PDF is required. Honor source privacy and read-only boundaries.
If adapting an existing collector, audit structured subagent metadata and older resumed files before trusting it.

Collect consumption independently from the account's authorized usage history, credited balance ledger or comparable
timestamped live snapshots. Separate included-allowance consumption from additional-credit consumption.
Reconcile resets, grants, corrections, expiry and concurrent activity before comparing endpoints.
Match account/workspace and allow for propagation delay; take another authorized live reading if it resolves ambiguity.
Credit fields inside rollouts can be stale, replayed, concurrent or from another account: they are not a spending ledger.
Human hours do not establish tokens, credits or the absolute size of a weekly allowance.

Validate the denominator before forecasting credit spend. Identify when credits actually paid for work, the included
allowance state, intervening refills and any idle time. Use measured credit-consuming time or comparable workloads to
estimate credit-only burn. Keep calendar totals descriptive when they mix included usage, reset coverage and credits;
dividing them by calendar days does not establish the cost of waiting while the allowance is exhausted.
Mark credit-only burn unknown when exposure cannot be isolated; collect a comparable exhausted-allowance session or
give conditional choices instead of declaring the bridge affordable. Exclude partial days from complete-day averages.
Treat an imminent user-reported burst as a separate workload scenario that can outweigh a smoothed historical average.
Label its cost as user-reported or estimated, preserve its timing, and do not spread it across idle or allowance-covered
days. Avoid converting that credit cost into a refill's capacity without comparable account evidence.

When reliable, report remaining balance divided by remaining calendar days and estimated active hours as planning
thresholds, explicitly distinct from measured burn. State that rates vary with model, reasoning, context, caching,
speed and autonomous/concurrent work. Verify current pricing only when a rate conversion changes the decision.
