# Claude Code: local privacy launcher

This documents the optional launcher installed on the operator's Mac on
2026-11-03 and verified with Claude Code 2.1.317. The implementation and build
cache live outside this repository. Updating agentic-devkit distributes this
guide; it does not install the launcher or change Claude on other machines.

## Supported telemetry controls

Merge these values into the existing `env` object in `~/.claude/settings.json`:

```json
{
  "env": {
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1"
  }
}
```

Restart Claude sessions after changing them. These settings persist across
updates. `claude doctor` confirmed auto-updates remained enabled after they
were applied. Disabling telemetry also disables feature-flag evaluation and
can affect Remote Control. Training preferences are a separate account setting.
See the [official data-usage documentation](https://code.claude.com/docs/en/data-usage#telemetry-services).

## Default command and coverage

The installed launcher is `~/.local/share/claude-privacy-audit/bin/claude`.
A managed block in `~/.zshenv` prepends that directory to PATH for new zsh
shells. Use `exec zsh` once in an existing terminal, or use `claude-private`
immediately. Check resolution with `command -v claude`.

The official updater retains `~/.local/bin/claude`, pointing into
`~/.local/share/claude/versions/`. Calling that path or a native executable
directly bypasses the launcher. Native subprocesses invoked by absolute path
are also outside its coverage. Existing running sessions are not patched.

The privacy change forces the `tengu_wiggly_dove` eligibility gate false
before automatic Git-origin/environment collection and generation of the
`x-claude-code-wiggly-dove` header. It does not hide IP/account information,
remove normal prompt/tool-result content, or cover other collection paths.

The client runs from extracted source under the already-installed Bun runtime.
One standalone-runtime predicate is restored for compatibility, and a renderer
shim supplies Anthropic's private Bun API. No full ClawGod installation,
feature unlocks, safety-instruction removals, geo patches, or organization-rule
bypasses are enabled.

## Update behavior

Each launch resolves the official updater's current symlink and hashes the
native executable, launcher recipe, runtimes, and cached client artifacts.
A new native version or changed recipe requires a separate verified build.
An existing session continues using its current build while the official
background updater installs a newer version; the next launch prepares it.

`claude update` and `claude install ...` run the official command and verify
the selected version after it succeeds. The launcher never silently falls
back to an unpatched client. Unknown code shapes, verification failures, and
cache corruption stop launch. This is version adaptation with rejection on
drift, not a promise that every future Claude release will be supported.

Before publishing a build, the launcher checks:

- The official native binary's signature and unchanged identity.
- Matching collection gate, header factory, and permission-context gate in
  the native and extracted source.
- Sixteen isolated gate cases across all eight eligibility combinations.
- Three actual-client loopback cases: official native baseline, forced-enabled
  collector control, and patched client. Completion and tool names must match;
  the control calls the collector and sends its header, while the patched
  client does neither.
- Matching official and patched version output.

The loopback checks use a temporary Git repository, isolated Claude settings,
and a dummy API key. They do not use the operator's account. Instrumentation
is removed before publication. Version 2.1.317 also passed six focused
update/cache tests, an isolated uninstall check, and fullscreen startup.

## Operations and rollback

These commands require the existing local installation:

```sh
claude --privacy-status
claude --privacy-rebuild
claude doctor
```

Inspect `~/.local/share/claude-privacy-audit/current.json` for the selected
build. Each build contains `manifest.json` and `verification.json`. The local
`README.md` and `vendor/SOURCES.json` record implementation details and pinned
upstream sources. Older published builds are retained for running sessions.

To restore normal command resolution:

```sh
claude --privacy-uninstall
exec zsh
```

Uninstall removes the managed PATH block and launcher links. It preserves the
official installation, telemetry opt-outs, backups, and verification evidence.
If the wrapper cannot start, run its installer directly with the local Python:

```sh
python3 ~/.local/share/claude-privacy-audit/install.py --uninstall
```

Do not copy settings, credentials, extracted client bundles, or machine-specific
runtime paths into this repository. Linux/container installation is outside
this Mac-specific setup and requires its own implementation and verification.

## Suspension evidence and limits

Two distinct GitHub usernames reported three account bans each in the same
ClawGod thread on June 14–15, 2026: [Andtun02](https://github.com/0Chencc/clawgod/issues/94#issuecomment-4700813555)
and [a398275770-ctrl](https://github.com/0Chencc/clawgod/issues/94#issuecomment-4707546489).
These are unverified self-reports, not six independently investigated incidents.
The [maintainer disputes the causal attribution](https://github.com/0Chencc/clawgod/issues/94#issuecomment-4714162760).

Those reports predate the Git/environment protection introduced in
[ClawGod v2.3.0 on October 19, 2026](https://github.com/0Chencc/clawgod/releases/tag/v2.3.0),
so they cannot demonstrate bans caused by that particular change. There is
no defensible numerical ban probability: exposure counts, duration, baseline
ban rates, enabled features, and confirmed suspension reasons are unavailable.

[Anthropic's consumer terms](https://www.anthropic.com/legal/consumer-terms)
restrict reverse engineering and bypassing protective measures and permit
suspension for material breaches. That is a plausible contractual risk, not
proof of a ban mechanism. The checks establish suppression of one metadata
path; they establish neither anonymity nor reduced suspension probability.
