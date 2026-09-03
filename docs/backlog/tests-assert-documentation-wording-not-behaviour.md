---
worth: later
where: tests/context-efficiency.sh:107
added: 2026-09-02
---
# The suite's dominant assertion style checks Markdown prose, not behaviour

Roughly 60 of the ~90 assertions in `tests/context-efficiency.sh` are `grep -F` string-presence checks against Markdown
prose — `'Missing coverage is itself a trigger'`, `'gpt-5.6-sol'`, `'up to 10 iterations'` (`:107-169`, model-version
literals at `:140-141`). They are hardcoded expected values that drift on any rewording, fail loudly on a harmless
copy-edit, and detect nothing about whether an agent follows the rule.

The genuinely valuable structural checks in the same file — every conduct doc reachable from its `overview.md`
(`:87-104`), `bash -n` on every hook (`:82-84`), real YAML frontmatter parsing (`:52-80`) — are diluted by them.

`worth: later` because the value decision is open: these canaries may be deliberate tripwires against silent conduct
edits. If they are, anchor them to something stable (a heading, or a committed anchor comment) and split them into
`tests/doc-canaries.sh` so a wording change does not read as a behavioural regression. If they are not, delete them and
keep the structural invariants and size budgets.
