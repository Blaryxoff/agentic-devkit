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
