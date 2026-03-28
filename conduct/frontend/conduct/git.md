# Git Workflow

This document defines git rules for Nuxt + TypeScript + BEM projects.

## Commits

Use Conventional Commits:

`<type>: <summary>`

Types:
- `feat`
- `fix`
- `refactor`
- `test`
- `docs`
- `chore`
- `ci`
- `perf`

Rules:
- imperative mood
- concise summary
- one logical change per commit

## Branches

Format:

`<type>/<short-description>`

Examples:
- `feat/catalog-query-sync`
- `fix/modal-scroll-lock`
- `refactor/extract-form-composable`

## Pull Requests

PR title follows commit format.

PR body should include:
- What changed
- Why
- How to verify
- Risks

## Pre-commit checks

Run:

```bash
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

## Hygiene

- never commit secrets or `.env` files
- avoid unrelated file churn
- keep branch short-lived
- rebase on latest `main` before merge
- do not force-push shared protected branches
