---
name: devkit-qaheal
description: >-
  resolve tracker QA findings or reconcile already completed fixes. Use when asked "fix QA issues in these tasks" or
  "исправь замечания QA". Comment-only: devkit-comment; full pipeline: devkit-task.
---

# QA Heal

Resolve the current actionable QA findings in the named tracker tasks, then report only outcomes supported by evidence.
Keep tracker state and environment deployment separate from implementation and local verification.
Prefer tracker MCP tools, authenticated APIs, and repository/runtime CLIs over browser interaction. Use a browser for
visual behavior and flows whose evidence cannot be obtained through those interfaces. Follow project-specific tracker
fallback instructions when a connector is unavailable; keep credentials out of output and skill files.

## Workflow

1. **Resolve each task.** Discover the available tracker MCP or CLI tools and inspect their schemas. For a human-facing
   task key, search by the exact key, select the exact matching key, then use the internal ID returned by search for every
   read or write. Preserve its native type; never derive internal IDs from visible keys. Read the complete discussion,
   following all pages and text chunks; if completeness cannot be verified, say so and do not assume omitted comments are absent.
2. **Select current findings.** Follow the newest comments and status changes. Work on actionable findings that remain
   open or were reopened. Treat older fixed notes as context, not new work. Map every finding to its expected behavior,
   reporter evidence, and current resolution state before editing.
3. **Find the owning checkout.** Inspect repository and worktree metadata, branches, and recent history to locate the
   implementation associated with the QA report. Corroborate the candidate with task references, affected paths, and
   commit/worktree evidence; a branch name or date alone is not proof. Read that checkout's `AGENTS.md`, project guidance,
   and hard Git rules before changing files. Preserve unrelated dirty changes and use the correct existing branch/worktree.
   Map each implementation variant to its owning branch; a shared backend and its client or theme may have separate
   source branches. Integrate through their contracts rather than copying whole trees or merging unrelated history.
   Follow the project's operator and designer Git routes. When operators may work directly on the default branch,
   do not require a PR solely for deployment. Preserve an active checkout with a clean worktree for the authorized
   integration or release; retain any separate designer PR requirements.
   If ownership remains ambiguous, continue independent findings and ask about only the blocked one.
4. **Reconcile existing fixes, then close gaps.** Compare each current QA remark's full body with the associated
   implementation, relevant development-session evidence, and resulting behavior. Support invocation after fixes were
   completed: establish which remarks are fully addressed, partially addressed, or still open. Reuse supported
   verification results; when all findings are already resolved, proceed to the deployment gate and reply without
   making redundant edits or repeating adequate checks. Treat verified, unreported existing fixes as eligible for the
   reply even when this invocation makes no code changes. Pass their development-session scope to `devkit-comment`.
   Use `devkit-coder` only for remaining implementation gaps. Make the smallest complete change that addresses the
   reproduced cause; preserve the project's conventions and existing tests. Do not broaden the task to unrelated cleanup.
   Keep staging configuration, credentials, deploy failures, and application defects as distinct findings: diagnose and
   report environment/deployment problems without disguising them as code fixes or implying that a local fix deployed.
5. **Verify locally.** Use `devkit-verify` for requested verification and `devkit-lunaqa` by default for local
   browser/runtime retests of user-visible findings. Prefer native APIs, fixtures, or CLI tools for setup and data
   preparation; use the browser for behavior that needs runtime/UI evidence. Pin the checkout, origin, tenant, and
   application variant through runtime evidence before dispatching dependent checks; a listening port or HTTP 200 alone
   does not prove the right implementation is running. Match package/API contract artifacts to the tested source
   revision before using them for build checks. Follow each project's authorized local
   login and fixture path. Record the actual checks and results; never claim a pass for an unexecuted or blocked check.
   Do not run a suite expected to take over two minutes without user confirmation. A focused check may establish a narrow
   fix, but must not be presented as full task acceptance.
6. **Wait for deployment.** Before posting, identify the environment where the reporters can check the result and
   verify that its deployment containing every fix claimed in the reply has succeeded. Match the deployed revision to
   the fixes through deployment records and confirm that the environment is available for checking. Local verification,
   green test jobs, a push, or an older successful deployment do not satisfy this gate. Monitor an in-progress deployment
   through available CI/deployment tools; keep progress in the user conversation. If deployment fails, is unavailable,
   or cannot be verified, withhold the tracker reply and report the blocker to the user. Deployment itself still requires
   separate authorization. Bypass this gate only when the user explicitly asks to post before a green deployment;
   honor that request without adding "Deploy is pending", equivalent caveats, or unsupported availability claims.
7. **Update the tracker.** After the deployment gate or its explicit exception, use `devkit-comment` to post one concise
   continuation per affected task, describing only verified, unreported fixes when the user requested comments or
   explicitly invoked this workflow. For an
   ordinary repair request without posting authorization, prepare a draft instead. Mention the reporters it addresses
   using supported native mention identities. Describe corrected behavior in language the reporters understand; keep
   tool names, test frameworks, CI job details, and routine verification results in the user conversation, not the
   tracker comment. Then read the comment back and verify its content and mentions. Never infer
   deployment from a branch or local check. Change a task to a discovered “Testing” status only when the user explicitly
   authorized that status change; resolve the exact status through tracker metadata and read back the saved status. Do not
   change assignees or other fields. If no unreported fix can be verified, do not post a generic update.
8. **Close out.** Summarize each finding as fixed and locally verified, fixed with a verification gap, still blocked, or
   not addressed, with concise evidence and relevant file references. Separate implementation, QA, task comment/status,
   and deployment evidence. Do not commit, push, deploy, or mutate production unless separately requested.

## Boundaries

- Invoke this skill for multi-task tracker QA repair requests such as “fix QA issues in these tasks” and “исправь
  замечания QA”, including reconciliation after fixes are already complete. Keep that reconciliation in this workflow;
  invoke `devkit-comment` alone for a comment-only request. Invoke `devkit-task` for a full specification-
  to-pushed-branch pipeline.
- Follow the current task discussion over stale task descriptions and earlier QA remarks.
- Post verified fixes only after their deployment is green and available to reporters, unless the user explicitly
  requests an earlier comment. Keep deployment blockers and pending-deployment wording out of tracker comments.
- Do not post a comment when the user asked only for a draft or when no unreported verified fix can be established.
- Do not move tasks to “Testing” merely because code or tests are complete; require explicit user authorization.
- Do not deploy or change production data as part of this workflow. Establish server availability through deployment
  and environment evidence before claiming it.

