# Backlog

Deferred work items for this repository, one file per defect. Format and lifecycle:
`plugins/core/conduct/deferred-work-backlog.md`.

Seeded 2026-09-02 from a whole-repo review at `1a14529` (generic quality, generic implementation, documentation, and
testing axes). Ordering below is by severity as adjudicated at filing time, not by `worth`.

Four items from the original Blocking set were fixed 2026-09-03 (Codex-validated) and removed: the Claude adapter's
settings.json hook merge, the Cursor adapter's hooks.json overwrite, the `devkit-tester` name collision, and the missing
test runner (`tests/run-all.sh` now exists and is documented in `CLAUDE.md`). Running that runner for the first time
surfaced a fifth, previously-unknown Blocking bug — see below — which was filed but not fixed in the same pass.

## Blocking

- [`bin/devkit-install` crashes on any fresh install with a Cyrillic skill description](awk-crashes-on-multibyte-skill-descriptions.md)

## Significant

- [`_collect_enabled` error paths are swallowed in a subshell](resolve-error-paths-swallowed-in-subshell.md)
- [Project paths interpolated into `python3 -c` source](resolve-interpolates-paths-into-python-source.md)
- [A failed fetch is stamped as a successful pull](devkit-update-stamps-failed-pull.md)
- [A malformed global Cursor hooks file is reset to `{}`](install-resets-malformed-cursor-hooks.md)
- [`update.sh` is an orphaned destructive vendor fetch](update-sh-orphaned-destructive-vendor-fetch.md)
- [`paths.settings` and `paths.lspServers` are read by nothing](plugin-paths-settings-and-lsp-never-read.md)
- [README documents a resolution order the resolver does not produce](readme-documents-wrong-resolution-order.md)
- [The toolkit schema rejects the `$schema` key it ships](toolkit-schema-rejects-the-schema-key-it-ships.md)
- [`--validate` performs no schema validation](validate-flag-validates-nothing.md)
- [A mistyped `--project` root is silently ignored](multi-root-skips-configless-root-silently.md)
- [Cursor adapter hardcodes the devkit home path](cursor-adapter-hardcodes-devkit-home-path.md)
- [A dangling devkit symlink is misreported as the user's file](dangling-devkit-symlink-reported-as-user-file.md)
- [Core subagent skills are registered twice](core-subagent-skills-registered-twice.md)
- [The no-clobber guard is never exercised](untested-no-clobber-guard.md)
- [`coder-gate`'s scratch exemption has no test](untested-coder-gate-scratch-exemption.md)
- [The resolution core and three CLI entry points have no coverage](untested-install-and-resolve-paths.md)
- [`adapters/README.md` is stale in four places](adapters-readme-describes-an-adapter-that-no-longer-exists.md)
- [Private identifiers in shipped conduct](private-identifiers-in-shipped-conduct.md)
- [The layout tree omits the css plugin and `tests/`](claude-md-layout-omits-css-plugin-and-tests.md)
- [The `ralphex-` prefix is documented but unused](ralphex-prefix-documented-but-unused.md)
- [Three skill descriptions have no trigger clause](skill-descriptions-without-a-trigger-clause.md)

## Minor

- [Three cross-reference defects in the review conduct cluster](review-conduct-cross-reference-defects.md)
- [Test assertions that can pass vacuously](test-assertions-that-can-pass-vacuously.md)
- [`settings.json` writes truncate before producing output](json-writes-truncate-before-producing-output.md)
- [Subagent output path from unvalidated frontmatter](subagent-output-path-from-unvalidated-frontmatter.md)
- [Cursor and Codex adapters ignore `paths.skills`](cursor-and-codex-adapters-ignore-paths-skills.md)
- [`devkit-css` Cursor rule globs every file](devkit-css-cursor-rule-globs-every-file.md)
- [Nine css skills drop the prefix, undocumented](css-skills-drop-the-prefix-undocumented.md)
- [`examples/nuxt-css.json` enables no CSS plugin](examples-nuxt-css-enables-no-css-plugin.md)
- [`--help` truncates the header block](install-help-truncates-the-header-block.md)
- [The howto index links 7 of 13 docs](howto-index-reaches-7-of-13-docs.md)
- [No test seams on the high-blast-radius scripts](no-test-seams-on-high-blast-radius-scripts.md)
- [Tests assert documentation wording, not behaviour](tests-assert-documentation-wording-not-behaviour.md)
