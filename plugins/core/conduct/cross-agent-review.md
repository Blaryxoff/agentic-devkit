# Cross-Agent Peer Protocol

Two distinct protocols live here:

- **Review cross-check** — complete the native review, then run the same review through the selected independent peer and merge verified findings. Mandatory when its gate holds; defined in [When this applies](#when-this-applies) and [Procedure](#procedure).
- **[Peer CLI invocation](#peer-cli-invocation)** — shared selection, permission and result rules for a non-interactive peer. `devkit-crosscheck` defines its own manual trigger; `devkit-pair` steers an existing session instead of launching a subprocess.

Run the review cross-check whenever its gate holds. A small change or a clean native review does not waive it.

## When this applies

Apply in any review skill (deep, fast, business-logic, logging, plan) after it has produced its own findings. The cross-check runs whenever **all** of these hold:

1. You are the **top-level review invocation** — the skill the user (or a non-review caller) invoked directly. A dispatched reviewer or subprocess worker returns findings to its owner without another peer pass. `DEVKIT_FEEDBACK_WORKER=1` marks a subprocess worker.
2. An independent peer is selected under [Peer selection](#peer-selection), its executable is available, and its review write boundary is established. The caller and peer may use the same harness or model; they must have separate conversations.
3. The selected peer did not already contribute to these findings in a completed, non-degraded revmux pass. Check `sources.agents` against the selected executor; a configured roster entry, degraded source or different peer does not satisfy the check. See [revmux-review.md](./revmux-review.md).

Check the selected executable with `command -v`; do not infer availability from its name. If selection is missing or ambiguous, ask which peer to use while completing the native review. Report an unavailable or unresolved peer as `Peer cross-check: skipped — <reason>`; never silently substitute another agent. A worker never reopens this gate, including a Codex worker launched by Codex.

## Procedure

1. **Run the native review first.** Complete your own findings before invoking the selected peer.
2. **Invoke the peer on the same scope, read-only.** Follow [Peer CLI invocation](#peer-cli-invocation). Supply the exact change set, relevant review rules and output format. Resolve skill names from the peer's catalog when using a skill; otherwise provide a self-contained review brief. Require a direct answer with no edits or further delegation. A failed, timed-out or empty pass leaves the native findings intact and the cross-check incomplete.
3. **Verify the peer's findings against the actual code:**
   - **Discard** findings that are duplicates of yours (same `file:line` + same defect), out of scope, unevidenced/speculative, or factually wrong when you check the cited code.
   - **Keep** findings that are valid, evidenced, in scope, and absent from your own list.
4. **Merge verified findings into your report.** Preserve severity buckets and stack sections; tag additions `(via <peer>)`.
5. **State the outcome** in one line with the peer identity and merged/discarded counts.

## Peer CLI invocation

Apply these mechanics from any caller to the selected peer, including another session of the same harness. Follow [shell-invocation.md](./shell-invocation.md). QA worker permissions are defined separately in [browser-qa-rules.md §12.7](./browser-qa-rules.md#12-lane-briefs).

### Peer selection

1. Use the peer explicitly requested for this task; otherwise use the consuming project's documented preference, then the user's global preference. A task-specific choice overrides an earlier default.
2. Record the peer's identity, transport, executable or session/thread ID, working directory, output channel and write boundary. The CLI name and the model name are separate choices.
3. Use `devkit-pair` when the user selected an already-running session. Do not replace that session with a subprocess. A CLI workflow requires an explicitly selected CLI or permission to start an independent peer conversation.
4. Ask for the missing selection when no preference exists or several sessions match; continue independent native work while waiting. The mere presence of `claude`, `cursor-agent`, `grok`, `gemini` or `codex` is not a preference.
5. Keep one peer conversation per task. Another Codex session is a valid peer; never resume the caller's own thread or select a different session merely because its checkout matches.

Use the known command forms below only for the selected CLI. For Gemini, Grok or any other CLI, inspect its installed help and current official documentation for non-interactive input, result extraction, resume support and enforced write restrictions. Record the verified command in the task scratchpad. Do not invent shared flags or silently reuse Claude's mode.

### Write boundary and invocation

- Establish an enforced repository write restriction for review and analysis: a documented sandbox or tool policy that blocks both edit tools and shell writes. A prompt saying "read-only" is not an enforcement mechanism. If the selected CLI cannot provide that boundary, use an existing restricted session or report the peer stage blocked; do not launch it unrestricted.
- Prefix every subprocess launch and resume with `DEVKIT_FEEDBACK_WORKER=1` and prohibit further delegation in the prompt.
- Redirect stdin from `/dev/null` when the prompt is an argument. An intentional prompt pipe/heredoc may own stdin instead; never inherit the calling harness's open input stream.
- Register additional peer executable basenames through `DEVKIT_PEER_COMMANDS` (comma-separated names, no shell syntax) when using the stdin guard with a custom CLI. This extends detection; it does not establish permission or read-only enforcement.
- Run from the exact repository or use the selected CLI's documented workspace option. Keep scratch output outside the checkout.

### Result channels

- Capture stdout and stderr in separate scratchpad files; read each directly. Judge findings and clean markers only
  on the final answer, never on stderr or a merged transcript. Use `-o <file>` or final `agent_message` events for Codex;
  use stdout for `claude -p`, and `.result` from Cursor's JSON output. For another CLI, verify its final-answer channel before judging findings. Codex echoes prompts on stderr, including severity definitions that are not findings.
  Keep stderr for failure diagnosis.
- Use fresh output paths for each pass and wait for completion before classifying the answer. An empty answer remains
  a failed review even when stderr has progress chatter or severity words; a timed-out/interrupted pass is incomplete.
- Read diagnostic files directly rather than through buffered `tail`/`head` pipelines. A blocked peer shows near-zero CPU
  (`ps -o time=`) against minutes of elapsed time.

These channel rules are adapted from [cc-thingz planning](https://github.com/umputun/cc-thingz/tree/master/plugins/planning) (MIT).

### Codex peer

```bash
DEVKIT_FEEDBACK_WORKER=1 codex exec --sandbox read-only --skip-git-repo-check "<prompt>" < /dev/null
```

- `--sandbox read-only` is the write boundary. Never grant `workspace-write` or `--dangerously-bypass-approvals-and-sandbox` to a peer review/cross-check run.
- Codex prints its reasoning trace before the answer; the final message is the last block. Use `-o <file>` (`--output-last-message`) when only the answer matters.
- Treat a run without repository tools or access as failed, even when it exits zero. Resolve version-specific startup failures from installed help and current official documentation before retrying once.

### Claude Code peer

```bash
DEVKIT_FEEDBACK_WORKER=1 claude -p "<prompt>" --permission-mode plan < /dev/null
```

- `--permission-mode plan` is the write boundary: the peer reads, greps, and runs read-only shell, but every edit tool is refused. Verified — a `-p` run under plan mode refuses to create a file and says so. Do not substitute `--allowedTools` for it; plan mode is the checked path.
- Diagnose login failures separately from the peer's write policy. Caller sandbox access to credentials may differ; use an already-authorized host execution path only while preserving the peer's plan-mode restrictions.
- Side effect: a plan-mode run may persist a plan file under `~/.claude/plans/`. Harmless; ignore it.
- `-p` prints the final answer only. Exit status is not a reliable success signal — judge the run by whether the text answers the prompt.

### Cursor peer

```bash
DEVKIT_FEEDBACK_WORKER=1 cursor-agent -p --trust --mode plan --output-format json "<prompt>" < /dev/null
```

- Use `--mode ask` for answer-only questions. Preserve the selected mode's edit and shell restrictions; never add `-f` to a review launch.
- Read `.result` from the completed JSON output and reject missing or empty results. Plan mode is a tool policy, not an OS sandbox; verify its restrictions against the installed CLI before relying on it for a new version.
- Prefer `cursor-agent`; accept `agent` only after resolving it to the same Cursor executable. An unrelated command named `agent` is not a peer selection.

### Persistent subprocess peer sessions

Applies only to **subprocess** peers this session starts. It does not apply to
`devkit-pair`, which talks to an interactive session the operator already has open and forbids these commands entirely.

A one-shot subprocess starts from an empty context unless an explicit thread is supplied. When a workflow drives the same
subprocess peer across several rounds, open its session once and resume it — the peer keeps what it already learned,
and each round costs only the new prompt. The "Prompt requirements" below describe the first round; a resumed round
carries the earlier context and need not restate it.

**Codex.** Capture the `thread.started` ID from `--json`, then resume it:

```bash
ROUNDS=$(mktemp -d)   # outside the repo — never write scratch JSONL into the checkout
DEVKIT_FEEDBACK_WORKER=1 codex exec --json --sandbox read-only --skip-git-repo-check "<bootstrap prompt>" < /dev/null \
  > "$ROUNDS/round-0.jsonl"
# {"type":"thread.started","thread_id":"01a0a189-b1b8-7611-9082-c59ad93e2a38"}
PEER=$(head -1 "$ROUNDS/round-0.jsonl" | jq -r .thread_id)

DEVKIT_FEEDBACK_WORKER=1 codex exec resume "$PEER" --json --skip-git-repo-check -c sandbox_mode='"read-only"' "<next prompt>" < /dev/null
```

- **`codex exec resume` has no `--sandbox` flag.** It falls back to `sandbox_mode` in `~/.codex/config.toml`, which on
  many machines is `danger-full-access`. Pass `-c sandbox_mode='"read-only"'` on **every** resume — the flag is the write
  boundary, and omitting it silently hands the peer full write access to the repo.
- Read the session id from `--json`'s `thread.started` event. Codex writes a rollout file for each internal subagent too,
  so modification time can identify a subagent id that fails to resume with `cannot resume an unloaded multi-agent v2 sub-agent`.
- `--json` also yields the answer without the reasoning trace:
  `jq -r 'select(.type=="item.completed" and .item.type=="agent_message") | .item.text'`.
- `-m <model>` works on `resume`, so a cheap tier can answer a cheap round in the same thread.

**Claude Code.** Mint the id yourself, then resume it:

```bash
SID=$(uuidgen | tr 'A-Z' 'a-z')
DEVKIT_FEEDBACK_WORKER=1 claude -p --session-id "$SID" --permission-mode plan "<bootstrap prompt>" < /dev/null
DEVKIT_FEEDBACK_WORKER=1 claude -p --resume  "$SID" --permission-mode plan "<next prompt>" < /dev/null
```

**Cursor.** Take the session ID from the completed JSON output, then use `--resume <session_id>` with the same workspace, read-only mode and JSON output flags on each round. Verify the installed CLI's session-ID field rather than guessing it.

**Other peers.** Resume only through their documented session mechanism; if unavailable, send a fresh self-contained brief. Never drop the write boundary to keep context.

**Exit status is not a success signal.** A resumed Codex round that answered correctly was observed
exiting 1. Judge every round by whether its text answers the prompt; treat empty output as a failed round.

### Prompt requirements

- Self-contained: the peer starts with an empty context. State the task, the repo path, the exact scope (files, diff, question), and the required output shape.
- Read-only intent: say "do not modify code / answer only".
- **No further delegation.** The prompt must instruct the peer to answer directly and never invoke another CLI, peer pass, or cross-check skill. Naming a skill slug is safe only where that skill's own gate blocks recursion (as the review gate does); otherwise name the task, not the skill.
- Budget: a peer run costs a full independent context. Run one peer pass per task, not one per sub-question.
