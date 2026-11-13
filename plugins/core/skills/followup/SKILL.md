---
name: devkit-followup
description: >-
  publish task estimates or implementation/bugfix follow-ups. Use for "followup estimate", "implementation follow-up",
  "переоцени задачу", or "исправь замечания QA". Comment-only: devkit-comment; full pipeline: devkit-task.
---

# Followup

Complete the requested follow-up on each named tracker task and verify its saved tracker updates.
For estimation requests, gather the task context and publish the resulting estimate using **Estimation follow-up** below.
For implementation reports, resolve remaining implementation gaps and post verified work answering the QA remarks;
when none exist, use the task description as the report source.
Finish the selected path with its required tracker writes and read-back: estimates publish through **Estimation follow-up**;
implementation and bugfix reports publish only after step 6's deployment and remote-check gate or an explicit waiver.
A combined request remains open until its requested tracker updates are verified. Honor draft-only restrictions and
suppress equivalent updates already saved. If the gate blocks publication, keep the report pending and explain the
blocker in chat; never substitute a local-progress, blocker, or evidence-gap comment to bypass the gate.
Keep tracker state and environment deployment separate from implementation and local verification.
Prefer tracker MCP tools, authenticated APIs, and repository/runtime CLIs over browser interaction. Use a browser for
visual behavior and flows whose evidence cannot be obtained through those interfaces. Follow project-specific tracker
fallback instructions when a connector is unavailable; keep credentials out of output and skill files.

## Estimation follow-up

Select this path when the user requests an estimate or re-estimate, including obvious misspellings such as `estimage`
and `reestimage`, or asks to answer an estimation request in the linked discussion. Complete the tracker interactions
even when the calculation is performed as a separate part of the request.

1. **Read the current task.** Apply workflow step 1 to resolve the exact task and complete discussion. Read linked
   specifications, attachments, the current estimate field, and later scope decisions. For a comment anchor, read that
   comment in the full discussion. Identify what changed since the latest scoped estimate.
2. **Prepare the estimation context.** Make the current scope, earlier estimate, and new evidence available for the
   calculation. Use the resulting estimate with its metric and exclusions; distinguish total implementation time from
   remaining work. Continue with publication once the estimation data is ready.
   Estimation alone requires no implementation, deployment, or remote smoke checks; the QA reporting gates below
   apply to claims of completed fixes. Do not use `devkit-comment`'s verified-fix format for an estimation reply.
3. **Publish the result.** Running this workflow for estimation authorizes one estimate comment and an estimate-field
   update on each named task, unless the user requests draft-only, comment-only, or another explicit restriction.
   Discover the tracker's actual estimate field, unit, and total-versus-remaining meaning through tool schemas,
   metadata, and project policy. Select the single figure matching that field and the confirmed scope; do not sum
   mutually exclusive options or put remaining time into a total estimate field. If scope or field semantics leave
   multiple materially different values, ask only about that ambiguity before the affected write. Keep a supported
   comment update independent of an unavailable or ambiguous estimate field and report any incomplete field update.
   Post a concise estimate with its scope and material prerequisites; for re-estimation, explain the change from the
   previous figure. Skip an equivalent comment already posted for the same scope and evidence. Update only the
   estimate field, preserving status, assignees, spent time, and unrelated fields. Honor project mention policy.
4. **Read back both updates.** Verify the saved comment and numeric estimate with its unit against the intended result.
   If a write has an uncertain result, inspect the task before retrying to avoid duplicate comments. Report the task
   link, estimate, and verified comment/field outcome in chat, including any blocker. A chat-only estimate does not
   complete this path unless the user requested draft-only output. Stop here; skip the implementation workflow below.

## Implementation workflow

Maintain a persistent finding checklist in the existing task note or session scratchpad; record its location in the
conversation. Before the first edit, give every selected finding a source reference, expected behavior, owning
repository/branch/worktree, implementation state, verification evidence, and next action or concrete blocker.
Track deployment and tracker publication separately from implementation. Update the checklist after each finding
and before a handoff; read it when resuming after an interruption, then continue the next actionable item.
Treat a narrow correction as an update to the active follow-up unless the user explicitly cancels or replaces it.
For an explanatory question, answer the question first; do not infer a requested edit from criticism alone.

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
   Populate the finding checklist from this selected report before editing; retain unfinished items across user corrections.
3. **Find the owning checkout.** Inspect repository and worktree metadata, branches, and recent history to locate the
   implementation associated with the selected report. Corroborate the candidate with task references, affected paths, and
   commit/worktree evidence; a branch name or date alone is not proof. Read that checkout's `AGENTS.md`, project guidance,
   and hard Git rules before changing files. Preserve unrelated dirty changes and use the correct existing branch/worktree.
   Map each implementation variant to its owning branch; a shared backend and its client or theme may have separate
   source branches. Integrate through their contracts rather than copying whole trees or merging unrelated history.
   Record the verified source-branch decision for each variant before changing files. Continue that existing branch;
   create a replacement only when evidence shows why it cannot be used and record the reason and safe source.
   Keeping the current checkout untouched or separating findings is not by itself a reason to create new branches.
   Resolve checkout conflicts without disturbing unrelated work; ask about an unresolved ownership/access conflict
   while continuing independent findings.
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
6. **Confirm deployment and fast-test the target.** Apply `plugins/core/conduct/git-commit-workflow.md` §6 before
   any separately authorized deployment action. Before drafting or posting any implementation or bugfix report,
   identify the remote environment where the reporters can check the result and verify that its deployment containing every fix claimed
   in the reply has succeeded. Use the requested environment: a staging request needs verified staging deployment and
   checks, not an additional production release. Match the deployed revision to the fixes through deployment records.
   Treat core versions, active themes, artifact readiness, and health/readiness endpoints as rollout evidence only;
   they do not establish that the feature is available or works for its users.
   By default, map every proposed completion claim to a task-specific scenario on that deployed target: record the tenant or
   application variant, actual role, prerequisites, action, expected outcome, and observed result. Check required
   feature settings and permissions, then exercise the affected UI flow or API/runtime behavior and inspect its
   functional result; an HTTP 200 or a page loading does not establish that result. For authenticated features,
   sign in through the project's authorized test login path; guest probes do not cover authenticated behavior.
   For a feature rollout, cover its main user journey across the applicable deployed components, including the
   backend and active frontend/theme. Claim only the scope supported by these checks; a narrow smoke check cannot
   support a statement that the full task functionality is available. Record the target, deployed revisions,
   scenarios, and results in the user conversation.
   Local verification, green test jobs, a push, or an older successful deployment do not satisfy this gate. Apply it to
   existing fixes too; reuse remote results only when they cover the claimed fixes on the confirmed deployed revision.
   Monitor an in-progress deployment through available CI/deployment tools; keep progress in the user conversation.
   If a scenario cannot be exercised because the feature is hidden, disabled, or requires unavailable access or
   setup, explain what was confirmed and what remains untested, then ask the user for a test path or permission
   to report the confirmed deployment without that functional check. Keep the reply pending until they answer;
   do not enable features or change production settings without authorization. An approved exception permits
   reporting the supported deployment scope, but does not establish user availability or a functional pass.
   If deployment fails, is unavailable, or cannot be verified, or a remote check fails, withhold implementation/bugfix
   drafts and tracker replies and report the blocker to the user. Deployment itself still requires separate authorization.
   Waive deployment confirmation or remote checks only when the user explicitly requests or approves that exception;
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
8. **Close out.** Check the entire finding checklist before ending the turn: finish every actionable implementation
   and local-verification item, including those outside the latest correction. "Not implemented yet" is unfinished
   work, not a blocker. Pause unfinished work only for explicit user direction or a concrete missing input,
   authorization, access, or external dependency; record the affected item, attempted resolution, and next action.
   Continue independent items when one is blocked. A deployment or publication gate blocks that stage, not
   independent implementation or local checks. Report a blocked follow-up as pending, not complete.
   Summarize each finding as deployed and remotely verified, fixed and locally verified only, fixed with
   a verification gap, still blocked, or not addressed, with concise evidence and relevant file references.
   Separate implementation, QA, task comment/status, and deployment evidence. Do not commit, push, deploy, or mutate
   production unless separately requested. Report each task's publication outcome: posted and read back, equivalent update
   already saved and verified, draft-only, or the explicit deployment/check/write/read-back blocker. A blocked or
   unverified publication is not a completed follow-up.

## Boundaries

- Invoke this skill for multi-task tracker QA repair requests such as “fix QA issues in these tasks” and “исправь
  замечания QA”, including reconciliation after fixes are already complete and tasks with no QA remarks.
  Keep that reconciliation in this workflow; invoke `devkit-comment` alone for a fix-report-only request. Invoke
  `devkit-task` for a full specification-to-pushed-branch pipeline.
- Route estimate and re-estimate follow-ups through **Estimation follow-up**. Preparing an estimate does not complete
  the requested tracker interactions.
- Follow the current task discussion over stale task descriptions and earlier QA remarks.
- Keep unrelated CI failures, baseline test failures, deployment diagnostics and investigation notes in the user
  conversation. Do not post them to the requested task or to other feature tasks, create tickets for them, or tag owners
  as an ancillary action of this workflow. A generic request to "hand off blockers" is not authorization for tracker
  writes or mentions; a separate tracker request must identify its destination and intended content.
- Use the task description as the report source only after confirming that the complete discussion contains no QA remarks.
- Draft or post implementation and bugfix reports only after deployment is green and focused checks of the claimed fixes
  pass on the deployed remote target, unless the user explicitly waives the missing gate. Local checks alone are insufficient.
  For hidden or disabled features and unavailable test prerequisites, use step 6's user fallback before stopping.
  Keep deployment blockers and pending-deployment wording out of tracker comments. When this gate blocks a comment,
  report in chat and withhold the tracker write; do not redirect it to another task or reclassify it as a diagnostic handoff.
- Do not post a comment when the user asked only for a draft. For implementation reports, require unreported verified
  completed work.
- Do not move tasks to “Testing” merely because code or tests are complete; require explicit user authorization.
- Do not deploy or change production data as part of this workflow. Establish server availability through deployment
  and environment evidence before claiming it.

