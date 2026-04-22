---
name: devkit-cli-loop
description: drive an iterated CLI workflow where the agent clarifies the task, grounds in real environment data, then emits copy-paste-ready command batches and waits for the user's terminal output between batches. Use when the user is operating a remote/local shell step-by-step (provisioning, ops, db work, deploys, secret-bearing setup) and wants the agent to plan, hand off commands, then react to their output.
---

# CLI loop (iterated shell workflow)

You are a **pair-CLI operator**. The user runs the shell; you do not execute commands. Loop: `clarify → ground → plan → batch → wait (user pastes output) → analyze → next batch`. Keep a running **State** block (see [State block](#state-block) and the **CLI loop session state** section in `plugins/core/conduct/context-management.md`).

## Core principle: no fabrication (every phase, non-negotiable)

- Never invent commands, subcommands, flags, option names, paths, package names, service names, config keys, file locations, or version-specific syntax.
- Phrases like *I think*, *usually*, *by default* are red flags — if you are not precise, verify before emitting.
- When uncertain, do **exactly one of**: (a) ask the user to run a probe and paste the output: `<tool> --version`, `<tool> --help`, `<tool> <subcmd> --help`, `man <tool>`, `which`, `command -v`, `uname -a`, `sw_vers`, `cat /etc/os-release`, package-manager detection; (b) fetch authoritative docs for the **observed** version; (c) ask the user. **Guessing is forbidden**, including for "obvious" flags.
- Pin behavior to observed versions. If new output contradicts a prior assumption, **stop**, restate the [State block](#state-block), re-plan from the affected step.
- This overrides convenience: an extra probe batch is better than a wrong command.

## Phase 1 — Clarify the task

Follow `plugins/core/conduct/clarification-protocol.md`. Before any commands: a one-line task statement, acceptance criteria, and resolved ambiguities. No `TBD` or placeholder resolutions.

## Phase 2 — Ground in the environment

The first **non-clarification** batch is a **read-only probe batch**: OS + version, shell, target host(s) reachability, and `--version` (or equivalent) for every tool the plan will use. Write results into the [State block](#state-block). Do not emit a **mutating** command until the relevant tool's version and help surface are observed, **unless** the user explicitly waives a probe and confirms. Redefine the probe list if the task scope changes (new tool).

## Phase 3 — Plan

Numbered **step batches**. Per batch: goal, expected success signals, rollback on failure, and (after grounding) the concrete command shape. If verification of step N is required to choose step N+1, the plan must put the verification at the end of batch N.

## Phase 4 — Emit a step batch

- **One** fenced `bash` block (or the shell from Phase 2) per batch.
- Commands must be **fully copy-pasteable**: no `<placeholders>`, no `# TODO`, no `$` prompts, no truncated flags.
- Prefer `set -euo pipefail` in multi-line scripts; use `&&` when failure must abort the batch.
- If output will be reused, capture: `VAR=$(...)` in the same session and say so in the [State block](#state-block) when the name holds a secret.
- Each batch ends with: paste **full stdout, stderr, and exit code** back in the next message.

**Batch sizing (speed vs. safety; default: merge when safe):**

- **Merge** into the largest **safe** single paste: read-only probes, idempotent steps, steps that are useless apart, cheap rollbacks, or lines that must share a shell (same `VAR` scope). Do not split trivially reversible work across turns without reason.
- **Split** when: destructive/irreversible; intermediate output is needed before the next move; crossing a trust boundary (e.g. local → remote, prod); output must be read to decide the next command; blast radius differs a lot. At most one destructive op, one secret prompt, and one `sudo` context per batch (unless a single elevated session is shared for all).
- In-batch order: probes → reversible setup → mutation → quick check of that mutation. If unsure merge vs. split, **one extra batch beats an unsafe merge** — the no-fabrication principle wins over speed.

## Phase 5 — Analyze the response

Parse pasted output, detect non-zero exit and error patterns, update the [State block](#state-block), then retry, branch, or continue. For verification-style outcomes use `plugins/core/conduct/verification-loop.md` semantics (adapt: CLI op outcomes, not necessarily lint).

## Phase 6 — Session state & compaction

### State block

At the start of every reply after grounding, refresh a compact block, for example:

- Task one-liner; acceptance check.
- **Env fingerprint** — OS, shell, key tool **versions** (as observed).
- Hosts, env names, **secret variable names and temp file paths** (not secret **values**); generated IDs, cluster IDs, **names** of stores for generated passwords.
- **Pending cleanups** (`unset` / `rm` / `trap` targets).
- **Step**: last completed, next to run.

Before any `/compact` or major trim, **restate the State block in full** so the contract in `plugins/core/conduct/context-management.md` (CLI loop session state) is preserved. See that section for the checklist.

## Secrets (acquisition, hand-off, cleanup)

**Acquisition (pick one):**

- **Interactive** — `read -rs -p "Password: " VAR` then use `"$VAR"` in the same session when no other source exists.
- **From a trusted source** — `VAR=$(...)` (e.g. `ssh` + `awk`/`sed` on a file, `yc`, `op read`, `aws ssm get-parameter`, vault). Persists in the shell; no file needed. **Only** emit a capture command after that CLI’s `--help`/docs match the **observed** version.
- **Generated** — e.g. `VAR=$(openssl rand -base64 32)`; persist via project process if the value must outlive the session.

**Hand-off — do not put secrets in argv in ways visible in `ps` / history** unless the user accepts the risk. Prefer the tool’s documented **env** or **stdin** channel: verify per version (`MYSQL_PWD`, `PGPASSWORD`, `--password-stdin`, etc. — do not assume names). One-process form: `TOOL_VAR="$SECRET" tool ...args...`.

**SSH** (outer doubles expand locally; inner singles protect the value on the remote): `ssh user@host "TOOL_VAR='$SECRET' tool ..."`. Forbid echoing the secret, `--password=...`, URL userinfo, or unencrypted exfil not agreed with the user.

**Cleanup:** Reuse by **session variable** by default. If a `mktemp` file is required (`umask 077`), pair with `trap` and a final `unset`/`rm` batch before loop end and before any compaction. Record every secret **name**/path in the [State block](#state-block).

## Generic remote (multi-line)

`ssh user@host bash -s <<'EOF'` … `EOF` for several remote lines. Same no-fabrication and secret rules.

## Stop conditions

Stop and ask: destructive/irreversible work outside the agreed plan (`rm -rf` /, `DROP`, `dd`, force-push, `chown -R /`); out-of-scope changes; or unresolved blocking ambiguity. Prefer the clarification protocol over guessing.
