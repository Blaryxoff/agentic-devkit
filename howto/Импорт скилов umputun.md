# Импорт скилов из umputun/cc-thingz

Из набора [`umputun/cc-thingz`](https://github.com/umputun/cc-thingz) (MIT) забрали релевантные части и адаптировали под devkit. Стек-агностичное легло в `plugins/core`.

## Новые core-скилы (`plugins/core/skills/`)

| Скил | Когда срабатывает |
|---|---|
| `devkit-git-review` | «review my changes», «git review» — интерактивное ревью: правишь аннотации прямо в diff в `$EDITOR`, агент чинит код в цикле. |
| `devkit-dialectic` | «prove/disprove», «stress-test this claim» — два встречных анализа (за/против) параллельно + синтез, сверенный с кодом. |
| `devkit-root-cause` | ошибки, падения тестов/билда, «it's not working» — 5-Why до корневой причины; только расследование, не фикс. |
| `devkit-wrong` | «this isn't working», «wrong approach», «start over» — сброс и 2–3 свежих подхода вместо латания тупика. |
| `devkit-clarify` | пользователь запутался («I don't understand», «wait, shouldn't it…») — объяснить реальное поведение с доказательствами, отличить непонимание от реального бага. |
| `devkit-learn` | «learn», «update claude.md» — записать стратегические знания сессии в проектный `CLAUDE.md` (отдельно от персональной авто-памяти `MEMORY.md`). |

## Новые conduct-доки (`plugins/core/conduct/`, авто-обнаружение)

- `code-comments.md` — комментарий описывает текущее состояние/назначение, не историю изменений (запрет `// added`, `// previously X, now Y`); документировать публичный API. Язык-агностично.
- `code-smells.md` — стек-агностичный чек-лист код-смеллов и анти-паттернов; цитируется вариантами `devkit-reviewer-deep`.
- `communication-style.md` — анти-AI-speak для коммитов/PR/ревью; цитируется `devkit-git`.

## skill-eval хук

`plugins/core/hooks/skill-eval.sh` — UserPromptSubmit-хук, заставляющий модель оценить и активировать релевантные скилы (включая роутер `devkit`) до реализации.

- Ставится **глобально** в `~/.claude/settings.json` при `bin/devkit-install` (зеркалит SessionStart-хук авто-апдейта).
- Только инструкция, без permissions. Claude-специфичен (Cursor/Codex имеют свои механизмы).
- `paths.hooks` для core **намеренно не задан** — иначе per-project claude-адаптер смержил бы хук второй раз, и он сработал бы дважды.

## Требования git-review

`python3`, один из tmux/kitty/wezterm (оверлей редактора), `$EDITOR` (по умолчанию `micro`), git. Встроенные тесты: `python3 plugins/core/skills/git-review/scripts/git-review.py --test`.
