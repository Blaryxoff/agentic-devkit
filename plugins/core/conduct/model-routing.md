# Runtime Model Routing

- Specify a model family and reasoning effort in workflows, never a numbered model release.
- Resolve the newest available version of that family before dispatch; record the actual model ID in the report.
- For native subagents, use the harness's current selectable-model catalog. Compare numeric version components,
  not lexicographic order. Do not infer availability from session history or substitute another family silently.
- For Codex CLI workers, query its account/provider catalog with the bundled resolver:

```bash
executor_model=$(python3 "$DEVKIT_HOME/bin/devkit-model" luna --effort medium < /dev/null) || exit 1
```

- Resolve `DEVKIT_HOME` from the loaded devkit skill's canonical clone when the environment variable is absent.
- Replace `luna` and `medium` with the workflow's requested family and effort. The resolver uses
  [`model/list`](https://developers.openai.com/codex/app-server#list-models-modellist), includes all result pages,
  selects the newest visible numbered release and validates the requested effort. It creates no thread or browser.
- Pin the resolved model within one pass, including rechecks; resolve again for the next pass.
- Use Claude's unversioned family aliases (`opus`, `sonnet`, `haiku`) for Claude CLI workers.
- A missing family, unsupported effort or failed catalog lookup blocks that dispatch. Report the prerequisite;
  never fall back to a remembered release or invent a `latest` alias.
