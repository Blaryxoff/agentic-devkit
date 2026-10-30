# Native Verification and Builds

- Apply [test-implementation.md](../../core/conduct/test-implementation.md) for named cases, isolation, runner boundaries, and failure reporting. Use [visuals.md](./visuals.md) for approved native baselines and actual device evidence.
- Run configured lint, typecheck, and eligible Jest/jest-expo or React Native Testing Library checks for the changed package. Match React, renderer, preset, transform allowlist, and library versions to the installed SDK.
- Verify changed native behavior on the relevant iOS/Android simulator or device: cold launch, deep link, auth restoration, denied permissions, keyboard/safe area, background/foreground, reconnect, and orientation when affected.
- Apply [qa-touch-and-device.md](../../core/conduct/qa-touch-and-device.md) §3 before provisioning and through teardown: reuse OS images and bounded baselines, isolate parallel lanes, and delete task-owned disposable devices after every outcome.
- Use existing browser Playwright flows for the web target only. Route browser QA to `devkit-browser`; use the available native/device tooling for native flows and report when it is unavailable.
- Verify release configuration with the project's existing local Xcode/Gradle or EAS workflow. Inspect API endpoints, public variables, permissions, identifiers, version/build numbers, and signing/update-channel compatibility without exposing secrets.
- Reconcile CocoaPods after native dependency changes through the project's Podfile workflow. Keep required native source/config/lockfile changes together; do not patch generated Pods files as the durable fix.
- Keep store submission and OTA publication separate from local verification; execute them only when explicitly authorized. Do not assume EAS cloud builds are the project's release path.

Sources: [Expo unit testing](https://docs.expo.dev/develop/unit-testing/), [Expo development builds](https://docs.expo.dev/develop/development-builds/introduction/), [React Native testing](https://reactnative.dev/docs/testing-overview).
