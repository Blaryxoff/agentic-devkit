# Runtime Configuration and Dependencies

Load this document for configuration, dependency, bootstrap, CLI, or task-runner changes. Use the consuming project's existing package manager, scripts, and approved integration packages.

## Configuration

- Map environment/config input once into validated typed settings at the runtime boundary; pass those settings into services instead of scattering reads of global environment state.
- Parse booleans, numbers, durations, URLs, and optional values explicitly. Reject missing secrets and invalid critical settings before accepting work; provide defaults only for safe non-secret settings.
- Separate business settings from transport/runtime settings and browser/native-public settings from server secrets. Document required keys and safe examples in `.env.example`; ignore real environment files.
- Preserve environment precedence and build-time versus runtime evaluation. Verify the actual value source for Node, Next public bundles, Expo bundles, Electron main/preload, and release packaging separately.
- Document changed config keys, validation, defaults, reload/restart behavior, and migration from old keys. Validate before replacing a live config; keep rollback instructions when changing deployment behavior.

## Dependencies

- Check project-owned utilities, standard/platform APIs, and installed dependencies before proposing another package. Do not add dependencies without approval.
- Verify installed versions, peer/engine requirements, license, maintenance/security status, bundle/native footprint, and replacement cost before a dependency decision. Pin through the project's lockfile and retain reproducible install behavior.
- Keep runtime and development dependencies separate; inspect workspace exports and native autolinking/build-script effects when moving a dependency between packages.
- Use configured audit/security tooling for dependency changes. Adjudicate findings and report affected usage; do not automatically apply force upgrades or unreviewed major versions.
- Wrap external clients at a narrow application boundary when reuse, replacement, error normalization, or test isolation requires it. Avoid parallel HTTP, logging, validation, cache, or ORM libraries for the same job.

## Entrypoints and commands

- Keep composition in the owning entry point: load config, initialize logging/telemetry, create clients/pools, register application operations and routes/workers, then signal readiness.
- Make required connection/config failure visible before readiness. Separate liveness from dependency readiness; bound startup and shutdown and release acquired resources on partial initialization failure.
- Keep CLI/task commands as thin adapters to application operations. Validate arguments, return meaningful exit status, propagate failure through shell wrappers, and close clients/pools on both success and error.
- Reuse existing `package.json`, Makefile, or task-runner conventions. Keep target names discoverable, propagate user arguments, mark phony Make targets, and keep help text accurate. Do not introduce a Makefile just to mirror another stack.
- Require explicit authorization for destructive database/cleanup/reset/publish targets; keep read-only status/validation commands distinct. Follow [shell-invocation.md](./shell-invocation.md) for bounded invocation.

## Canonical local servers

Apply the manager requirements below only where the operator or project explicitly chooses a canonical manager, such as `canonical_dev_servers: true` on a Herd Mac. Installing devkit or having a registry file does not opt in. Other environments use their existing project runtime commands; record exact task-started processes/sessions and clean up only those owned resources on success, failure or interruption.

- Before starting an application server in a canonical setup, inspect `devkit-projects status`/MCP `projects_status` and the project's registered checkout, services, profile and origin. Use only `devkit-projects start`/`project_start`; on a Herd Mac preserve the registered `.test` route and DBngin database. Repair an unavailable manager or missing shared registry before proceeding; do not fall back to raw package commands, alternate ports or temporary copies.
- Reuse a running service only when its checkout/revision and API/environment profile match the intended work. A wrong branch or API lane blocks that acceptance check. Register an approved isolated variant or worktree with the manager's service template, reserved ports and origin first. A device bridge such as Android's host alias may target that registered runtime without creating another server.
- Before starting a temporary QA/worktree runtime, record its exact manager ID, checkout, profile, owning task/run, whether it was already running, and teardown action in the run's cleanup ledger. Stop only task-started services through the manager on success, failure or interruption; scripts use an exit trap. Verify stopped state before handoff, or record the user's explicit retention decision and new owner. Manager registration alone does not authorize indefinite retention. Never sweep unrelated processes by name or port range.
