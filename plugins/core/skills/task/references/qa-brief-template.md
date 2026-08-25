# QA brief template

The peer agent runs browser QA in a fresh context with an isolated browser profile. It has your repository and nothing
else: not your session, not your cookies, not what you already clicked. Every section below exists because omitting it
sent a real run into a wall.

Write the brief in the operator's language, fill every section, delete nothing.

---

```markdown
# Браузерная QA: <feature>

Проверить в реальном браузере локальный стенд. Ты — QA, код не правишь; на каждый
пункт отдаёшь PASS/FAIL со скриншотом или цитатой из DOM.

## Стенд

- Фронт: **<url>** (<why this host and not localhost — proxy, API base, CORS>).
- Бэк: <url>, репозиторий <path>.
- Dev-сервер уже запущен / запусти так: <command>.
- Известные ложные отказы: <e.g. 504 Outdated Optimize Dep → stale Vite dep cache,
  перезагрузи страницу; если не помогает — сообщи>.
- **Отложенная работа выполняется сразу:** <queue driver, e.g. QUEUE_CONNECTION=sync —
  делают ли delayed-листенеры вид, что прошёл их таймаут. Перечисли, какие статусы
  из-за этого выглядят «неправильно» локально.>
- Консоль/artisan: <exact command>.

## Предусловия данных

<What the scenario needs to exist before the first click — free slots, an approved
profile, a second account, a published entity — and the exact command or SQL that
creates it. Without this a whole branch of the brief comes back BLOCKED.>

<For any "чужие данные" check: name the second account and the id that belongs to it,
so ownership is proven rather than assumed.>

## Авторизация

<Where the auth code actually lands locally — log file, mailhog, DB column — and the
exact steps to get from "code requested" to "logged in", including any post-login
interstitial to dismiss.>

<Which account to use, or how to create one.>

## Что уже проверено — НЕ повторяй

<Verbatim list of what you already verified yourself, with the result. Without this
the peer burns its run re-testing solved ground.>

## Что проверить

### 1. <area>

<Route(s). Exact expected string in quotes — "Комментарий для врача по адресу", not
"the updated hint". A string the peer must match exactly cannot be paraphrased.>

<Name the negative case too: what must NOT have changed elsewhere.>

### 2. <area>

<...>

### N. <access control>

<Every new endpoint or route that reads someone's data gets a foreign-id probe:
open it as another user, expect 403/redirect and no data on screen.>

## Формат ответа

Список пунктов с PASS/FAIL. Для FAIL — что видел, что ожидалось, шаги
воспроизведения. Стилистику и дизайн не критикуй, проверяй только эти пункты.
```

---

## Section notes

| Section | Why it is mandatory |
|---|---|
| Stand URL + why | A dev server reachable on two hosts fails silently on the wrong one (API base derived from host). |
| Known false failures | Stale bundler caches surface as application errors; without a note the peer files a bug against your code. |
| Queue driver | A synchronous queue runs delayed listeners inline, so timeout-driven state (auto-cancel, expiry, reminders) lands the instant a record is created. The peer sees a "wrong" status and files a major defect against untouched code. |
| Data preconditions | A scenario that needs a bookable slot, a second account, or a published entity comes back BLOCKED without them — and BLOCKED items cost a second full QA run. |
| Auth recipe | Local codes never leave the machine. The peer cannot guess which log line holds them. |
| Already verified | Prevents paying twice for the same coverage. |
| Exact expected strings | A copy change is only verifiable character by character. |
| Negative cases | A rename that also hit the wrong surface passes a positive-only check. |
| Access-control probe | New read endpoints are where IDOR lands; QA is the cheapest place to catch it. |
| Response format | Keeps the report triageable instead of narrative. |

## Invocation

Launch the peer with a sandbox that permits browser control, and point it at the brief by path — do not inline the
brief into the prompt, or the two copies drift.

Flags, stdin handling (`< /dev/null`), and failure modes: `plugins/core/conduct/cross-agent-review.md` →
"Peer CLI invocation".
