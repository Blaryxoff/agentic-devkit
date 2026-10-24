# React UI and Failure Contracts

Load this document for stateful views, forms, client errors, or behavior reviews. Apply [state.md](./state.md) for query/store ownership and [typed-javascript.md](../../core/conduct/typed-javascript.md) for runtime contract narrowing and finite states.

- Model loading, error, empty, blocked, partial-data, and success explicitly. Include initial fetch, refetch, and mutation-in-flight behavior; distinguish empty success from missing permission or failed data.
- Map every server status to a render branch and action availability. Provide a safe fallback for unknown future values; do not silently render an allowed action for an unrecognized state.
- Normalize validation, unauthenticated, permission, missing resource, conflict, throttling, offline/network, server, and cancellation failures at the existing client adapter. Preserve typed diagnostic code/request ID separately from safe user-facing text.
- Keep form input and actionable field errors on failure. Provide a permitted retry, prerequisite, reauthentication, refresh/reconcile, or exit action; blocked/error screens must not strand the user.
- Prevent duplicate submissions and distinguish safe refetch from retrying a mutation. Reconcile conflicts and ambiguous success with authoritative server state; do not offer automatic retry that can duplicate a paid or destructive operation.
- Keep validation and authorization server-enforced even when the UI validates or hides controls. Do not expose internal exceptions, credentials, private request bodies, or stack traces in toasts or telemetry.
- Reconstruct entry/deep-link state from authorized routes and persistence; check back/forward/relaunch and cross-tab/window session behavior when the contract requires it.
- Apply [behavioral-completeness.md](../../core/conduct/behavioral-completeness.md) for an exhaustive flow/view/store audit. Component existence and a successful happy path do not establish full UI behavior.
