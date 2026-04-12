# Commands and Workflow Rules

This document defines standard command workflows for Nuxt frontend projects.

## Core scripts

Use project scripts from `package.json` as single source of truth:

- `pnpm dev`
- `pnpm build`
- `pnpm preview`
- `pnpm lint` (if configured)
- `pnpm typecheck` (if configured)
- `pnpm test` (if configured)

## Command usage rules

- prefer targeted checks while iterating (lint/type/test for affected scope).
- run build before final delivery for production-impacting changes.
- do not invent ad-hoc scripts when existing ones cover the task.

## Local development flow

1. install deps: `pnpm install`
2. run app: `pnpm dev`
3. iterate with lint/type/test as needed
4. validate production build: `pnpm build`

## CI flow (recommended)

1. install deps
2. lint
3. typecheck
4. tests
5. build

## DO / DO NOT

DO:
- keep scripts deterministic and documented
- keep command names consistent across repos where possible

DO NOT:
- run unrelated heavy checks on every tiny edit
- bypass type checks for TS code changes
