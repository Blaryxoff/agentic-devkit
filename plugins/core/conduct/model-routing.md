# Runtime Model Routing

- Specify a model family and resolve its currently available model identifier. Use the caller's requested reasoning effort; when omitted,
  inherit the worker runtime's configured default without an effort override.
- Resolve the newest available version of that family before dispatch; record the actual model ID in the report.
- For native subagents, use the harness's current selectable-model catalog. Compare numeric version components,
  not lexicographic order. Confirm availability in the catalog and keep the requested family unchanged.
- For Codex CLI workers, query its account/provider catalog with the bundled resolver:

```bash
executor_model=$(python3 "$DEVKIT_HOME/bin/devkit-model" luna < /dev/null) || exit 1
```

- Resolve `DEVKIT_HOME` from the loaded devkit skill's canonical clone when the environment variable is absent.
- Replace `luna` with the workflow's requested family. When effort is explicitly requested, append
  `--effort "$executor_effort"` and pass that same effort to the worker. The resolver uses
  [`model/list`](https://developers.openai.com/codex/app-server#list-models-modellist), includes all result pages,
  selects the newest visible numbered release and validates an explicitly requested effort. It creates no thread or browser.
- Record the effective effort from the worker's startup metadata. Keep model and effective effort consistent within
  one pass, including rechecks; resolve again for the next pass.
- Use Claude's unversioned family aliases (`opus`, `sonnet`, `haiku`) for Claude CLI workers.
- A missing family, unsupported effort or failed catalog lookup blocks that dispatch. Report the prerequisite and resume after it is resolved; use catalog-confirmed releases rather than remembered releases or an invented `latest` alias.
