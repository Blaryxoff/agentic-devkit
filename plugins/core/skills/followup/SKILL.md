---
name: devkit-followup
description: >-
  post ticket comments after QA repair or reconciliation. Use when asked "fix QA issues in these tasks" or
  "исправь замечания QA". Comment-only: devkit-comment; full pipeline: devkit-task.
---

# Followup

Post a ticket comment reporting verified work on each named tracker task, resolving any remaining implementation gaps first.
Answer existing QA remarks; when no QA remarks exist, treat the task description as the report to address in the same format.
Keep tracker state and environment deployment separate from implementation and local verification.
Prefer tracker MCP tools, authenticated APIs, and repository/runtime CLIs over browser interaction. Use a browser for
visual behavior and flows whose evidence cannot be obtained through those interfaces. Follow project-specific tracker
fallback instructions when a connector is unavailable; keep credentials out of output and skill files.

## Workflow

1. **Resolve each task.** Discover the available tracker MCP or CLI tools and inspect their schemas. For a human-facing
   task key, search by the exact key, select the exact matching key, then use the internal ID returned by search for every
   read or write. Preserve its native type; never derive internal IDs from visible keys. Read the complete discussion,
   following all pages and text chunks; if completeness cannot be verified, say so and do not assume omitted comments are absent.
   Fix the tracker write scope to the tasks explicitly named by the user or unambiguously selected from the current
   task context. Reading linked tasks or finding owners during investigation does not authorize writing to those tasks.
2. **Select the report source.** Follow the newest comments and status changes. When QA remarks exist, work on actionable
   findings that remain open or were reopened. Treat older fixed notes as context, not new work. When the complete
   discussion contains no QA remarks, use the task description and its acceptance criteria as the report to address;
   apply later clarifications and scope decisions. Resolved or already answered QA remarks do not trigger this fallback.
   Map every finding or requirement to its expected behavior, source evidence, and current resolution state before editing.
3. **Find the owning checkout.** Inspect repository and worktree metadata, branches, and recent history to locate the
   implementation associated with the selected report. Corroborate the candidate with task references, affected paths, and
   commit/worktree evidence; a branch name or date alone is not proof. Read that checkout's `AGENTS.md`, project guidance,
   and hard Git rules before changing files. Preserve unrelated dirty changes and use the correct existing branch/worktree.
   Map each implementation variant to its owning branch; a shared backend and its client or theme may have separate
   source branches. Integrate through their contracts rather than copying whole trees or merging unrelated history.
   Follow the project's operator and designer Git routes. When operators may work directly on the default branch,
   do not require a PR solely for deployment. Preserve an active checkout with a clean worktree for the authorized
   integration or release; retain any separate designer PR requirements.
   If ownership remains ambiguous, continue independent findings and ask about only the blocked one.
4. **Reconcile existing fixes, then close gaps.** Compare the full text of each selected QA remark or description requirement
   with the associated implementation, relevant development-session evidence, and resulting behavior. Support invocation after fixes were
   completed: establish which remarks are fully addressed, partially addressed, or still open. Reuse supported
   verification results; when all findings are already resolved, proceed to the deployment gate and reply without
   making redundant edits or repeating adequate checks. Treat verified, unreported existing fixes as eligible for the
   reply even when this invocation makes no code changes. Apply the same reconciliation to completed description requirements.
   Pass the selected report source and development-session scope to `devkit-comment`.
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
6. **Confirm deployment and fast-test the target.** Before drafting or posting a ready comment, identify the remote
   environment where the reporters can check the result and verify that its deployment containing every fix claimed
   in the reply has succeeded. Use the requested environment: a staging request needs verified staging deployment and
   checks, not an additional production release. Match the deployed revision to the fixes through deployment records, then run a focused
   smoke check of each claimed fix on that deployed remote
   target. Use the affected UI flow or API/runtime behavior and confirm the expected outcome; server availability or
   HTTP 200 alone is insufficient. Record the target, deployed revision, checks, and results in the user conversation.
   Local verification, green test jobs, a push, or an older successful deployment do not satisfy this gate. Apply it to
   existing fixes too; reuse remote results only when they cover the claimed fixes on the confirmed deployed revision.
   Monitor an in-progress deployment through available CI/deployment tools; keep progress in the user conversation.
   If deployment fails, is unavailable, or cannot be verified, or a remote check fails or is blocked, withhold ready
   drafts and tracker replies and report the blocker to the user. Deployment itself still requires separate
   authorization. Waive deployment confirmation or remote checks only when the user explicitly requests that exception;
   a request for comments alone is not a waiver. Honor an explicit exception without adding "Deploy is pending",
   equivalent caveats, or unsupported deployment or verification claims.
7. **Update the tracker.** After the deployment and remote-check gate or its explicit exception, use `devkit-comment`
   to post one concise continuation per requested task, describing only verified, unreported fixes or completed requirements
   that directly address that task's selected report. A request to run this workflow authorizes those comments only;
   honor an explicit draft-only request instead.
   Use the same comment format for QA replies and description-based reports. Mention the reporters it addresses
   using supported native mention identities; when the source is the description, resolve recipients under `devkit-comment`
   without inventing a QA reporter. Pass the project's task-comment policy, verified deployment/runtime
   identifiers and rollout times, and remote-check scenarios/results/roles to `devkit-comment` for any required details.
   When the claimed fixes are confirmed deployed to production, require the draft or posted comment to say so explicitly.
   Identify the production environment by its established name or URL when useful; staging evidence alone does not qualify.
   Describe corrected behavior in
   language the reporters understand; keep tool names, test frameworks, CI job details, and routine verification
   results in the user conversation, not the
   tracker comment. Then read the comment back and verify its content and mentions. Never infer
   deployment from a branch or local check. Change a task to a discovered “Testing” status only when the user explicitly
   authorized that status change; resolve the exact status through tracker metadata and read back the saved status. Do not
   change assignees or other fields. If no unreported completed work can be verified, do not post a generic update.
8. **Close out.** Summarize each finding as deployed and remotely verified, fixed and locally verified only, fixed with
   a verification gap, still blocked, or not addressed, with concise evidence and relevant file references.
   Separate implementation, QA, task comment/status, and deployment evidence. Do not commit, push, deploy, or mutate
   production unless separately requested.

## Boundaries

- Invoke this skill for multi-task tracker QA repair requests such as “fix QA issues in these tasks” and “исправь
  замечания QA”, including reconciliation after fixes are already complete and tasks with no QA remarks.
  Keep that reconciliation in this workflow; invoke `devkit-comment` alone for a comment-only request. Invoke `devkit-task` for a full specification-
  to-pushed-branch pipeline.
- Follow the current task discussion over stale task descriptions and earlier QA remarks.
- Keep unrelated CI failures, baseline test failures, deployment diagnostics and investigation notes in the user
  conversation. Do not post them to the requested task or to other feature tasks, create tickets for them, or tag owners
  as an ancillary action of this workflow. A generic request to "hand off blockers" is not authorization for tracker
  writes or mentions; a separate tracker request must identify its destination and intended content.
- Use the task description as the report source only after confirming that the complete discussion contains no QA remarks.
- Draft or post ready comments only after deployment is green and focused checks of the claimed fixes pass on the
  deployed remote target, unless the user explicitly waives the missing gate. Local checks alone are insufficient.
  Keep deployment blockers and pending-deployment wording out of tracker comments. When this gate blocks a comment,
  report in chat and withhold the tracker write; do not redirect it to another task or reclassify it as a diagnostic handoff.
- Do not post a comment when the user asked only for a draft or when no unreported verified completed work can be established.
- Do not move tasks to “Testing” merely because code or tests are complete; require explicit user authorization.
- Do not deploy or change production data as part of this workflow. Establish server availability through deployment
  and environment evidence before claiming it.

