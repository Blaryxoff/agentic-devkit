---
name: devkit-git-review
description: interactive git-diff annotation review — generate a cleaned-up diff, open it in $EDITOR for the user to annotate, then address the annotations in a loop. Use when the user says "git review", "review my changes", "annotate changes/diff", or "interactive review". For a non-interactive correctness/architecture pass use devkit-reviewer-fast / devkit-reviewer-deep instead.
---

# Git Review (interactive annotation)

> Adapted from `umputun/cc-thingz` (MIT).
> Bundled-script paths resolve under the devkit clone root (`~/.claude/agentic-devkit` = `DEVKIT_HOME`), not the project root.

Interactive, annotation-based review: the user writes review comments directly into a diff, you fix the code, repeat until the diff comes back clean.

## When to use

- "git review", "review my changes", "review changes"
- "annotate changes", "annotate diff", "interactive review", "review diff"

For a one-shot reviewer report (correctness, regressions, architecture, security) use `devkit-reviewer-fast` or `devkit-reviewer-deep` — those do not loop through the editor.

## How it works

1. Script generates a cleaned-up diff file (friendly headers, no technical noise).
2. Opens it in `$EDITOR` via tmux popup, kitty overlay, or wezterm split-pane.
3. User adds annotations (comments, change requests) directly in the file.
4. Script returns the user's annotations as a git diff on stdout.
5. You read the annotations and fix the code in the real repo.
6. Script regenerates a fresh diff (reflecting the fixes) and opens again.
7. Loop until the user closes the editor without changes (no stdout).

## Workflow

### 1. Run the script

```bash
"$DEVKIT_HOME/plugins/core/skills/git-review/scripts/git-review.py" [base_ref]
```

`DEVKIT_HOME` defaults to `~/.claude/agentic-devkit`. If unset, resolve this skill's own symlink
(`~/.claude/skills/devkit-core--git-review`) to find the clone root.

- No argument: auto-detect — uncommitted changes if present, otherwise current branch vs default branch.
- With a ref: diff against it (`master`, `HEAD~3`, `v1.2.0`, a commit SHA).

### 2. Process annotations

If the script prints to stdout, the user annotated. The output is a git diff of what the user added/changed in the review file.

- **Added lines (`+`)**: the user's comments / change requests.
- **Removed lines (`-`)**: the user wants something removed or changed.
- **Modified (`-` then `+`)**: the user replaced text to show the desired change.

Each annotation sits in context — the surrounding `===` file headers and diff content show which file and code area it refers to.

### 3. Plan the changes

Plan the response using the harness's native plan mode when available; otherwise present it in chat. List each annotation, the file/code it targets, and the planned fix. Get approval before touching code. Resolve ambiguous annotations via `plugins/core/conduct/clarification-protocol.md` instead of guessing.

### 4. Address annotations

After approval, fix the real source. Each annotation is a directive — treat it as a code-review comment that must be addressed. Keep edits surgical per `plugins/core/conduct/surgical-changes.md`.

### 5. Loop

Run the script again. It regenerates a fresh diff reflecting the fixes and reopens the editor. The user either adds more annotations (→ step 2) or closes without changes (no stdout → done).

### 6. Done

No stdout → review complete. Tell the user.

## Script arguments

| Argument | Description |
|----------|-------------|
| (none) | auto-detect: uncommitted changes if present, otherwise branch vs default branch |
| `<ref>` | diff against a specific ref: `master`, `main`, `HEAD~5`, `v1.2.0`, … |
| `--clean` | remove the review tracking repo from `/tmp` |
| `--test` | run the embedded unit tests |

## Requirements

- `python3`
- tmux, kitty, or wezterm (for the editor overlay)
- `$EDITOR` set (defaults to `vi`; multi-word values such as `emacsclient -c` are supported)
- git
- kitty users: `kitty.conf` needs `allow_remote_control yes` and `listen_on unix:/tmp/kitty-$KITTY_PID`
