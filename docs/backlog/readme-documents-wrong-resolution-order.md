---
worth: yes
where: README.md:100
added: 2026-09-02
---
# README documents a resolution order the resolver does not produce

Within a layer, `resolve_plugins` sorts by `keys` (alphabetical) then applies a stable `sort_by(layer)`
(`adapters/_lib/resolve.sh:138`), so dependencies are not ordered before dependents inside the same layer. Both worked
examples in README are wrong:

| Config | README claims | Actual |
|---|---|---|
| `[laravel, vue, inertia, tailwind]` | `core → frontend → vue → inertia → laravel → tailwind` | `core, frontend, inertia, laravel, vue, tailwind` |
| `[nuxt]` | `core → frontend → vue → nuxt` | `core, frontend, nuxt, vue` |

The order is user-visible: it drives the section order of `AGENTS.md` conduct blocks and `.cursor/rules/*.mdc` creation.

Fix: either topologically order within a layer, or correct `README.md:100` and `:113`. `CLAUDE.md:92` (layer order only)
is already accurate.
