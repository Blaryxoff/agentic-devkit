# Native Architecture and Tooling

- Match the installed Expo Router's layouts, route groups, auth guards, and deep-link conventions. Wait for root navigation and async session restoration before navigating; preserve entry URLs through login when the contract requires it.
- Keep a compatible React singleton within the native bundle. Inspect Metro and native autolinking when a pnpm workspace contains multiple React versions or duplicate native modules.
- Start from the installed SDK's `expo/metro-config`. SDK 52+ supplies monorepo support and SDK 54 supports isolated pnpm installs; preserve a custom resolver only for a demonstrated compatibility requirement. Do not copy old watchFolders/nodeModulesPaths boilerplate into a newer SDK by default.
- Use NativeWind's installed major setup. For v4, inspect its Metro/Babel integration, CSS entry, Tailwind v3 config, content globs, and interop for third-party components; do not substitute web Tailwind v4 setup.
- Bridge TanStack Query focus/connectivity to AppState and the existing network integration on native. Clean up listeners and choose foreground refetch behavior deliberately; browser focus events do not cover native background/foreground transitions.
- Keep long-lived call/WebView components mounted across orientation/layout changes when remounting would terminate a session. Subscribe and clean up by screen focus/app lifecycle where mounting alone does not match visibility.
- Check SDK-compatible dependencies with the project's Expo tooling (`expo install --check`, `expo-doctor` when available). Inspect findings before any fix/install command; dependency changes still require approval.
- Preserve manually maintained `ios/` and `android/` changes. Do not run `expo prebuild --clean` over committed native projects as a repair shortcut; follow the project's regeneration policy.

Sources: [Expo monorepos](https://docs.expo.dev/guides/monorepos/), [Expo Router auth](https://docs.expo.dev/router/advanced/authentication/), [NativeWind v4 installation](https://www.nativewind.dev/docs/getting-started/installation), [Query native lifecycle](https://tanstack.com/query/v5/docs/framework/react/react-native), [Expo native generation](https://docs.expo.dev/workflow/continuous-native-generation/).
