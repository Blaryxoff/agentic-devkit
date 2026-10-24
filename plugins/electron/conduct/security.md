# Electron Security

- Expose one narrow contextBridge operation per capability; never expose raw `ipcRenderer`, unrestricted channel sends, Node modules, or arbitrary filesystem/shell access.
- Validate IPC sender frame/origin and payload for every privileged handler. Prevent a remote subframe or newly navigated page from acquiring a capability through a trusted parent window.
- Parse URLs and allowlist exact schemes, origins, and intended paths before navigation, new windows, external browser opening, downloads, deep links, or permission grants. Hostname matching alone permits unintended schemes/ports; never pass untrusted URLs directly to `shell.openExternal`.
- Deny unexpected navigations/window creation and apply permission check/request handlers to the actual session partition. Bound media/device permissions to the requesting trusted origin and required capability.
- Load remote content over HTTPS and apply an appropriate CSP at its owning server. Keep session cookies and credentials out of renderer-exposed objects, URLs, logs, and bridge messages.
- Keep preload isolated and sandbox-compatible. Validate data entering from a remote renderer as hostile even when the initial URL is trusted.
- Test positive and denied paths: allowed top-level content, external links, iframe IPC, unexpected schemes/ports, cross-origin navigation, and media permission denial.

Sources: [Electron security checklist](https://www.electronjs.org/docs/latest/tutorial/security), [context isolation](https://www.electronjs.org/docs/latest/tutorial/context-isolation), [IPC](https://www.electronjs.org/docs/latest/tutorial/ipc).
