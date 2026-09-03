---
worth: yes
where: adapters/_lib/resolve.sh:94
added: 2026-09-02
---
# `_collect_enabled` error paths do not abort — they fall through into `jq --argjson` and leak a usage banner

`_collect_enabled` calls `exit 1` at `:83` (bad version) and `:94` (no toolkit.json), but it is only ever invoked as a
command substitution (`enabled_json=$(_collect_enabled)` at `:106`), so `exit` terminates the substitution subshell, not
the caller. errexit does not rescue this — a nested `v=$(inner)` inside `r=$(outer)` continues after `inner` exits 1.

Reproduced on both paths:

```
$ bin/devkit-resolve --validate
ERROR: No .devkit/toolkit.json found at …
jq: invalid JSON text passed to --argjson
Use jq --help for help with command-line options, …     → exit 2
```

Adapters do stop (no files written), so this is not data loss — but the exit code is jq's `2` rather than `1` and the
real diagnostic is buried. `_check_jq` (`:31`) has the identical shape when reached via `:100`.

Fix: `return 1` in all three, and `enabled_json=$(_collect_enabled) || exit 1` at the call site.
