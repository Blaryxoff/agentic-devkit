# Electron Conduct

Apply these rules to Electron shells and desktop clients. Inspect Electron, builder/updater versions, main entry, preload, renderer origin, session partitions, and packaging config before editing. The renderer may be a remote web app; do not assume it is trusted local HTML.

## Routing

- Main/preload/renderer flow, IPC, URLs, permissions, or credentials → [security.md](./security.md).
- Window/app lifecycle, builds, update feeds, signing, or test code → [testing.md](./testing.md).
- Web renderer UI → the enabled frontend/Next.js/React conduct for that renderer.

## Boundaries

- Keep privileged OS and filesystem operations in main, expose minimal typed capabilities through preload, and keep renderer code within browser privileges.
- Keep window/session/update state in the existing main-process modules. Preserve app identity, userData paths, persistent partitions, and single-instance/deep-link behavior when changing startup.
- Keep `contextIsolation: true`, `nodeIntegration: false`, and renderer sandboxing enabled, especially for remote content. Prefer a supported Electron release; treat upgrades as a separately scoped dependency change.

Sources: [Electron process model](https://www.electronjs.org/docs/latest/tutorial/process-model), [security checklist](https://www.electronjs.org/docs/latest/tutorial/security).
