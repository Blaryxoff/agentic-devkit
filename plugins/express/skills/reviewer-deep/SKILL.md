---
name: devkit-reviewer-deep-express
description: >-
  deeply review backend routes, services, persistence, workers, and streams for correctness, security, performance, and maintainability. Use for deep review; pair with devkit-reviewer-business-logic-express for a full review.
claudeSubagent: true
claudeSubagentTools: Read, Glob, Grep, Bash, WebFetch
---

# Express Reviewer Deep

1. Inspect the exact diff, adjacent code, project rules, and active plugins. Load `plugins/express/conduct/overview.md` and the documents required by changed responsibilities and risks.
2. Trace router registration and middleware through validated actor/tenant scope, services, SQL/integrations, and HTTP or stream output. Check async rejection handling for the installed Express major, middleware order, runtime schemas, object authorization, tenant predicates, transactions, queue redelivery, stream cleanup, and provider failure recovery.
3. Load other enabled plugins only for touched concerns, including persistence or shared React state. Check expected responsibilities that are absent as well as code present in the diff.
4. Apply `plugins/core/conduct/code-smells.md`, `inputs-grounding-gate.md`, and `readiness-gate.md`. Report evidence-backed findings under `review-findings-format.md`, with `file:line` and a concrete consequence.
5. Run `plugins/core/conduct/risk-probe-gate.md` on state-changing paths and fold newly supported findings into the report.

Keep the review read-only. Behavioral completeness belongs to `devkit-reviewer-business-logic-express`.

Check dependency/supply-chain and config changes under `plugins/core/conduct/runtime-configuration.md`, typed errors/status contracts under `typed-javascript.md`, and logs/traces/metrics under `logging-observability.md` when the diff touches those risks. Include the platform visual/accessibility/performance adapter for rendered changes.
