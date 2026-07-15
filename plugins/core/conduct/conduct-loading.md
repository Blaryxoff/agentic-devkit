# Conduct Loading

Enabled plugins define the eligible rule set; they do not make every conduct document mandatory context.

## Loading sequence

1. Ground in the user's target, named files, changed paths, plan scope, or failing behaviour.
2. Identify which enabled plugins, layers, and expected responsibilities the target actually touches. Infer concerns
   from artifact roles and user-visible behaviour; a missing validation, authorization, state, or failure path is itself
   a loading trigger even when the draft or diff does not mention it.
3. Read `overview.md` for each touched non-core plugin when it exists.
4. Open only the documents required by the target or a concrete risk:
   - changed responsibility, cross-layer flow, or new files → `architecture.md`, `anti_patterns.md`, layering rules;
   - authentication, authorization, external input, or secrets → `security.md`;
   - migrations, queries, models, transactions, or schema assumptions → database and enum rules;
   - exceptions, retries, or fallbacks → `error_handling.md`;
   - configuration or dependencies → `configs.md`, `dependencies.md`;
   - logs, metrics, or tracing → `logging.md`, `observability.md`;
   - state management → store/state rules;
   - plans or specifications → only the relevant spec and architecture documents;
   - tests, CLI, deployment, or git → only when the request directly targets them.
5. Stop loading when the opened rules cover both the implemented concerns and the responsibilities expected but absent.

Never read or enumerate a conduct directory wholesale to gather general context. An explicit whole-stack standards audit
may cover every document, but load and evaluate it in scoped groups instead of placing the entire corpus in context at
once.

Project-level `CLAUDE.md`, `AGENTS.md`, and `.cursor/rules/` override generic conventions and project-specific choices.
They must not relax applicable safety, security, approval, destructive-operation, or read/write-boundary requirements;
apply the stricter rule for those conflicts. Record the applied exception rather than loading unrelated conduct to
search for conflicts.
