# Token Optimization

Guidelines for reducing AI token consumption without sacrificing output quality.

## Model routing

- Use the most cost-effective model that can handle the current task.
- Reserve high-capability models (Opus-class) for deep architectural reasoning, complex debugging, and multi-system design.
- Use standard models (Sonnet-class) for routine implementation, refactoring, and single-file changes.
- Use fast models for simple lookups, formatting, and mechanical tasks (renaming, import sorting).
- Switch models explicitly when task complexity changes mid-session.

## Thinking budget

- Constrain extended thinking tokens when the task is straightforward.
- Deep thinking is valuable for architectural decisions, subtle bugs, and security analysis.
- Deep thinking is wasteful for boilerplate generation, simple CRUD, and mechanical refactoring.

## Subagent efficiency

- Prefer subagents over main-context work for isolated, well-scoped subtasks (single-file review, targeted search, independent module work).
- Each subagent spawns its own context window — use them for parallelism, not for sequential steps that share state.
- Pass subagents only the context they need for their assigned task.

## Prompt discipline

- Reference large files by path when the path gives enough context.
- When asking for changes, specify the file and function rather than describing the location.
- Batch related questions into a single prompt rather than asking one at a time.
- Provide acceptance criteria upfront to reduce revision loops.

## Anti-patterns

- Running the same expensive model for every task regardless of complexity.
- Leaving all MCP servers enabled globally when only 2-3 are needed per project.
- Asking open-ended questions that require the model to explore broadly when a targeted question would suffice.
- Repeatedly re-reading the same large files across turns instead of keeping relevant context compact.
