# Electron Lifecycle, Packaging, and Verification

- Apply [test-implementation.md](../../core/conduct/test-implementation.md) for testcase traceability, independent fixtures, and test-only scope. Use [architecture.md](./architecture.md) for the updater/IPC state graph and actual packaged-window visual checks.
- Resolve package scripts before invoking Electron or builder. If the environment sets `ELECTRON_RUN_AS_NODE`, clear it using the project's launcher; otherwise Electron can start as Node instead of opening the app.
- Run configured checks for main/preload and renderer separately. Smoke-test startup, restored session, login/logout, deep links, external windows, app quit/reopen, tray/window behavior, and denied IPC/permissions when affected.
- Preserve window and renderer identity across layout/theme changes; close listeners, windows, timers, and background processes deliberately. Verify background streaming behavior when changing throttling or power settings.
- Use the installed builder/updater's versioned documentation. Build the intended platform/architecture and inspect artifact contents, preload/resource paths, app identity, and feed metadata; unpackaged dev mode does not establish packaged behavior.
- Keep signing/notarization credentials outside the repository. Verify signatures using the project's release workflow; distributing an unsigned local build is a separate decision from a private smoke check.
- For generic update providers, pair release binaries with generated platform metadata and blockmaps at the configured HTTPS feed. Check app version, architecture, target, download verification, failure recovery, and installation behavior before publication.
- Distinguish updatable targets from portable outputs. For builder 26/updater 6, follow that version's feed/signing rules; do not import builder 27/updater 7-only options into older configs.
- Publish binaries or update-feed metadata only when explicitly authorized; release artifacts can trigger updates for installed clients. Report untested OS/architecture and store/update paths explicitly.

Sources: [Electron environment variables](https://www.electronjs.org/docs/latest/api/environment-variables), [electron-builder v26 updates](https://www.electron.build/v26/docs/features/auto-update/), [Electron code signing](https://www.electronjs.org/docs/latest/tutorial/code-signing).
