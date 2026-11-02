# Quality Gates

Apply when a task adds or changes a lint, type, security, documentation or CI check. Running existing checks is
[verification-loop.md](./verification-loop.md).

## Adding a check

1. Keep the tool the project already runs for a job; add a tool only for a job nothing covers.
2. Wire the check into the project's existing aggregate command (`make check`, a package script, `tests/run-all.sh`) so
   hooks and CI run the same definition. Never add a second entry point.
3. Prove it once: run it against one real violation in a disposable fixture or scratch copy and confirm a non-zero exit,
   then on the clean tree. A check never seen failing is not known to work. This is a one-time proof per check, not a
   per-change step.
4. Baseline existing findings with the tool's baseline mechanism instead of disabling the rule.
5. Schedule a new check that takes minutes (an architecture scan, a full-history secret scan) instead of adding it to
   the per-change command. Keep gates that project or stack conduct requires in CI; a vulnerability scan there also
   runs on a schedule, because a new advisory fails it without a code change.

## Backing a rule with a check

When a project rule in conduct or `AGENTS.md` can be enforced mechanically, prefer the check over more prose. A rule
without a check is advice; an agent drifts from it as the code base grows.

## Project-wide setup

For an explicit request to set up quality gates across a project, choose tools from
[dev-quality-gates](https://github.com/mokevnin/dev-quality-gates) (CC0) and follow its `docs/adopt.md`. Project
conduct, existing tools and the user's local serving setup take precedence over it. Its scratch-branch and pull-request
steps apply only when the user asks for them.
