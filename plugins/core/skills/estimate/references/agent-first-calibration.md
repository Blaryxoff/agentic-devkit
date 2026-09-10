# Agent-first calibration sources

Re-fetch these pages before citing them. Use them to calibrate maturity levels and decomposition; never derive a fixed
"AI acceleration factor" from them. Local high-context delivery evidence remains primary.

Dates below are the source's own publication or last-updated date as verified on 2026-09-10.

## Vendor delivery case studies

### Nursa / Lovable

- Source: <https://lovable.dev/blog/how-nursa-built-a-new-product-in-48-hours-and-changed-how-its-entire-company-ships-software>
- Date: July 1, 2026.
- Reported result: one weekend produced an interactive shift scheduler, student and admin portals, and a credentials
  dashboard; "two weeks turning Nursa for schools into an enterprise-grade product" followed.
- Use for: separating a demo weekend from the hardening that follows it, as two independently evidenced windows.
- Do not use for: a demo-to-production ratio, multiplier, or hardening-tail factor of any kind. This is a
  vendor-authored story about a greenfield product built from nothing; it carries no information about a scope that is
  already largely implemented.

### Flash News / Replit

- Source: <https://replit.com/blog/building-mobile-apps-on-replit>
- Date: February 20, 2026.
- Reported result: the builder could "sketch an idea in the morning… and have a clickable version in Replit later that
  day"; the toolchain "made it feel realistic to go from idea to TestFlight in a weekend."
- Use for: calibrating small, focused demo outcomes only. Both statements describe a workflow's feel, not a measured
  delivery window for that app — do not restate either as a timed result.
- Do not use for: estimating complex authorization, financial, migration, moderation, or multi-client work.

### Lovsight / Lovable

- Source: <https://lovable.dev/blog/how-one-data-scientist-enabled-a-150-person-org-with-a-single-lovable-app>
- Date: June 3, 2026.
- Reported result: "the agent built the core functionality in just a couple of prompts"; about half the company was
  using it within a few weeks, reaching roughly 90% adoption over subsequent weeks.
- Use for: separating code generation from adoption, integration, and operational maturity.
- Do not use for: replacing project-specific delivery evidence. This is a vendor-authored success story.

## Operator and autonomy model

### Anthropic: Claude Code expertise

- Source: <https://www.anthropic.com/research/claude-code-expertise>
- Date: June 16, 2026. Dataset: ~400,000 interactive sessions from ~235,000 people, October 2025 to April 2026.
- Reported pattern: "people make about 70% of the planning decisions but only 20% of the execution decisions." Greater
  domain expertise is associated with more agent work per instruction and easier error recovery. The share of sessions
  spent debugging fell from 33% to 19% over the period.
- Use for: keeping operator planning, review, and recovery time on the schedule.
- Do not use for: inferring a concurrency factor, a causal productivity uplift, or autonomous execution.

### METR: task-completion time horizons

- Source: <https://metr.org/time-horizons/>
- Date: updated May 8, 2026.
- Reported pattern: "AI agents are typically several times faster than humans on tasks they complete successfully," on
  a suite of self-contained, well-specified software tasks.
- Reliability note: "Measurements above 16 hrs are unreliable with our current task suite."
- Use for: decomposing long lanes into short, verifiable tasks and widening uncertainty for oversized or coupled lanes.
- Do not use for: multiplying a traditional person-day estimate by a universal speed factor.

## Measured productivity and its limits

### METR: experienced open-source developer RCT

- Source: <https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/>
- Date: July 10, 2025.
- Reported result: 16 experienced developers on 246 real issues in repositories they knew took 19% longer with early-2025
  AI tools (CI +2% to +39%), while believing afterwards that AI had sped them up by 20%.
- Use for: guarding against perceived-speed anchoring; keeping prompting, review, and correction overhead in the lane.
- Do not use for: a current multiplier. It measures early-2025 tooling.

### METR: developer-productivity experiment update

- Source: <https://metr.org/blog/2026-02-24-uplift-update/>
- Date: February 24, 2026.
- Reported result: late-2025 raw time change was -18% (CI -38% to +9%) for returning participants and -4% (CI -15% to
  +9%) for new ones. METR calls the current productivity estimate unreliable: 30% to 50% of developers declined to
  submit tasks they did not want to do without AI, and concurrent-agent time reporting was unreliable.
- Use for: reporting ranges instead of false precision; separating aggregate agent runtime from operator elapsed time.
- Do not use for: asserting one measured universal uplift in either direction.

### DORA: State of AI-assisted Software Development 2025

- Source: <https://cloud.google.com/blog/products/ai-machine-learning/announcing-the-2025-dora-report>
- Date: September 24, 2025. Sample: nearly 5,000 technology professionals.
- Reported pattern: 90% of respondents use AI at work and over 80% believe it raised their productivity, while 30%
  report little or no trust in AI-generated code. AI amplifies an organization's existing strengths and weaknesses.
- Use for: treating AI assistance as the delivery baseline. A person-day figure produced by an AI-assisted team already
  contains the acceleration; do not apply a further multiplier to it.
- Do not use for: a throughput or change-failure number — those live behind the full report, not this page.

## Parallel-agent and rework cost

### Concurrent agent pull requests and merge conflicts

- Source: <https://arxiv.org/abs/2607.04697>
- Date: July 6, 2026. Dataset: AIDev-pop, 33,596 agent-authored pull requests across 2,807 repositories.
- Reported result: 40.2% of repositories had temporally overlapping agent PR pairs (53.4% within a one-week window),
  covering 79.4% of all agent PRs. Textual conflict rate was 19.8% for same-agent pairs and 41.7% for cross-agent
  pairs; 84.4% of conflicts were in source files rather than dependency manifests.
- Use for: pricing one merge/contract-reconciliation gate on the specific lanes that actually touch the same files or
  schema. Lanes with disjoint ownership carry no such cost.
- Do not use for: capping the number of lanes by itself; local file ownership and schema coupling decide that.

### Reviewer involvement in merged agent pull requests

- Source: <https://arxiv.org/abs/2605.22534>
- Date: May 21, 2026. Dataset: 11,048 closed agentic PRs, 9,799 human-reviewed, 717 manually inspected.
- Reported result: 15.4% of merged PRs required explicit reviewer feedback or direct commits. Only 35.7% of rejections
  reflected clear agent failure; 31.2% were workflow constraints.
- Use for: keeping one integration/review gate per lane in the schedule; not reading a rejected branch as wasted work.
- Do not use for: estimating implementation duration.

### GitClear: The Maintainability Gap

- Source: <https://www.gitclear.com/the_ai_code_quality_maintainability_gap>
- Date: January 2026. Dataset: 623 million analyzed changes, 2023 to 2026.
- Reported result: refactoring fell to 3.8% of changes year-to-date 2026 (from 21% in 2022), block duplication rose 81%
  over 2023, copy/paste reached 15.7% in the first half of 2026 (from 9.4% in 2022), and churn rose 15%.
- Use for: pricing a named dedup/refactor gate between alpha and production when the code under change is itself
  agent-written and unrefactored. Never as a tail proportional to the build.
- Do not use for: a speed factor. GitClear authors this research and sells the analytics product that measures these
  signals — label it vendor-authored.

## Application rules

1. Never multiply, scale, or apply a percentage from this page to an estimate. Every source here either prices one
   named gate in the schedule or widens a stated range. A source that cannot be attached to a specific gate does not
   enter the estimate.
2. Do not calibrate a scope classified mostly `exact`, `continuation`, or `foundation` from this page at all. Every
   source below measures new or greenfield work; local anchor evidence governs a scope that is already largely built.
3. Cite the exact source and the narrow fact used.
4. Label vendor case studies as vendor evidence.
5. Pair web evidence with at least one local implementation or throughput analogue whenever available.
6. Use demo case studies to calibrate demo/alpha only.
7. Use the rework sources to add named hardening gates to beta/production, each carrying its own low/likely/high
   window. Never express them as a percentage or factor over the implementation total.
8. State the source date or retrieval date when the estimate is time-sensitive.
9. Replace or remove a source when the page is unavailable, materially changed, or superseded by stronger evidence.
