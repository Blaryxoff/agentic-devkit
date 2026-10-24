# Electron Application and Renderer Design

- Apply [feature-design.md](../../core/conduct/feature-design.md), [typed-javascript.md](../../core/conduct/typed-javascript.md), and [runtime-configuration.md](../../core/conduct/runtime-configuration.md) for relevant design, contract, config, dependency, and entrypoint decisions.
- Assign operations to main, isolated preload, renderer, and backend explicitly. Keep privileged workflows out of renderer UI and keep domain decisions out of IPC/window callbacks; use narrow validated contracts and stable errors at each bridge.
- Model launch/configuration → app ready → session restore → window ready, plus reopen/single-instance/deep-link/quit and failure exits. Keep app identity, persistent partitions, and user data compatible across versions.
- Specify authorized sender, channel, input/output/error DTO, cancellation, resource lifetime, and payload bounds for each IPC capability. Avoid unbounded event streams or leaving handlers/listeners attached to destroyed windows.
- Build the updater/download graph: idle/checking/available/downloading/downloaded/installing/restarted/failed/cancelled as supported by the installed updater. Specify guards, duplicate callbacks, interrupted downloads, offline recovery, version/channel compatibility, user consent, and failed-install recovery without inventing rollback support.
- Trace cross-window/session synchronization and revocation. A renderer reload, remote-site navigation, closed window, or second instance must not retain unauthorized capabilities or duplicate main-process side effects.
- Normalize transport, IPC, permission, filesystem, network, and updater errors into safe user-facing recovery plus private diagnostic context. Preserve one reporting owner and redact crash state under [logging-observability.md](../../core/conduct/logging-observability.md).

## Renderer visual and operational checks

- Reuse the enabled frontend design, motion, critique, pixel-build, and pixel-guard workflows for browser-rendered content. Native window chrome and packaged-process behavior require the desktop checks here and [testing.md](./testing.md).
- Compare at the actual content bounds, not only outer BrowserWindow size. Verify supported resizing/minimum size, titlebar/window controls, DPI scaling/zoom, OS light/dark/high-contrast and reduced-motion preferences.
- Verify keyboard/menu focus, accelerators, modal ownership, native dialog returns, and accessibility with the actual packaged window/session partition when affected.
- Keep screenshot baselines separate by intended OS/DPI/chrome configuration and obtain approval before replacing them. A standalone web-tab match does not establish packaged preload, partition, permission, native chrome, or OS integration behavior.
- Measure main/renderer event-loop responsiveness, memory/listeners, CPU wakeups, background throttling/power use, and stream continuity when changing those paths; use a production-like packaged build.
