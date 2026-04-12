# Code conduct

Rules are used to create LLM agents, skills, pipelines, etc.
This will dramatically increase development speed as well as code consistency and reliability.
These rules are a source of truth.

Primary target stack in this repository:
- Laravel (PHP)
- Inertia + Vue
- Tailwind CSS
- Nginx (web transport/runtime boundary)

## Usage

### Tools

You can use rules directly in your prompts, but a much more convenient way is to create a skill or an agent.
We have created some basic implementations for many tools: ClaudeCode, Cursor etc. See [agentic-tools](https://rtpay.gitlab.yandexcloud.net/backend/agentic-tools)

### Workflow Example

- Create a spec — [see](./spec/)
- Create high-level (e2e/integration) test cases
- Feed to your LLM:
  - Created spec
  - Expected test cases
  - [Code conduct rules](./)
  - [Testing rules](./testing/)
- Validate the newly created test cases; make sure all edge cases and happy paths are covered
- Review the code (or by using [checklist](./fast_code_review_checklist.md) only or all files)
- Commit following [git conventions](./git.md): Conventional Commits format, one logical change per commit, run project checks (at minimum `vendor/bin/pint --dirty`, related `php artisan test`, and relevant frontend lint/format checks)

## Proposing Rule Changes

When you find something inconvenient, overkill, or too strict, you can propose changes.

1. Create your changes. Make sure that (**ALWAYS** use an LLM to validate the following rules):
   - The tone of the rules is **not** in SKILL instruction format, as these rules can be used for different purposes and must remain use-agnostic
   - Changes **do not conflict with or duplicate** existing rules
   - [fast_code_review_checklist.md](./fast_code_review_checklist.md) (contains only core topics; used in pre-commit hooks)
2. Create a PR
