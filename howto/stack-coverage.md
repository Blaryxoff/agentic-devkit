# Stack Coverage Against Laravel and Frontend

Use this map to audit applicable obligations, not file counts. Shared workflows resolve active plugin indexes; stack-specific APIs, tools, and discovery paths live in conduct. A row is covered only when its rules are reachable from the relevant architect, coder, reviewer, tester, or visual workflow.

## Backend and shared engineering baseline

Paths in the baseline column are relative to `plugins/laravel/`. Target paths below are relative to `plugins/`.

| Baseline | Obligations carried forward | Canonical target |
|---|---|---|
| `conduct/architecture.md`, `thin_controller_model.md` | Dependency direction, thin transport/data objects, focused business operations, DTOs/projections, domain invariants, pattern tradeoffs, query/write responsibility | `core/conduct/feature-design.md`, `typed-javascript.md`; `express/conduct/architecture.md`, `anti_patterns.md`; native/desktop architecture |
| `conduct/anti_patterns.md` | Hidden request/global state, adapter orchestration, unvalidated payloads, blocking work, string errors, swallowed/double reports, secret/large logs, environment reads, real adapters/order-coupled tests | `express/conduct/anti_patterns.md`; shared typed/config/logging/test protocols |
| `conduct/php.md`, `documentation.md` | Naming/types, immutable values, constructor boundaries, runtime validation, public contract documentation, precise source comments | `core/conduct/typed-javascript.md`, `code-comments.md`, `feature-design.md`; platform architecture |
| `conduct/enums.md` | Finite statuses/types, labels, API/database/render consistency, exhaustive transitions | `core/conduct/typed-javascript.md`; `drizzle/conduct/schema-design.md`; `react/conduct/ui-contracts.md` |
| `conduct/configs.md` | One validated config mapping, typed conversion, safe defaults, secrets, environment examples, injection, restart/rollout behavior | `core/conduct/runtime-configuration.md`; platform security/build conduct |
| `conduct/dependencies.md` | Project-first reuse, approved packages, installed versions, reproducible lockfile, maintenance/security/license/footprint, single integration boundary | `core/conduct/runtime-configuration.md`, `library-docs.md`; platform compatibility rules |
| `conduct/error_handling.md` | Typed categories/causes, no string matching/suppression/double wrapping/reporting, safe stable external errors, async ownership, no business-code process exit | `core/conduct/typed-javascript.md`; `express/conduct/error_handling.md`; `react/conduct/ui-contracts.md`; desktop architecture |
| `conduct/security.md` | Runtime input validation, SQL safety, object/tenant authorization, token/session lifecycle, password hashing, secrets, TLS/headers/CORS/CSRF, rate/upload limits, dependency security, safe errors | `express/conduct/security.md`; `drizzle/conduct/overview.md`; native/desktop security; shared typed/config/telemetry rules |
| `conduct/logging.md` | Structured context and severity, operation/actor scope, request/trace IDs, redaction, bounded payloads, single reporting | `core/conduct/logging-observability.md`; enabled platform integration/security rules |
| `conduct/observability.md` | Trace initialization/context/span lifecycle, request/queue/data/runtime metrics, bounded cardinality, private diagnostics, sampling/retention, correlation and recovery | `core/conduct/logging-observability.md`; backend integrations and native/desktop runtime profiling |
| `conduct/database_snapshot.md` | Identify current schema source, detect drift, use repository regeneration path | `drizzle/conduct/schema-design.md`, `database-safety.md` |
| `conduct/database-safety.md` | Constraints, real transaction context, concurrent invariants, compatible migrations, isolated verification, destructive-operation approval | `drizzle/conduct/database-safety.md`; backend durable enqueue/recovery rules |
| `conduct/cmd.md` | Typed validated bootstrap, initialization order, readiness, thin commands, bounded shutdown | `core/conduct/runtime-configuration.md`; backend/native/desktop entrypoint rules |
| `conduct/makefile.md` | Discoverable dev/build/lint/type/test/data/audit commands, arguments, failure propagation, safe destructive commands | `core/conduct/runtime-configuration.md`, `verification-loop.md`, `shell-invocation.md`; project-owned package/Make/task scripts |
| `conduct/git.md` | Scoped commits, branching/PR/release conventions, hook/CI safety, annotated tags | Existing `core/skills/git/SKILL.md`, `core/conduct/git-commit-workflow.md`; project branch/deploy rules |
| `conduct/fast_code_review_checklist.md` | Regressions, types/states, boundaries, errors/logs/config/security/dependencies, migrations and tests | Platform fast reviewers plus risk-matched indexes, `express/conduct/anti_patterns.md`, core review/risk protocols |
| `conduct/overview.md` | Discoverability and progressive loading | Each plugin's `conduct/overview.md`; `core/conduct/overview.md` and `conduct-loading.md` |

## Specification baseline

| Baseline | Required decisions | Canonical target |
|---|---|---|
| Laravel `conduct/spec/spec.md` | Discovery, owner/status/stakeholders, problem/goals/non-goals, actors, invariants, criteria, contracts, dependencies/nonfunctional constraints, validation, delivery/recovery, open decisions | `core/conduct/feature-design.md`; platform architect and ordinary specification workflow |
| `spec/spec-database.md` | Engine/scope/volume, schema before/after, types/nullability, indexes/query patterns/cardinality, constraints/cascades, concurrency, migration locks/rollout, batched backfill/checkpoint/verification | `drizzle/conduct/schema-design.md`, `database-safety.md` |
| `spec/spec-events-messaging.md` | Channel/producers/consumers, version/payload/invariants, recipients, durability/order, commit coupling, duplicate/out-of-order handling, retention/replay and runbook | `express/conduct/specification.md`, `integrations.md` |
| `spec/spec-jobs-scheduler.md` | Identity/trigger/schedule/timezone/overlap, full processing lifecycle, throughput/concurrency/batches/deadlines, lease/TTL/idempotency, retries/failure/replay/drain/scale/health | `express/conduct/specification.md`, `integrations.md`; shared telemetry/config rules |
| `spec/spec-infra-nginx.md` | Upstream/routing/static cache/compression, TLS/headers/CORS/limits, stream buffering/timeouts/upgrades, config validation/reload, rollout/rollback | `express/conduct/specification.md`; `core/conduct/docker-deployment.md` for deployment work |

Ordinary specifications use the active architect and these contracts. Ralphex plan creation/review remains separately keyword-gated; enabling coverage does not create a new automatic planning/approval flow.

## Workflow baseline

| Existing workflow | Preserved completion obligations | New-stack route |
|---|---|---|
| Laravel architect | Grounded responsibilities/contracts, pattern fit/rejection, alternatives/rationale, database integrity/performance, risks and concrete handoff | Platform architect → shared feature-design protocol → risk-matched stack specification/schema rules |
| Laravel deep reviewer | Architecture, security/data/errors, performance, supply chain, frontend consequences, maintainability, evidence/readiness/risk | Existing core deep orchestrator → touched platform reviewer → typed/config/logging and stack conduct; testing/docs specialists when gates open |
| Laravel fast reviewer | Material regressions, auth/conventions, cross-layer consequences, evidence and risk probe | Existing core fast orchestrator → platform fast reviewer or conduct-only fallback |
| Laravel business reviewer | Missing-source confidence, all-write state graph, actors/guards/side effects/transactions, criteria ledger, unreachable/missing/terminal/time-trigger/orphan/idempotency defects | Platform business reviewer → `core/conduct/behavioral-completeness.md` plus runtime entry discovery |
| Laravel tester + test-case conduct | Named case documents, finalization gate, test-only scope, criterion/case mapping, AAA/one behavior, independent deterministic fixtures, unit/integration/E2E boundaries, failure report | Platform tester/testing index → `core/conduct/test-implementation.md`; testcase design stays with the existing designer |
| Frontend deep/fast reviewer | UI state/error/security/performance/type/dependency/accessibility consequences | Touched renderer/platform reviewer plus shared React/UI and selected runtime conduct; no duplicate browser review for native-only scope |
| Frontend business reviewer | Entry-to-render trace, route reachability, complete view states, every API status, blocked exit, cache/invalidation/rollback, hydration and lifecycle | Shared behavioral protocol + React/UI contracts + actual app/window/session lifecycle |
| Frontend design critique | Source precedence/identity, hierarchy/composition/type/color/content/states/adaptation, anti-slop, evidence-backed read-only findings | Same shared skill → design-quality → resolved runtime adapter |
| Frontend pixel build | Measured whole-frame/control/spacing/icon ledger before edit; reuse; explicit resolved-value/glyph audit; normalized comparison; focused iteration then complete target pass | Same shared skill → `frontend/conduct/visual-workflow.md` → resolved runtime adapter |
| Frontend pixel guard | Verify approved baseline before edit; classify refactor/restyle; structural plus persistent assertions; restore collateral deltas; explicit named-baseline approval | Same shared skill → shared visual workflow → resolved runtime adapter |
| Frontend motion reviewer | Purpose/frequency, timing/easing/origin, interruption, resource cost, reduced motion/input modes, actual interaction evidence, read-only verdict | Same shared skill → motion policy → resolved interaction adapter |

## UI conduct baseline and runtime adapters

| Baseline conduct | Shared obligations | Runtime implementation |
|---|---|---|
| Frontend `design-quality.md` | Source order, identity, whole-frame inventory before details, explicit unexplained deltas, realistic content and state/accessibility checks | Existing design policy with actual runtime layout/accessibility evidence |
| Frontend `motion.md` | Purpose/frequency, motion tokens, origin/physicality, interruption, responsiveness, reduced motion and actual-input verification | Shared policy; implementation-specific CSS/WAAPI examples are browser-only |
| Frontend `visual-implementation.md` | Ready/authenticated/stable target, measured layout and paint comparison, no hidden overflow/occlusion, normalized evidence, iteration and approved baselines | Browser adapter retains Chrome DevTools/Playwright/Figma mechanics; other runtimes select their own adapter |
| Frontend `playwright-visual-regression.md` | Reproducible local dependency/runner, deterministic environment, explicit fixtures/fonts/theme/scale, exact initial comparison, controlled thresholds/masks, expected/actual/diff evidence | Browser assertions stay unchanged; native adapter requires actual device/OS-unit normalization and approved runner for persistent claims |
| Frontend `overview.md` | Thin UI/reusable logic, stable contracts, asynchronous states, existing token/component reuse | Shared UI rules; generic CSS applies to browser renderers only |

- Native adapter: `react-native/conduct/visuals.md` covers OS/device/build/theme/font-scale/orientation/keyboard/insets, unit/pixel normalization, native accessibility tree and VoiceOver/TalkBack, gestures/reduced motion, JS/UI frame cost, memory/battery/network, and approved per-target baselines.
- Desktop host adapter: `electron/conduct/architecture.md` adds actual window/content bounds, native chrome, DPI/zoom, themes/high contrast, menus/keyboard, packaged partition/preload, updater/download state graph, cross-window revocation, process responsiveness and power behavior.
- Shared client contracts: `react/conduct/state.md` and `ui-contracts.md` cover query/store ownership, account-scoped caches, form/error recovery, complete render states, stale responses, streaming, hydration and rollback.

## Deliberate translations

- Preserve language/framework semantics rather than copying PHP APIs, folder names, native enum columns, `HasLabels`, schema-snapshot commands, or Monolog/OTEL wiring into another runtime. Require equivalent validated values, labels, schema evidence, diagnostics and failure boundaries through installed tooling.
- Follow project-owned coverage thresholds, test layout, branch/release flow, package manager, and task runner; do not impose Laravel's numeric threshold, Makefile, or backend core on a UI-only feature.
- Preserve source-of-truth, security, destructive-operation, baseline-approval, and dependency-approval boundaries. Scale architectural abstractions to actual invariants and existing seams rather than forcing a repository/CQRS/DDD migration.
- Keep framework/runtime names and concrete APIs in plugin conduct. Shared workflows resolve applicable rules through enabled indexes; adding a runtime should not require another framework-name branch in shared visual skills.

## Tooling and verification

- Keep shared coder/comment gates, review routing, test policy, verification, git safety, and adapter generation from the always-enabled core plugin; stack manifests do not replace those protections.
- Reuse the existing frontend Figma/Chrome MCP configuration for relevant design/browser work. A shared workflow selects only tools that inspect the actual target; inheriting a configured browser does not make it a native-device verifier.
- Preserve browser regression tooling and its project-local dependency/approval rules. Native and desktop adapters use existing project/device/package tooling and report unavailable verification; no new daemon, runner, or dependency is silently installed.
- Exercise resolved dependencies, workflow discovery, generated Claude/Cursor/Codex entries, read-only reviewers, idempotent regeneration, and disabled-plugin cleanup in `tests/stack-plugins.sh`, including standalone UI platform plugin configurations.
- Audit Markdown links/frontmatter and shared workflow dispatch separately from runtime product behavior. Toolkit adapter tests establish availability and routing structure, not execution of a consuming application's UI or store-release flow.
