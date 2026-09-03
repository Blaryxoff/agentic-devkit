---
worth: yes
where: schemas/toolkit.schema.json:8
added: 2026-09-02
---
# Every shipped example and every `--init` output fails the schema it points at

`toolkit.schema.json` sets `additionalProperties: false` and declares only `version` and `enabled`. All three
`examples/*.json` — and the file `devkit-resolve --init` writes (`bin/devkit-resolve:176-179`) — include a `$schema`
key, so each one fails validation against the schema it references.

All eight `plugin.json` files validate cleanly; this is specific to the toolkit schema.

Fix: add `"$schema": {"type": "string"}` to the properties block.

Related: [[validate-flag-validates-nothing]].
