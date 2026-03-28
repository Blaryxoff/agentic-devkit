# Fast Code Review Checklist

Use this checklist before commit/PR for Nuxt + TypeScript + BEM work.

## Architecture

- [ ] Logic is extracted to composables/services where appropriate
- [ ] Components are focused and not overloaded with side effects
- [ ] No obvious duplication (DRY)

## Type safety

- [ ] No unjustified `any`
- [ ] Public contracts (props/emits/composable returns) are typed
- [ ] Unsafe casts are avoided or documented

## UX behavior

- [ ] Loading, empty, and error states are implemented
- [ ] URL/query sync is correct for filters/search/pagination
- [ ] No obvious regressions in critical flows

## BEM and styling

- [ ] Class names follow BEM conventions
- [ ] Modifier usage is semantic and consistent
- [ ] No style leakage or conflicting block naming

## Error handling and logging

- [ ] Promise rejections are handled
- [ ] Errors are mapped to user-safe messages
- [ ] Logs contain context and no sensitive data

## Security

- [ ] No secrets/tokens in code or logs
- [ ] No unsafe HTML rendering of untrusted content

## Verification

- [ ] `pnpm lint` passes
- [ ] `pnpm typecheck` passes
- [ ] relevant tests pass
- [ ] `pnpm build` passes for production-impacting changes

## Git hygiene

- [ ] Commit message follows Conventional Commits
- [ ] One logical change per commit
- [ ] No unrelated generated noise in changeset
