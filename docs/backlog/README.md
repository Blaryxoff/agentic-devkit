# Backlog

Deferred work items for this repository, one file per defect. Format and lifecycle:
`plugins/core/conduct/deferred-work-backlog.md`.

Seeded 2026-09-02 from a whole-repo review at `1a14529` (generic quality, generic implementation, documentation, and
testing axes). The last item was cleared 2026-09-20.

## Blocking

_None._

## Significant

_None._

## Minor

_None._

## Cleared

- **2026-09-03** — the Claude adapter's settings.json hook merge, the Cursor adapter's hooks.json overwrite, the
  `devkit-tester` name collision, and the missing test runner. Running that runner for the first time surfaced a fifth,
  previously-unknown Blocking bug (the Cyrillic-description install crash), filed then and fixed below.
- **2026-09-13** — the Cyrillic-description install crash (the slash-command generator no longer parses skill
  descriptions at all), the three trigger-less skill descriptions, and the unvalidated subagent output path.
  `tests/context-efficiency.sh` enforces the description contract and a catalog-wide metadata budget, so the first two
  cannot regress.
- **2026-09-20** — the remaining twenty-two, in six passes:
  - **resolution** — paths interpolated into Python literals, `exit 1` inside sourced helpers, a configless extra
    project root skipped silently.
  - **installer** — every JSON write routed through `write_json` (tmp-then-`mv`, symlink- and mode-preserving), a
    malformed global Cursor hooks file no longer reset to `{}`, dangling devkit symlinks repaired instead of blamed on
    the user, `devkit-update` no longer stamping a failed fetch.
  - **`--validate`** — real checking of every `toolkit.json` and `plugin.json` against `schemas/`, via a checker for the
    draft-07 subset those schemas use that refuses to run against a keyword it does not implement.
  - **adapters** — the Cursor adapter's hardcoded clone path, `paths.skills` ignored by Cursor and Codex, `devkit-css`
    globbing every file, and `paths.settings`/`paths.lspServers` promised by the schema and read by nothing.
  - **tests** — new coverage for the no-clobber guard, the resolution core, the Claude and Cursor adapters,
    `devkit-update`, `skill-eval`'s debounce, `coder-gate`'s scratch exemption and the visual-loop cleanup; vacuous
    assertions repaired; wording canaries split into `tests/doc-canaries.sh`; `--preset`/`--enable` and `--dry-run`
    added as the seams two of those scripts lacked.
  - **docs** — `adapters/README.md`'s four stale sections, three cross-references in the review conduct cluster, and
    dual registration of core subagent skills settled as deliberate. `update.sh` deleted.
