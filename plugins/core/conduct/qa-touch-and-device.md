# Touch and Device Verification

## 1. Exercise the affected interaction

- Load this reference only for in-scope touch, browser-engine, device, or native-runtime risks. Keep unrelated desktop or API checks within their requested scope.
- Use [runtime-qa-evidence.md](./runtime-qa-evidence.md) for case/source/run, component, actor, fixture, method, and outcome records.
- Perform an actual touch-mode action on each affected critical control and verify its expected navigation/state result. DOM presence, geometry, a programmatic click, or a hover cannot prove tap behavior.
- Retain the existing bounds, clipping, and target-size checks in [browser-qa-rules.md](./browser-qa-rules.md) §5.15 and [browser-layout-audit.md](./browser-layout-audit.md). Diagnose interception with center and relevant edge hit tests when needed; do not force the action past an overlay.
- Exercise portrait/landscape, focused-input/keyboard viewport, sticky overlays, and the scroll path when the affected flow depends on them. Verify the action remains reachable and operable after each relevant transition.
- Record browser engine/version, touch profile, viewport/scale, orientation, and actual device versus emulation. Name any keyboard/zoom behavior the selected surface cannot reproduce.

## 2. Match proof to the runtime

- Require the actual browser engine for engine-specific claims, including Safari keyboard/zoom behavior. Chromium mobile emulation establishes only the recorded Chromium profile.
- Use Safari on the relevant platform when the claim depends on its browser chrome, keyboard, viewport zoom or OS integration; a generic WebKit runner alone does not establish those behaviors.
- Route native assertions through `devkit-verify` to the consuming project's configured device/runtime tools and enabled stack testing rules. Discover existing commands and capabilities; this reference supplies no general native runner or new tool API.
- Verify native behavior in the relevant app/package runtime. A browser PASS for a shared business feature does not establish native permissions, platform modules, lifecycle, privileged bridges, or packaging behavior.
- Preserve independent app/package and server revisions and their relevant configuration through runtime handoffs. Reuse only matching case/method/fixture evidence within its proven boundary.
- Attempt available authorized runtime/device/fixture recovery before declaring a missing capability blocked. Preserve unavailable engine, hardware, keyboard, or native cells as named coverage gaps; do not install runner dependencies or invent device evidence.
- Report actual device, simulator, emulator, and browser emulation separately. Keep checks whose claims require a different surface unverified even when the substitute surface passes.

## 3. Bound simulator and emulator storage

- Inventory existing devices, running instances, installed runtimes and disk usage before provisioning. Reuse installed Android system images and iOS runtimes; do not download or reinstall an OS image for each test run.
- Keep at most one explicitly designated reusable baseline per required OS/API and hardware profile. Reuse it for serial checks only with exclusive ownership and a recorded fixture/reset boundary; shut it down when the task started it. Retire obsolete profiles through an explicit cleanup decision rather than accumulating dated baselines.
- Create a uniquely named task/worker device only when parallel execution or an isolated initial state requires it. Bound the device count to concurrent lanes, reuse each owned device within its lane, and delete it when the lane ends. Do not keep a permanent device per task, branch or test case.
- Record the run owner, device name/UDID, Android serial/AVD path, baseline versus disposable status, and whether the task created or started it. Register cleanup before launch using the runner's teardown/finally or shell exit/signal traps. Persist this ownership record so a later run can reconcile leftovers after a hard crash.
- Reset only exclusively owned test state needed by the case. Android `-wipe-data` and iOS `simctl erase` remove apps/settings; use them for an authorized clean-device boundary, not as routine cleanup of a borrowed device. A cold boot or disabled snapshot saving alone does not prove a fresh app/user-data fixture.

| Platform | Provision and reclaim owned test devices |
|---|---|
| Android | Use the configured SDK/runner with the existing system image. Keep a bounded Quick Boot snapshot for the reusable baseline; disable snapshot saving for disposable runs when supported. Stop the exact serial, for example `adb -s <serial> emu kill`, wait for exit, then delete its disposable AVD with the installed manager, for example `avdmanager delete avd -n <owned-name>`. |
| iOS | Clone a shutdown baseline with `xcrun simctl clone <baseline-udid> <owned-name>` when its fixture matches; create a fresh device against the installed runtime when a clean initial state is required. After use, run `xcrun simctl shutdown <owned-udid>` if running, then `xcrun simctl delete <owned-udid>` for disposable devices. |

- Execute cleanup after success, failure, timeout and interruption, once required evidence is saved outside the disposable device. Verify owned disposable IDs are absent from the device inventory, their processes have exited and their data directories are reclaimed; report leftovers and measured storage when reclamation fails. Retry only after rechecking ownership.
- Preserve other sessions' active devices, borrowed baseline data and shared OS runtimes. Do not use global shutdown/delete/erase commands, broad directory deletion, or name/date matching as proof of ownership. Review unused runtime versions separately with the supported SDK/Xcode manager and the required test matrix.

Sources: [Android image/data separation and reset options](https://developer.android.com/studio/run/emulator-commandline), [Android Quick Boot](https://developer.android.com/studio/run/emulator-snapshots), [Apple Simulator cloning](https://developer.apple.com/videos/play/wwdc2019/418/). Confirm commands against the installed SDK and `xcrun simctl help <command>` before use.
