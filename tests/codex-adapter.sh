#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_link() {
  local path="$1"
  local target="$2"
  [ -L "$path" ] || fail "expected symlink: $path"
  [ "$(readlink "$path")" = "$target" ] || fail "unexpected target for $path"
}

assert_absent() {
  [ ! -e "$1" ] && [ ! -L "$1" ] || fail "expected absent: $1"
}

assert_contains() {
  grep -Fq -- "$2" "$1" || fail "expected $1 to contain: $2"
}

assert_not_contains() {
  if grep -Fq -- "$2" "$1"; then
    fail "expected $1 not to contain: $2"
  fi
}

skill_snapshot() {
  local skills_dir="$1"
  find "$skills_dir" -type l -print | sort | while IFS= read -r link; do
    printf '%s -> %s\n' "$(basename "$link")" "$(readlink "$link")"
  done
}

home="$TMP_DIR/home"
codex_home="$home/.codex"
cursor_home="$home/.cursor"
claude_home="$home/.claude"
mkdir -p "$codex_home/skills" "$cursor_home/skills" "$cursor_home/hooks" "$cursor_home/rules" "$claude_home"
jq -n '{beforeSubmitPrompt:[{hooks:[{type:"command",command:"custom-cursor-prompt-hook"}]}]}' \
  > "$cursor_home/hooks/hooks.json"
jq -n '{version:1,hooks:{sessionStart:[{command:"custom-native-cursor-hook"}]}}' \
  > "$cursor_home/hooks.json"
printf '%s\n' '---' 'description: "user authored cursor rule"' 'alwaysApply: true' '---' '' '# keep me' \
  > "$cursor_home/rules/user-authored.mdc"
printf '%s\n' \
  '[[hooks.PreToolUse]]' \
  '[[hooks.PreToolUse.hooks]]' \
  'type = "command"' \
  'command = "agterm-status pre-tool-use"' \
  '[mcp_servers.chrome-devtools]' \
  'command = "npx"' \
  'args = [' \
  '  "chrome-devtools-mcp@latest",' \
  '  "--experimentalPageIdRouting",' \
  '  "--headless=false",' \
  '  "--isolated",' \
  '  "--custom-flag"' \
  ']' \
  > "$codex_home/config.toml"
jq -n --arg coder "sh '$ROOT/plugins/core/hooks/coder-gate.sh'" \
  '{hooks:{Stop:[{hooks:[{type:"command",command:"plannotator",timeout:30}]}],PreToolUse:[{hooks:[{type:"command",command:$coder}]}]}}' \
  > "$codex_home/hooks.json"
ln -s "$ROOT/plugins/css/skills/css-a11y" "$codex_home/skills/devkit-css--css-a11y"
ln -s "$ROOT/plugins/core/skills/coder" "$codex_home/skills/devkit-core--retired"
ln -s "$ROOT/plugins/laravel/skills/architect" "$cursor_home/skills/devkit-laravel--architect"
ln -s "$ROOT/plugins/core/skills/coder" "$codex_home/skills/user-skill"
ln -s "$ROOT/plugins/core/skills/coder" "$cursor_home/skills/devkit-renamed"
ln -s "$ROOT/plugins/core/skills/removed-skill" "$cursor_home/skills/removed"
printf '%s\n' 'personal global guidance' > "$claude_home/CLAUDE.md"
printf '%s\n' 'personal codex guidance' > "$codex_home/AGENTS.md"
legacy_skill_eval="sh $ROOT/plugins/core/hooks/skill-eval.sh"
legacy_feedback_end="python3 $ROOT/plugins/core/hooks/jev-feedback.py session-end"
jq -n --arg legacy "$legacy_skill_eval" --arg oldend "$legacy_feedback_end" '{hooks:{UserPromptSubmit:[{hooks:[{type:"command",command:$legacy},{type:"command",command:"custom-prompt-hook"}]}],SessionEnd:[{hooks:[{type:"command",command:$oldend},{type:"command",command:"custom-session-end-hook"}]}]}}' \
  > "$claude_home/settings.json"

install_output=$(HOME="$home" CODEX_HOME="$codex_home" CURSOR_HOME="$cursor_home" DEVKIT_HOME_DIR="$ROOT" \
  bash "$ROOT/bin/devkit-install")

assert_link "$codex_home/skills/devkit-core--coder" "$ROOT/plugins/core/skills/coder"
assert_link "$codex_home/skills/devkit-core--backlog" "$ROOT/plugins/core/skills/backlog"
assert_link "$codex_home/skills/devkit-core--estimate" "$ROOT/plugins/core/skills/estimate"
assert_link "$codex_home/skills/devkit-core--timesheet" "$ROOT/plugins/core/skills/timesheet"
assert_link "$codex_home/skills/devkit-core--learn" "$ROOT/plugins/core/skills/learn"
assert_link "$codex_home/skills/devkit-core--nontech" "$ROOT/plugins/core/skills/nontech"
assert_link "$codex_home/skills/devkit-core--task" "$ROOT/plugins/core/skills/task"
assert_link "$codex_home/skills/devkit-core--lunaqa" "$ROOT/plugins/core/skills/lunaqa"
assert_link "$codex_home/skills/devkit-core--devkit-router" "$ROOT/plugins/core/skills/devkit-router"
assert_absent "$codex_home/skills/devkit-css--css-a11y"
assert_absent "$codex_home/skills/devkit-core--retired"
assert_absent "$codex_home/skills/devkit-laravel--architect"
assert_link "$codex_home/skills/user-skill" "$ROOT/plugins/core/skills/coder"
assert_link "$cursor_home/skills/devkit-coder" "$ROOT/plugins/core/skills/coder"
assert_link "$cursor_home/skills/devkit-estimate" "$ROOT/plugins/core/skills/estimate"
assert_link "$cursor_home/skills/devkit-timesheet" "$ROOT/plugins/core/skills/timesheet"
assert_link "$cursor_home/skills/devkit-nontech" "$ROOT/plugins/core/skills/nontech"
for link in "$cursor_home"/skills/*; do
  [ -L "$link" ] || continue
  declared=$(sed -n 's/^name:[[:space:]]*//p' "$link/SKILL.md" | head -1)
  [ "$(basename "$link")" = "$declared" ] || fail "Cursor global skill folder differs from frontmatter name: $link"
done
[ -f "$cursor_home/agents/devkit-plan-reviewer.md" ] || fail "global Cursor review subagent missing"
assert_contains "$cursor_home/agents/devkit-plan-reviewer.md" 'readonly: true'
assert_not_contains "$cursor_home/agents/devkit-plan-reviewer.md" 'tools: Read, Glob, Grep, Bash, WebFetch'
assert_absent "$cursor_home/skills/devkit-laravel--architect"
assert_absent "$cursor_home/skills/devkit-renamed"
assert_absent "$cursor_home/skills/removed"
assert_absent "$codex_home/hooks.json"
assert_contains "$codex_home/config.toml" 'command = "agterm-status pre-tool-use"'
assert_contains "$codex_home/config.toml" 'command = "plannotator"'
assert_contains "$codex_home/config.toml" 'coder-gate.sh'
assert_contains "$codex_home/config.toml" 'comment-gate.sh'
assert_contains "$codex_home/config.toml" 'jev-feedback.py'
[ "$(grep -Fc 'jev-feedback.py' "$codex_home/config.toml")" = "1" ] || fail "expected only the Codex feedback prompt hook"
assert_contains "$codex_home/config.toml" 'args = ["chrome-devtools-mcp@latest", "--custom-flag", "--headless", "--pageIdRouting", "--isolated"]'
assert_not_contains "$codex_home/config.toml" '--experimentalPageIdRouting'
assert_not_contains "$codex_home/config.toml" '--headless=false'
[ "$(grep -Fc 'coder-gate.sh' "$codex_home/config.toml")" = "1" ] || fail "expected one Codex coder gate"
[ "$(grep -Fc 'comment-gate.sh' "$codex_home/config.toml")" = "1" ] || fail "expected one Codex comment gate"
python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$codex_home/config.toml"
[ "$(python3 -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["shell_environment_policy"]["set"]["DEVKIT_HOME"])' "$codex_home/config.toml")" = "$ROOT" ] \
  || fail "Codex shell environment does not export DEVKIT_HOME"
[ "$(jq -r '.env.DEVKIT_HOME' "$claude_home/settings.json")" = "$ROOT" ] \
  || fail "Claude settings do not export DEVKIT_HOME"
[[ "$install_output" == *"Cursor stack skills are now project-scoped"* ]] \
  || fail "Cursor project-skill migration notice was not emitted"
assert_contains "$claude_home/CLAUDE.md" 'personal global guidance'
assert_link "$claude_home/skills/devkit-core--backlog" "$ROOT/plugins/core/skills/backlog"
assert_link "$claude_home/skills/devkit-core--estimate" "$ROOT/plugins/core/skills/estimate"
assert_link "$claude_home/skills/devkit-core--timesheet" "$ROOT/plugins/core/skills/timesheet"
assert_link "$claude_home/skills/devkit-core--learn" "$ROOT/plugins/core/skills/learn"
assert_link "$claude_home/skills/devkit-core--nontech" "$ROOT/plugins/core/skills/nontech"
assert_link "$claude_home/skills/devkit-core--task" "$ROOT/plugins/core/skills/task"
assert_link "$claude_home/skills/devkit-core--lunaqa" "$ROOT/plugins/core/skills/lunaqa"
assert_contains "$claude_home/commands/lunaqa.md" 'Skill(devkit-core--lunaqa)'
python3 - "$ROOT/bin/devkit-model" <<'PY'
import runpy
import sys

select_model = runpy.run_path(sys.argv[1])["select_model"]

def model(name, hidden=False, effort="medium"):
    return {"model": name, "hidden": hidden, "supportedReasoningEfforts": [{"reasoningEffort": effort}]}

older, current, next_minor, future = [f"gpt-{version}-luna" for version in (1, 2, "2.10", 3)]
other_family = f"gpt-{99}-sol"
catalog = [model(older), model(current), model(other_family)]
assert select_model(catalog, "luna", "medium") == current
catalog += [model(f"gpt-{2}.9-luna"), model(next_minor), model(future, hidden=True)]
assert select_model(catalog, "luna", "medium") == next_minor
catalog.append(model(future))
assert select_model(catalog, "luna", "medium") == future
assert select_model(catalog, "sol", "medium") == other_family
default_catalog = [model(current), model(future, effort="high")]
assert select_model(default_catalog, "luna") == future
assert select_model(default_catalog, "luna", "high") == future
for unavailable in [[], [model(other_family)], [model(current), model(future, effort="high")]]:
    try:
        select_model(unavailable, "luna", "medium")
    except ValueError:
        pass
    else:
        raise AssertionError("Unavailable Luna must block instead of silently falling back")
print("Luna model selection tests passed")
PY
assert_contains "$claude_home/commands/nontech.md" 'Skill(devkit-core--nontech)'
assert_contains "$claude_home/commands/xlsx.md" 'Skill(devkit-core--xlsx)'
for cmd in "$claude_home"/commands/*.md; do
  iconv -f UTF-8 -t UTF-8 < "$cmd" > /dev/null 2>&1 \
    || fail "generated command is not valid UTF-8: $cmd"
done
assert_contains "$claude_home/CLAUDE.md" '<!-- devkit-skill-policy:start -->'
assert_contains "$claude_home/CLAUDE.md" 'Skill selection starts from the catalog metadata.'
assert_contains "$claude_home/CLAUDE.md" "$ROOT/plugins/core/conduct/learning-capture-gate.md"
assert_contains "$claude_home/CLAUDE.md" 'Skill(devkit-core--learn)'
assert_contains "$claude_home/CLAUDE.md" 'Cursor invokes `/devkit-coder`'
assert_not_contains "$claude_home/CLAUDE.md" '{{DEVKIT_HOME}}'
assert_contains "$codex_home/AGENTS.md" 'personal codex guidance'
assert_contains "$codex_home/AGENTS.md" '<!-- devkit-skill-policy:start -->'
assert_contains "$codex_home/AGENTS.md" 'Skill selection starts from the catalog metadata.'
assert_contains "$codex_home/AGENTS.md" 'Cursor invokes `/devkit-coder`'
assert_not_contains "$codex_home/AGENTS.md" '{{DEVKIT_HOME}}'
assert_contains "$cursor_home/rules/devkit-skill-policy.mdc" 'alwaysApply: true'
assert_contains "$cursor_home/rules/devkit-skill-policy.mdc" 'Skill selection starts from the catalog metadata.'
assert_contains "$cursor_home/rules/devkit-skill-policy.mdc" 'Cursor invokes `/devkit-coder`'
assert_contains "$cursor_home/rules/devkit-skill-policy.mdc" "$ROOT/plugins/core/conduct/learning-capture-gate.md"
assert_contains "$cursor_home/rules/devkit-skill-policy.mdc" 'Cursor invokes `/devkit-learn`'
assert_not_contains "$cursor_home/rules/devkit-skill-policy.mdc" '{{DEVKIT_HOME}}'
assert_contains "$cursor_home/rules/user-authored.mdc" '# keep me'
assert_contains "$claude_home/settings.json" 'skill-eval.sh'
assert_contains "$claude_home/settings.json" 'jev-feedback.py'
[ "$(jq '[.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains("jev-feedback.py"))] | length' "$claude_home/settings.json")" = "1" ] \
  || fail "expected one Claude feedback prompt hook"
[ "$(jq '[.hooks.SessionEnd[]?.hooks[]? | select(.command | contains("jev-feedback.py"))] | length' "$claude_home/settings.json")" = "0" ] \
  || fail "old Claude feedback session-end hook was not removed"
assert_contains "$claude_home/settings.json" 'custom-session-end-hook'
assert_contains "$claude_home/settings.json" 'custom-prompt-hook'
[ "$(jq '[.hooks.beforeSubmitPrompt[]? | select(.command | contains("jev-feedback.py"))] | length' "$cursor_home/hooks.json")" = "1" ] \
  || fail "expected one Cursor beforeSubmitPrompt feedback hook"
assert_contains "$cursor_home/hooks.json" 'custom-cursor-prompt-hook'
assert_contains "$cursor_home/hooks.json" 'custom-native-cursor-hook'
[ "$(jq --arg cmd "$ROOT/bin/devkit-update --if-stale" '[.hooks.sessionStart[]? | select(.command == $cmd)] | length' "$cursor_home/hooks.json")" = "1" ] \
  || fail "expected one Cursor sessionStart auto-update hook"
[ ! -f "$cursor_home/hooks/hooks.json" ] || fail "legacy Cursor hooks remained active after migration"
[ "$(jq -r '.hooks.beforeSubmitPrompt[]? | select(.command | contains("jev-feedback.py")) | .command' "$cursor_home/hooks.json")" = "python3 '$ROOT/plugins/core/hooks/jev-feedback.py' prompt" ] \
  || fail "Cursor beforeSubmitPrompt feedback command does not point at this clone"
jq -e '.version == 1 and all(.hooks.preToolUse[]; has("command") and (has("hooks") | not))' "$cursor_home/hooks.json" >/dev/null \
  || fail "global Cursor hooks are not in native version 1 format"
[ "$(jq '[.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains("skill-eval.sh"))] | length' "$claude_home/settings.json")" = "1" ] \
  || fail "expected one skill-eval hook"
assert_absent "$claude_home/output-styles/laconica.md"
assert_link "$claude_home/output-styles/senior.md" "$ROOT/plugins/core/output-styles/senior.md"
assert_absent "$claude_home/output-styles/laconica-ru.md"
[ "$(jq -r '.outputStyle' "$claude_home/settings.json")" = "Senior" ] \
  || fail "expected Senior default output style"

skill_eval_output=$(sh "$ROOT/plugins/core/hooks/skill-eval.sh" < /dev/null)
[[ "$skill_eval_output" == *"$ROOT/plugins/core/conduct/learning-capture-gate.md"* ]] \
  || fail "skill-eval hook did not resolve the installed learning gate"
[[ "$skill_eval_output" == *"Skill(devkit-core--learn)"* ]] \
  || fail "skill-eval hook did not emit the Claude learn slug"

first_claude_guidance=$(cksum < "$claude_home/CLAUDE.md")
first_codex_config=$(cksum < "$codex_home/config.toml")
codex_coder_link="$codex_home/skills/devkit-core--coder"
python3 - "$codex_coder_link" <<'PY'
import os
import sys

timestamp_ns = 946684800_000_000_000
os.utime(sys.argv[1], ns=(timestamp_ns, timestamp_ns), follow_symlinks=False)
PY
codex_coder_link_mtime=$(python3 -c 'import os, sys; print(os.lstat(sys.argv[1]).st_mtime_ns)' "$codex_coder_link")
jq '.outputStyle = "Laconica"' "$claude_home/settings.json" > "$claude_home/settings.json.tmp"
mv "$claude_home/settings.json.tmp" "$claude_home/settings.json"
HOME="$home" CODEX_HOME="$codex_home" CURSOR_HOME="$cursor_home" DEVKIT_HOME_DIR="$ROOT" \
  bash "$ROOT/bin/devkit-install" >/dev/null
[ "$codex_coder_link_mtime" = "$(python3 -c 'import os, sys; print(os.lstat(sys.argv[1]).st_mtime_ns)' "$codex_coder_link")" ] \
  || fail "global Codex core skill links were replaced during idempotent install"
[ "$first_claude_guidance" = "$(cksum < "$claude_home/CLAUDE.md")" ] || fail "global CLAUDE.md generation is not idempotent"
[ "$first_codex_config" = "$(cksum < "$codex_home/config.toml")" ] || fail "global Codex hook installation is not idempotent"
[ "$(jq '[.hooks.SessionEnd[]?.hooks[]? | select(.command | contains("jev-feedback.py"))] | length' "$claude_home/settings.json")" = "0" ] \
  || fail "removed feedback session-end hook reappeared"
[ "$(jq '[.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains("skill-eval.sh"))] | length' "$claude_home/settings.json")" = "1" ] \
  || fail "skill-eval hook installation is not idempotent"
[ "$(jq -r '.outputStyle' "$claude_home/settings.json")" = "Senior" ] \
  || fail "previous devkit Laconica output style was not migrated to Senior"
jq '.outputStyle = "Explanatory"' "$claude_home/settings.json" > "$claude_home/settings.json.tmp"
mv "$claude_home/settings.json.tmp" "$claude_home/settings.json"
HOME="$home" CODEX_HOME="$codex_home" CURSOR_HOME="$cursor_home" DEVKIT_HOME_DIR="$ROOT" \
  bash "$ROOT/bin/devkit-install" >/dev/null
[ "$(jq -r '.outputStyle' "$claude_home/settings.json")" = "Explanatory" ] \
  || fail "explicit non-devkit output style was overwritten"

# Three installs have now run against this home. inject_cursor_edit_gates and the
# Claude hook injectors are all re-entrant by construction; assert that, or a
# regression duplicating an entry on every install goes unnoticed.
for cmd in coder-gate.sh comment-gate.sh jev-feedback.py; do
  n=$(jq --arg c "$cmd" '
    [(.hooks.preToolUse[]?), (.hooks.beforeSubmitPrompt[]?)]
    | map(select(.command | contains($c)))
    | length
  ' "$cursor_home/hooks.json")
  case "$cmd" in
    coder-gate.sh) want=2 ;;   # one Read|ReadFile gate, one edit gate
    comment-gate.sh) want=1 ;;
    jev-feedback.py) want=1 ;;
  esac
  [ "$n" = "$want" ] || fail "expected $want $cmd entries in Cursor hooks after three installs, found $n"
done
assert_contains "$cursor_home/hooks.json" 'custom-cursor-prompt-hook'
for event in UserPromptSubmit PreToolUse SessionStart; do
  n=$(jq --arg e "$event" '[.hooks[$e][]?.hooks[]? | select(.command | test("devkit"))] | length' \
    "$claude_home/settings.json")
  dupes=$(jq --arg e "$event" '[.hooks[$e][]?.hooks[]?.command | select(test("devkit"))] | length - (unique | length)' \
    "$claude_home/settings.json")
  [ "$n" -gt 0 ] || fail "no devkit $event hook in settings.json"
  [ "$dupes" = "0" ] || fail "three installs left $dupes duplicate devkit $event hook(s)"
done

project="$TMP_DIR/project"
mkdir -p "$project/.devkit" "$project/.codex/skills/custom-skill" "$project/.cursor/skills/custom-skill"
git -C "$project" init -q
printf '%s\n' 'project-local-entry' > "$project/.gitignore"
printf '%s\n' '{"version":1,"enabled":["devkit-laravel","devkit-vue","devkit-inertia","devkit-tailwind"]}' \
  > "$project/.devkit/toolkit.json"
ln -s "$ROOT/plugins/css/skills/css-a11y" "$project/.codex/skills/devkit-css--css-a11y"

DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/codex/generate" >/dev/null

assert_contains "$project/.gitignore" 'project-local-entry'
# Exact-line count, not a substring: codex/generate runs three times against this
# project, so a regression in ensure_gitignore_entry's normalisation awk would append
# on every run and a presence check would still pass. '.codex/skills' also satisfies
# a substring match without the entry ever being written.
[ "$(grep -cxF '.codex/' "$project/.gitignore")" = "1" ] \
  || fail "expected exactly one '.codex/' line in .gitignore, found $(grep -cxF '.codex/' "$project/.gitignore")"

assert_absent "$project/.codex/skills/devkit-core--coder"
assert_link "$project/.codex/skills/devkit-frontend--pixel-build" "$ROOT/plugins/frontend/skills/pixel-build"
assert_link "$project/.codex/skills/devkit-laravel--architect" "$ROOT/plugins/laravel/skills/architect"
assert_absent "$project/.codex/skills/devkit-css--css-a11y"
[ -d "$project/.codex/skills/custom-skill" ] || fail "custom skill directory was removed"
assert_contains "$project/AGENTS.md" '### devkit-core'
assert_contains "$project/AGENTS.md" '### devkit-frontend'
assert_contains "$project/AGENTS.md" '### devkit-vue'
assert_contains "$project/AGENTS.md" '### devkit-inertia'
assert_contains "$project/AGENTS.md" '### devkit-laravel'
assert_contains "$project/AGENTS.md" '### devkit-tailwind'
assert_not_contains "$project/AGENTS.md" '### devkit-css'
assert_contains "$project/AGENTS.md" 'plugins/core/conduct/overview.md'
assert_contains "$project/AGENTS.md" '~/.claude/agentic-devkit/plugins/core/conduct/learning-capture-gate.md'
assert_contains "$project/AGENTS.md" 'Cursor invokes `/devkit-learn`'
assert_not_contains "$project/AGENTS.md" '{{DEVKIT_HOME}}'
assert_contains "$project/AGENTS.md" 'plugins/laravel/conduct/overview.md'
assert_not_contains "$project/AGENTS.md" 'plugins/core/conduct/docker-deployment.md'
assert_not_contains "$project/AGENTS.md" 'plugins/laravel/conduct/architecture.md'

DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/cursor/generate" >/dev/null
assert_absent "$project/.cursor/skills/devkit-coder"
assert_link "$project/.cursor/skills/devkit-pixel-build" "$ROOT/plugins/frontend/skills/pixel-build"
assert_link "$project/.cursor/skills/devkit-architect" "$ROOT/plugins/laravel/skills/architect"
for link in "$project"/.cursor/skills/*; do
  [ -L "$link" ] || continue
  declared=$(sed -n 's/^name:[[:space:]]*//p' "$link/SKILL.md" | head -1)
  [ "$(basename "$link")" = "$declared" ] || fail "Cursor project skill folder differs from frontmatter name: $link"
done
[ -d "$project/.cursor/skills/custom-skill" ] || fail "custom Cursor skill directory was removed"
assert_contains "$project/.cursor/rules/devkit-core.mdc" 'plugins/core/conduct/overview.md'
assert_contains "$project/.cursor/rules/devkit-core.mdc" '~/.claude/agentic-devkit/plugins/core/conduct/learning-capture-gate.md'
assert_contains "$project/.cursor/rules/devkit-core.mdc" 'Cursor invokes `/devkit-learn`'
assert_not_contains "$project/.cursor/rules/devkit-core.mdc" '{{DEVKIT_HOME}}'
assert_contains "$project/.cursor/rules/devkit-laravel.mdc" 'plugins/laravel/conduct/overview.md'
assert_not_contains "$project/.cursor/rules/devkit-core.mdc" 'plugins/core/conduct/docker-deployment.md'
assert_not_contains "$project/.cursor/rules/devkit-laravel.mdc" 'plugins/laravel/conduct/architecture.md'

first_cursor_skills=$(skill_snapshot "$project/.cursor/skills")
first_cursor_core_rule=$(cksum < "$project/.cursor/rules/devkit-core.mdc")
DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/cursor/generate" >/dev/null
[ "$first_cursor_skills" = "$(skill_snapshot "$project/.cursor/skills")" ] || fail "Cursor skill regeneration is not idempotent"
[ "$first_cursor_core_rule" = "$(cksum < "$project/.cursor/rules/devkit-core.mdc")" ] || fail "Cursor rule regeneration is not idempotent"

first_skills=$(skill_snapshot "$project/.codex/skills")
first_agents=$(cksum < "$project/AGENTS.md")
DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/codex/generate" >/dev/null
[ "$first_skills" = "$(skill_snapshot "$project/.codex/skills")" ] || fail "skill regeneration is not idempotent"
[ "$first_agents" = "$(cksum < "$project/AGENTS.md")" ] || fail "AGENTS.md regeneration is not idempotent"

printf '%s\n' '{"version":1,"enabled":["devkit-css"]}' > "$project/.devkit/toolkit.json"
DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/codex/generate" >/dev/null
DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/cursor/generate" >/dev/null

assert_link "$project/.codex/skills/devkit-css--css-a11y" "$ROOT/plugins/css/skills/css-a11y"
assert_absent "$project/.codex/skills/devkit-frontend--pixel-build"
assert_absent "$project/.codex/skills/devkit-laravel--architect"
assert_contains "$project/AGENTS.md" '### devkit-css'
assert_not_contains "$project/AGENTS.md" '### devkit-laravel'
[ -d "$project/.codex/skills/custom-skill" ] || fail "custom skill directory was removed"
assert_link "$project/.cursor/skills/css-a11y" "$ROOT/plugins/css/skills/css-a11y"
assert_absent "$project/.cursor/skills/devkit-pixel-build"
assert_absent "$project/.cursor/skills/devkit-architect"
[ -d "$project/.cursor/skills/custom-skill" ] || fail "custom Cursor skill directory was removed"
assert_contains "$project/.cursor/rules/devkit-core.mdc" 'plugins/core/conduct/overview.md'
assert_contains "$project/.cursor/rules/devkit-css.mdc" 'plugins/css/conduct/overview.md'
for disabled_rule in frontend inertia laravel tailwind vue; do
  assert_absent "$project/.cursor/rules/devkit-${disabled_rule}.mdc"
done

collision_project="$TMP_DIR/collision-project"
mkdir -p "$collision_project/.devkit" \
  "$collision_project/.codex/skills/devkit-css--css-a11y" \
  "$collision_project/.cursor/skills/css-a11y"
printf '%s\n' '{"version":1,"enabled":["devkit-css"]}' > "$collision_project/.devkit/toolkit.json"
if DEVKIT_PROJECT_ROOT="$collision_project" bash "$ROOT/adapters/codex/generate" >/dev/null 2>&1; then
  fail "Codex adapter accepted an occupied enabled-skill destination"
fi
if DEVKIT_PROJECT_ROOT="$collision_project" bash "$ROOT/adapters/cursor/generate" >/dev/null 2>&1; then
  fail "Cursor adapter accepted an occupied enabled-skill destination"
fi
[ -d "$collision_project/.codex/skills/devkit-css--css-a11y" ] \
  || fail "Codex collision path was mutated"
[ -d "$collision_project/.cursor/skills/css-a11y" ] \
  || fail "Cursor collision path was mutated"

own_env_home="$TMP_DIR/own-env-home"
mkdir -p "$own_env_home/.codex" "$own_env_home/.claude"
printf '%s\n' '[shell_environment_policy]' 'set = { EDITOR = "vim" }' > "$own_env_home/.codex/config.toml"
own_env_output=$(HOME="$own_env_home" CODEX_HOME="$own_env_home/.codex" CURSOR_HOME="$own_env_home/.cursor" DEVKIT_HOME_DIR="$ROOT" \
  bash "$ROOT/bin/devkit-install")
python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$own_env_home/.codex/config.toml" \
  || fail "installer broke a Codex config that owns shell_environment_policy.set"
assert_contains "$own_env_home/.codex/config.toml" 'set = { EDITOR = "vim" }'
[[ "$own_env_output" == *"add DEVKIT_HOME"* ]] || fail "installer did not report the skipped Codex DEVKIT_HOME"

echo "codex adapter tests passed"
