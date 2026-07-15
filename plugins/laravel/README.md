# Laravel Plugin

Laravel architecture, security, database, testing, and operational conduct for agent-assisted projects.

## Start here

- Agent routing index: [conduct/overview.md](./conduct/overview.md)
- Plugin manifest: [plugin.json](./plugin.json)
- Skills: [skills/](./skills/)

## Baseline principles

- Keep business logic in domain/services/actions; keep HTTP, persistence, queues, and external APIs at boundaries.
- Use Form Requests for validation, policies/gates for authorization, Eloquent relationships/scopes for query
  composition, and Resources/DTOs for response boundaries.
- Prefer typed DTOs/value objects over stable raw-array contracts.
- Map request/model/domain/response boundaries explicitly.

## Human workflow

1. Start from the relevant specification under `conduct/spec/`.
2. Design test coverage from `conduct/testing/`.
3. Use `conduct/overview.md` to select only rules relevant to the change.
4. Review with `conduct/fast_code_review_checklist.md` when appropriate.
5. Follow `conduct/git.md` and the target project's own verification commands.
