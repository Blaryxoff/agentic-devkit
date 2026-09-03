---
worth: yes
where: adapters/_lib/resolve.sh:91
added: 2026-09-02
---
# Project paths are interpolated unquoted into `python3 -c` source

`$TOOLKIT_ROOT` and `$PROJECT_ROOT` are pasted inside single-quoted Python string literals at `:91` and `:155`. A path
containing an apostrophe terminates the literal — reproduced with `--project="…/it's here"`, which yields
`SyntaxError: unterminated string literal` and a silently empty hint. A directory name that closes the quote and paren
executes arbitrary Python as the invoking user; both `--project=` and `DEVKIT_PROJECT_ROOT` are externally supplied.

`toolkit_relpath` (`:155`) additionally has its output written verbatim into the user's `.devkit/toolkit.json` `$schema`
field (`bin/devkit-resolve:99,176-179`).

Fix: pass paths as `argv` in both places, never as source text:
`python3 -c 'import os.path,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$TOOLKIT_ROOT" "$PROJECT_ROOT"`.
