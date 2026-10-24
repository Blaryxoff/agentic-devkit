# React Native and Expo Conduct

Apply these rules to native clients, including Expo projects. Inspect installed Expo/RN/React/Router/NativeWind versions and committed native directories first; SDK compatibility governs native dependencies. Preserve the project's managed/prebuild or manually maintained native workflow.

## Routing

- Screens, Expo Router, shared code, Metro, NativeWind, or app lifecycle → [architecture.md](./architecture.md).
- Session persistence, deep links, permissions, notifications, streams, or WebViews → [security.md](./security.md).
- Builds, device checks, test code, or QA → [testing.md](./testing.md).
- Shared hooks, Query, and Zustand → `plugins/react/conduct/overview.md` and its routed state rules.
- Design/reference fidelity, visual protection, accessibility, animation, or native performance → [visuals.md](./visuals.md); reuse enabled frontend design/motion policy with this native adapter.
- Feature architecture/specification → [feature-design.md](../../core/conduct/feature-design.md).
- Types/errors, configuration/dependencies, or telemetry → the risk-matched [typed JavaScript](../../core/conduct/typed-javascript.md), [runtime configuration](../../core/conduct/runtime-configuration.md), or [logging/observability](../../core/conduct/logging-observability.md) rules.

## Boundaries

- Keep routes thin and business/API behavior in existing hooks, clients, and services. Client route protection improves navigation; the API must enforce authorization.
- Preserve native accessibility roles/labels, dynamic type, safe areas, keyboard behavior, and touch targets. NativeWind is a native styling adapter; browser CSS and DOM accessibility rules do not automatically apply.
- Treat Expo Go, development builds, native release builds, and browser export as distinct verification surfaces. State which one was checked.

Sources: [Expo SDK versions](https://docs.expo.dev/versions/), [React Native accessibility](https://reactnative.dev/docs/accessibility).
