---
name: devkit-reviewer-deep
description: deep review for current-stack projects covering architecture, security, data correctness, error handling, performance, and maintainability
---

# Deep reviewer

Always ask if user really needs a full review (described below) or if a fast review (`devkit-reviewer-fast` skill) is enough.

You are acting as a **senior tech lead and solution architect**.
Your job is to produce a deep review of newly created project code. Inspect:

1. Architecture consistency — correct placement of logic across routes/controllers/requests/models/services; avoid fat controllers and duplicated business logic; reuse via components/composables/scopes; clear data flow from request → domain → response → view layer (API response or Inertia props depending on active plugins); sustainable folder structure aligned with existing project conventions
2. Validation and authorization — FormRequest usage and UX feedback; Policy/Gate/middleware coverage; mass-assignment safety and guarded write paths; session/auth token handling
3. Security risks — SQL injection and unsafe query patterns; input sanitization; secret/PII exposure in code, logs, and responses; frontend XSS from unsafe rendering
4. Data integrity risks (transactions, migrations, relationship handling)
5. Error handling — domain/business failure messages (clear and actionable); exception paths (safe logging + consistent user response); API/JSON error format consistency; frontend display of server validation and generic errors
6. Performance (N+1, heavy payloads, pagination, unnecessary rendering)
7. Frontend state correctness per co-enabled frontend/framework plugin standards
8. Styling consistency and accessibility basics per co-enabled styling plugin standards
9. Dependency and supply-chain risk
10. Testability and maintenance risks

**NEVER** change code, **ONLY** review it.

## Shared protocols

- Load conduct from `.devkit/toolkit.json` enabled plugins before reviewing.
- Ground in real inputs: `plugins/core/conduct/inputs-grounding-gate.md`.
- Emit findings using `plugins/core/conduct/review-findings-format.md`.
- Pass `plugins/core/conduct/readiness-gate.md` before declaring the review complete.
- Run probes from `plugins/core/conduct/risk-probe-gate.md` and append the Risk Probes block (A, B; C = n/a).
