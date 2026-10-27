# Output, Media, and Telemetry Verification

## 1. Select output assertions

- Load this reference when an in-scope contract promises a generated file, recording/media, notification, telemetry, or asynchronous output. Select relevant assertions; do not expand an unrelated spot check into an output audit.
- Use [runtime-qa-evidence.md](./runtime-qa-evidence.md) for source, case/run, component, actor, fixture, method, and outcome records across browser, API, worker, and native execution.
- Trace the initiating action through processing to the promised output. Separate requested/accepted, pending, ready, and usable/delivered states according to the contract.
- Use available project tools and authorized test services. Attempt available authorized fixture/provider recovery before marking a prerequisite blocked; do not install dependencies or operate paid/live integrations merely to complete this checklist.

## 2. Generated artifacts

- Verify the required output entry point in each distinct supported implementation; a shared feature name does not prove each layout/client exposes it.
- Generate the artifact for the current pinned case, then open, parse, or render it with available tools suited to the assertion. A successful download establishes availability only.
- Check required fields, selected template, relevant image transparency/assets, links/QR destinations, and authorization against the contract. Use rendered evidence for visual assertions; text extraction cannot prove transparency or layout.
- Exercise supported download, open, and back-navigation behavior on the affected surface. Preserve unsupported viewer/device boundaries as gaps.

## 3. Media and recordings

- Observe processing transitions, then play/decode the resulting recording or media. A ready flag, successful job, or visible player does not establish usable media.
- Verify audio/video changes from receiver-side media evidence when supported. For mute, retain connection/track identity and counter continuity so disconnects or counter resets cannot imitate suppressed media.
- Use authorized synthetic media for deterministic checks and label it. Record actual engine/device and limits that still require real hardware or media.
- Keep unavailable recording/provider/device checks blocked after authorized recovery; distinguish those limits from an observed unplayable artifact.

## 4. Activity telemetry and analytics

- Define the measured quantity and permitted timing tolerance from the authoritative contract. Distinguish unique watched duration, elapsed playback, farthest position, and completion; resolve an unknown definition before numerical acceptance.
- Trace controlled actual activity → emitted events → authenticated actor/context → persisted intervals/counters → report, retaining evidence at each relevant boundary.
- Use known playback intervals and verify final-interval handling at end-of-media and page exit. Measure the persisted/report result against the observed activity within the contract's tolerance.
- Seek or resume at the end without watching; verify position changes do not fabricate watched duration/completion when the contract measures viewing time.
- Exercise replay and duplicate-event handling under the specified counting rules. Do not assume all replay must either add time or be ignored.
- Change session/account/impersonation context with a pending final event. Verify late events retain their original authorized actor/context or are safely rejected; they must not migrate to the newly active account.
- Repeat collection-to-report checks for supported client implementations with separate instrumentation. Playback or a device screenshot alone cannot establish event delivery, server persistence, or correct attribution.
- Apply [behavioral-completeness.md](./behavioral-completeness.md) for analytics identity and window comparisons: pin metric/version, entity/cohort identity, segment, timezone/window, and source population; join by identity, not list position.
- Compare equivalent views with a matching control and a deliberately mismatched-window case. Keep legitimately different populations/windows distinct; report an ambiguous business window as a contract gap.

## 5. Notifications and asynchronous delivery

- Verify the promised channel, recipient, content/link, timing, and duplicate behavior through an authorized test outbox, log, or provider using the current case/run.
- Distinguish queued, sent, and delivered from the strongest observed evidence. Match acceptance to the promised delivery boundary; a queue entry or inspected template alone cannot prove delivery.
- Preserve missing provider access and absent current-run output as unverified coverage after authorized recovery. Retain the exact observed processing state and the next prerequisite in the shared ledger.
