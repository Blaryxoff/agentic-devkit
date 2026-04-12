# Code conduct

Rules are used to create LLM agents, skills, pipelines, etc.
This will dramatically increase development speed as well as code consistency and reliability.
These rules are a source of truth.

Primary target stack in this repository:
- Nuxt 3
- Vue 3
- TypeScript (strict)
- BEM + SCSS

## Usage

### Tools

You can use rules directly in prompts, but it is more convenient to create a skill or an agent.

### Workflow Example

- Create a spec — [see](./spec/)
- Create high-level frontend test cases
- Feed to your LLM:
  - Created spec
  - Expected test cases
  - [Code conduct rules](./)
  - [Testing rules](./testing/)
- Validate the newly created test cases; make sure all edge cases and happy paths are covered
- Review the code (or by using checklist files)
- Commit following [git conventions](./git.md): Conventional Commits format, one logical change per commit, run project checks (`pnpm lint`, `pnpm typecheck`, related tests, and build checks)

## Proposing Rule Changes

When you find something inconvenient, overkill, or too strict, you can propose changes.

1. Create your changes. Make sure that (**ALWAYS** use an LLM to validate the following rules):
   - The tone of the rules is **not** in SKILL instruction format, as these rules can be used for different purposes and must remain use-agnostic
   - Changes **do not conflict with or duplicate** existing rules
   - [fast_code_review_checklist.md](./fast_code_review_checklist.md) (contains only core topics; used in pre-commit hooks)
2. Create a PR
