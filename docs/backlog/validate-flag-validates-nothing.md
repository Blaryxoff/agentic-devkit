---
worth: yes
where: bin/devkit-resolve:204
added: 2026-09-02
---
# `--validate` performs no schema validation

`README.md:51` ("Validate config and show resolved set") and `:207` ("Verify in a consuming project with
`devkit-resolve --validate`") imply schema validation. `--validate` only calls `resolve_plugins`, which checks
`version == 1` and that each named plugin exists.

Reproduced:

- `{"version":1,"enabled":["devkit-laravel"],"bogusKey":true}` → `OK: 2 plugins resolved`, exit 0.
- `{"version":1}` — missing the schema-`required` `enabled` — → `OK: 1 plugins resolved`, exit 0.
- An unknown plugin leaks a raw `jq: error (at <stdin>:129): Plugin not found: devkit-nope` with exit 5.
- No `plugin.json` is ever checked; an unrecognised `layer` silently sorts last via the `// 99` fallback
  (`adapters/_lib/resolve.sh:138`) instead of erroring.

Fix: validate each root's `toolkit.json` against `schemas/toolkit.schema.json` and every `plugins/*/plugin.json` against
`schemas/plugin.schema.json`; reject an unknown `layer`; wrap the jq "Plugin not found" error in a formatted message.

Related: [[toolkit-schema-rejects-the-schema-key-it-ships]], [[multi-root-skips-configless-root-silently]].
