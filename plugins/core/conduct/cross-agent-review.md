# Cross-Agent Peer Protocol

Two distinct protocols live here:

- **Review cross-check** — for any review skill: run the review in the calling agent first, then, only when the caller is Claude Code, cross-check by running the same review in Codex and merging the relevant findings. Mandatory when its gate holds; defined in [When this applies](#when-this-applies) and [Procedure](#procedure).
- **[Peer CLI invocation](#peer-cli-invocation)** — direction-agnostic mechanics for driving the other CLI non-interactively and read-only. Shared by the review cross-check above and by the manually-triggered `devkit-crosscheck` skill, which defines its own gate and is bidirectional.

**The review cross-check is MANDATORY, not optional.** When the three gating conditions below hold, you MUST run it. It is not a "proportional", "nice-to-have", or "use-judgement" step — there is no discretion to skip it because the change looks small, the review looks clean, or running Codex feels slow. Omitting the cross-check while the gate is open is a **protocol violation**, not a permissible shortcut. If you catch yourself reasoning "this is probably fine without Codex", stop — that reasoning is exactly what this rule forbids.

## When this applies

Apply in any review skill (deep, fast, business-logic, logging, plan) after it has produced its own findings. The cross-check runs whenever **all** of these hold:

1. You are **Claude Code** (not Codex, Cursor, or any other agent).
2. You are the **top-level review invocation** — the skill the user (or a non-review caller) invoked directly. Defer the cross-check when you were dispatched as a subagent/variant by a review orchestrator; return your report to the orchestrator and let it run the cross-check once.
3. The `codex` CLI is available: `command -v codex` succeeds.

**Evaluate the gate explicitly — never assume it fails.** You MUST actually run `command -v codex` to settle condition 3; do not guess that Codex is absent. Skipping is permitted **only** when a condition genuinely fails, and when you skip you MUST say so and name the failing condition (e.g. `Codex cross-check: skipped — codex CLI not found`). A skip with no stated reason, or a skip while all three conditions hold, is a violation. Never recurse: when this same skill runs inside Codex, condition 1 is false, so Codex performs a plain native review with no further cross-check.

## Procedure

1. **Run the native review first.** Complete your own findings in full before invoking Codex. The cross-check augments your review; it never replaces it.
2. **Invoke Codex on the same scope, read-only.** Run the same review skill in Codex against the same change set, with no write access:

   ```bash
   codex exec --sandbox read-only --skip-git-repo-check \
     "Use the <codex-skill-slug> skill to review the same scope: <scope description>. \
      Review only — do not modify code. Output findings only, in the devkit review-findings-format \
      (defect type, finding, evidence as file:line, suggested fix), grouped by Blocking/Significant/Minor." \
     < /dev/null
   ```

   - `<codex-skill-slug>` is this skill's Codex symlink under `.codex/skills/` (e.g. `devkit-core--reviewer-fast`). Each skill names its own slug where it cites this protocol.
   - `<scope description>` is the exact thing you reviewed (working-tree diff, branch diff, named files, or the plan document), so both agents review the same thing.
   - Flags, stdin handling, and failure modes: [Peer CLI invocation](#peer-cli-invocation).
   - If the run fails, times out, or returns nothing, note `Codex cross-check: skipped (unavailable)` and present your own findings unchanged.
3. **Analyze Codex's findings — do not trust them blindly.** For each Codex finding, verify against the actual code before accepting it:
   - **Discard** findings that are duplicates of yours (same `file:line` + same defect), out of scope, unevidenced/speculative, or factually wrong when you check the cited code.
   - **Keep** findings that are valid, evidenced, in scope, and absent from your own list.
4. **Merge the kept findings into your report.** Place each into the matching severity bucket (and matching stack section, for orchestrators). Tag merged findings `(via Codex)` so provenance is visible. Preserve the existing presentation structure — do not collapse separate stack sections or restate the shared format.
5. **State the cross-check outcome** in one line: how many Codex findings were merged and how many discarded (e.g. `Codex cross-check: 2 findings merged, 3 discarded as duplicate/out-of-scope`).

## Peer CLI invocation

Shared mechanics for driving the other CLI non-interactively and read-only. Applies to the review cross-check above and to `devkit-crosscheck`.

### Claude Code → Codex

```bash
codex exec --sandbox read-only --skip-git-repo-check "<prompt>" < /dev/null
```

- Always end the invocation with `< /dev/null`. `codex exec` reads stdin to append a `<stdin>` block even when the prompt is a positional arg, so an inherited open pipe (common when launching in the background) never closes and codex blocks forever on "Reading additional input from stdin…"; `/dev/null` gives immediate EOF.
- `--sandbox read-only` is the write boundary. Never grant `workspace-write` or `--dangerously-bypass-approvals-and-sandbox` to a peer run.
- Add `-c tools.web_search=true` only when the task genuinely needs the network (reading a URL, checking upstream docs).
- Codex prints its reasoning trace before the answer; the final message is the last block. Use `-o <file>` (`--output-last-message`) when only the answer matters.
- If the output contains `failed to spawn code-mode host`, retry **once** with `--disable code_mode_host` added to the invocation. Codex does not exit non-zero here — it logs the error, runs with no shell access, and reports that it could not inspect the code; treat any such run as having produced nothing. Cause: the Homebrew cask ships only `bin/codex`, but the `code_mode_host` feature is `stable` and on by default in codex 0.144.x, so codex tries to spawn a host binary that was never installed. Permanent fix: install `codex-code-mode-host` alongside `codex` — it ships in the npm package `@openai/codex@<version>-<platform>` under `vendor/<target>/bin/`.

### Codex → Claude Code

```bash
claude -p "<prompt>" --permission-mode plan < /dev/null
```

- `--permission-mode plan` is the write boundary: the peer reads, greps, and runs read-only shell, but every edit tool is refused. Verified — a `-p` run under plan mode refuses to create a file and says so. Do not substitute `--allowedTools` for it; plan mode is the checked path.
- **The command must run outside the Codex sandbox.** Observed on macOS (codex 0.146): under both `--sandbox read-only` and `--sandbox workspace-write`, `claude -p` exits 1 with `Not logged in · Please run /login`; it succeeds only when the calling Codex session runs the command unsandboxed (approve the escalation when prompted). Other platforms unverified — treat the same symptom as the same cause. The peer's own write boundary is unaffected: `--permission-mode plan` still refuses every edit.
- Always end with `< /dev/null`, same as the Codex direction — an inherited open pipe can leave the peer waiting on stdin.
- Side effect: a plan-mode run may persist a plan file under `~/.claude/plans/`. Harmless; ignore it.
- `-p` prints the final answer only. Exit status is not a reliable success signal — judge the run by whether the text answers the prompt.

### Prompt requirements (both directions)

- Self-contained: the peer starts with an empty context. State the task, the repo path, the exact scope (files, diff, question), and the required output shape.
- Read-only intent: say "do not modify code / answer only".
- **No further delegation.** The prompt must instruct the peer to answer directly and never invoke another CLI, peer pass, or cross-check skill. Naming a skill slug is safe only where that skill's own gate blocks recursion (as the review gate does); otherwise name the task, not the skill.
- Budget: a peer run costs a full independent context. Run one peer pass per task, not one per sub-question.
