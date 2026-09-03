---
worth: yes
where: howto/README.md:18
added: 2026-09-02
---
# The howto index links 7 of the 13 documents in the directory

The Навигация section wikilinks 7 documents; `howto/` holds 13. Unreachable from the index: `Импорт скилов umputun.md`,
`modular-plugin-ownership-plan.md`, `project-test-rules.md`. Two of those three are written in English inside a
directory that `CLAUDE.md:40` and `README.md:197` both label "Developer guides (Russian)" — a mismatch only visible to
someone who lists the directory, because the index never surfaces them.

Fix: add the three missing docs to the index and note which entries are English.
