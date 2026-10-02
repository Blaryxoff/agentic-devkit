# CLAUDE.md: конвенции проекта для AI-агентов

> Часть [[Руководство разработчика]]

## Что такое CLAUDE.md

CLAUDE.md — файл в корне репозитория (и/или в поддиректориях), который Claude Code автоматически читает при запуске. Это «мозг» агента для вашего проекта: он определяет, как агент должен писать код, какие паттерны использовать, чего избегать.

Cursor использует аналогичный `.cursorrules`. Оба файла должны быть синхронизированы по содержанию.

## Иерархия

```
~/.claude/CLAUDE.md              ← личные настройки (не в git)
repo-root/CLAUDE.md              ← общие правила проекта
repo-root/app/CLAUDE.md          ← backend-специфичные правила
repo-root/resources/CLAUDE.md    ← frontend-специфичные правила
```

Claude Code мерджит все уровни. Более специфичный файл переопределяет общий.

## Шаблон корневого CLAUDE.md

```markdown
# Project: [Название]

## Обзор
Веб-продукт на текущем проектном стеке.

## Технологический стек
- Backend: [актуальный backend стек]
- Frontend: [актуальный frontend стек]
- Tooling: PHPUnit, Pint, ESLint, Prettier

## Структура репозитория
```
app/                    # Laravel backend
routes/                 # web/api маршруты
resources/js/           # Inertia Vue pages/components
database/               # migrations, factories, seeders
tests/                  # PHPUnit tests
docs/plans/product/     # product планы в markdown
docs/plans/dev/         # dev планы в markdown
```

## Абсолютные правила

### Действия и границы
- Используй точные типы TypeScript; обоснуй любое необходимое применение `any`
- Читай `env()` только внутри `config/*.php`
- Вынеси валидацию бизнес-форм в FormRequest
- Читай URL, ключи и пароли через конфигурацию; не хардкодь секреты
- Добавляй зависимости только при крайней необходимости
- Выражай очевидное поведение именами и кодом

### ВСЕГДА
- Используй FormRequest для валидации и Policy/Gate для доступа
- Используй Eloquent отношения и eager loading для предотвращения N+1
- Придерживайся существующих паттернов Inertia страниц и Vue компонентов
- Поддерживай Tailwind-конвенции проекта и dark mode (если есть)
- Именуй ветки: `feature/GP-XXX-short-description`
- Коммит-сообщения: `feat(scope): description` (Conventional Commits)
```

## Шаблон app/CLAUDE.md (backend)

```markdown
# Backend Conventions

## Стиль кода
- Строгие типы и явные return types
- Тонкие контроллеры, бизнес-логика в сервисах/домене по текущей конвенции проекта
- FormRequest для валидации, Policies/Gates для авторизации

## Паттерны

### Контроллер
- Делегирует валидацию в FormRequest
- Делегирует SQL и сложную бизнес-логику соответствующему слою проекта
- Возвращает Inertia responses или Resources последовательно

## Запрещённые паттерны
- `DB::raw` с пользовательским вводом
- Сырые массивы без понятной структуры там, где нужен DTO/Resource
- Массовый копипаст сервисов/контроллеров
```

## Шаблон resources/CLAUDE.md (frontend)

```markdown
# Frontend Conventions

## Стек
- [актуальный UI framework]
- [актуальный data/navigation framework]
- [актуальный styling framework]
- ESLint + Prettier

## Компоненты
- Functional components only
- Один root element
- Props/emit типизируются
- Переиспользуемые части выносятся в Components/composables

## Типизация
- strict: true, noUncheckedIndexedAccess: true
- Используй только конкретные типы либо `unknown` + type narrowing
- Сохраняй консистентные типы props и Inertia page props

## UI
- Используй существующие Tailwind паттерны
- Для списков применяй gap utilities
- Учитывай dark mode если он используется в проекте

## Запрещено
- `as any`, `@ts-ignore`, `@ts-expect-error` без комментария
- Прямые обращения к DOM без крайней необходимости
- Инлайн-стили вместо Tailwind
```

## Как обновлять CLAUDE.md

1. Обнаружил, что AI повторяет одну и ту же ошибку?
   → Добавь правило в CLAUDE.md
2. AI не знает о новом паттерне в проекте?
   → Добавь пример в CLAUDE.md
3. AI использует устаревший API?
   → Добавь в секцию «Запрещённые паттерны»

Изменения в CLAUDE.md коммитятся как обычный код и проходят ревью.

---

Далее: [[Промпт-инжиниринг]]

#ai #claude-md #conventions #cursorrules
