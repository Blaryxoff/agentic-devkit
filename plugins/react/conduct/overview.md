# React Conduct

Apply these rules to React web and native clients. Read each app's React version and renderer separately; a workspace may legitimately contain React 18 web and React 19 native apps. Keep each bundle's React singleton compatible with its renderer rather than forcing one version across unrelated apps.

## Routing

- Query caches, Zustand, session restoration, effects, or streaming state → [state.md](./state.md).
- Forms, client failures, complete view states, or route recovery → [ui-contracts.md](./ui-contracts.md).
- Cross-layer architecture or requested specifications → [feature-design.md](../../core/conduct/feature-design.md).
- Types/errors, config/dependencies, or diagnostics → [typed-javascript.md](../../core/conduct/typed-javascript.md), [runtime-configuration.md](../../core/conduct/runtime-configuration.md), or [logging-observability.md](../../core/conduct/logging-observability.md), matched to the changed risk.
- Next.js server/client boundaries and caching → `plugins/nextjs/conduct/overview.md` when enabled.
- Native routing, styling, permissions, and app lifecycle → `plugins/react-native/conduct/overview.md` when enabled.
- Web markup, accessibility, visual design, or CSS → `plugins/frontend/conduct/overview.md` when enabled.

## Boundaries

- Keep render pure, hooks unconditional, and state close to its consumers. Derive values during render; use effects for synchronization with external systems and return cleanup for subscriptions.
- Keep browser/native APIs behind the relevant platform boundary; shared hooks must not assume DOM, localStorage, SecureStore, or navigation lifecycles are interchangeable.
- Verify behavior with the app's installed renderer and testing-library versions. A browser render does not prove native behavior.

Sources: [React effects](https://react.dev/learn/you-might-not-need-an-effect), [rules of hooks](https://react.dev/reference/rules/rules-of-hooks).
