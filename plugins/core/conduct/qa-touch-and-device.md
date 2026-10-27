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
