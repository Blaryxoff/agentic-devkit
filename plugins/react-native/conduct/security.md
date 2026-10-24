# Native Security and Lifecycle

- Store native credentials with the existing secure storage adapter; AsyncStorage is not encrypted credential storage. Web targets need their own storage/cookie policy and XSS boundary.
- Await token hydration and validate/refresh the session before protected requests. Serialize refresh, bound retry, clear credentials and account-scoped query/store data on logout, and prevent stale requests restoring a logged-out session.
- Treat SecureStore persistence as platform-dependent: iOS keychain entries can survive reinstall, Android backups must exclude unreadable encrypted entries, and biometric changes can invalidate protected values. Recover through normal authentication.
- Treat `EXPO_PUBLIC_*` as public bundle contents. Keep signing credentials, provider secrets, and server keys outside app config and shipped JavaScript.
- Validate deep-link schemes/hosts, route parameters, notification payloads, and WebView bridge messages. Reauthorize the destination resource on the API after cold start, login, or workspace switch.
- Request camera/microphone/files/notifications only for the relevant user action. Handle denied/revoked permission, backgrounding, and unavailable native modules; release recording, playback, stream, and notification listeners.
- Define reconnect behavior per stream. For `react-native-sse` one-shot POST generation, disable automatic polling/replay (`pollingInterval: 0`) unless the operation has an idempotency contract; own explicit cancellation and reconnection in the existing helper.
- Restrict WebView navigation and injected/bridged capabilities. Validate origins and message shapes, keep credentials out of HTML/URLs/logs, and preserve call/media permission boundaries.

Sources: [Expo SecureStore](https://docs.expo.dev/versions/v54.0.0/sdk/securestore/), [Expo environment variables](https://docs.expo.dev/guides/environment-variables/), [react-native-sse options](https://github.com/binaryminds/react-native-sse), [WebView security guide](https://github.com/react-native-webview/react-native-webview/blob/master/docs/Guide.md).
