---
worth: yes
where: schemas/plugin.schema.json:57
added: 2026-09-02
---
# `paths.settings` and `paths.lspServers` are declared, promised, and read by nothing

`grep -rn 'paths.settings\|lspServers' adapters bin` returns zero hits. Both keys are declared in the schema and in
`plugins/{laravel,nuxt}/plugin.json`, and both point at real files that never reach any output channel.

The `settings` half is security-shaped: `plugins/laravel/settings.json` and `plugins/nuxt/settings.json` carry ~150
`permissions.deny` rules each, including `Read(.env)`, `Read(*.pem)`, `Read(*.key)`, `Read(*credentials*.json)`, and
`adapters/README.md:9` states the Claude adapter emits settings.json with "permissions + hooks". The adapter writes
hooks only and says so in a comment (`adapters/claude/generate:109`). A user reading the docs believes secret reads are
denied; they are not.

`plugins/laravel/settings.json:6-13` additionally contains entries like `"// Build and generated artifacts"` that are
not valid permission rules and would be rejected if the key ever were wired up.

`adapters/claude/generate:24` claims LSP configs are "noted but not merged" — no code notes them either.

Fix: pick one direction. Either merge `permissions.deny` additively into `.claude/settings.json` and emit a NOTICE for
LSP paths, or delete both keys from the schema and both manifests and correct `adapters/README.md:9`. Do not leave a
security-shaped promise that no code honours.

Related: [[adapters-readme-describes-an-adapter-that-no-longer-exists]].
