# Makefile Rules

If a project uses `Makefile`, keep targets frontend-focused and deterministic.

## Recommended targets

```makefile
.PHONY: dev build lint typecheck test fmt ci

dev:
	pnpm dev

build:
	pnpm build

lint:
	pnpm lint

typecheck:
	pnpm typecheck

test:
	pnpm test

fmt:
	pnpm format

ci: lint typecheck test build
```

## Usage notes

- use `pnpm` as default package manager.
- keep target names predictable across projects.
- prefer short wrappers over long shell logic.

## Apply these practices

- keep `.PHONY` for non-file targets
- keep CI target as one-command quality gate

## Replace these patterns

- Keep frontend templates focused on frontend tooling.
- Move complex scripts into dedicated, testable script files.
