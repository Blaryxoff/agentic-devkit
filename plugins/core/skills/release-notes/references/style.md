# Release notes style (RU)

The house format for release posts. Follow it literally — the team reads these in a messenger and reacts to them.

## Skeleton

```
DD.MM.YYYY

<emoji> <Название раздела>

<Изменение одной строкой>
<Изменение одной строкой>

<emoji> <Название раздела>

<Изменение одной строкой>
```

- **Header.** `DD.MM.YYYY` on its own line. Add a theme when the release has one: `13.03.2026 Релиз: запись на услуги
  клиник, SEO, монетизация` (2–4 themes, comma-separated). A small out-of-cycle release is headed `Мини-релиз` with no
  date, or `DD.MM.YYYY` plus a `🔧 Мини-релиз` line.
- **Sections.** `<emoji> <Заголовок>` — 1–4 words, a product area the team names out loud.
- **Items.** One line each, no bullet markers, no trailing period. Nest with two spaces only when a single change has
  enumerable variants.
- **Plain text.** No `#`, no `**`, no `>`. Markdown does not survive the paste.

## Section order

- Lead with the release's biggest theme, whatever it is — a new section of the site, a geo rollout, an SEO sweep.
- Then the remaining areas by weight: the ones the team spent the most on first.
- Fix-flavoured sections last (`🔧 Профиль врача`, `🎨 Интерфейс`, `🛠 Другое`).
- A dedicated `🐛 Исправления` section only when the fixes don't belong to a named area. Fixes inside a feature area
  stay in that area.

Size: 3–6 sections for a mini-release, 8–14 for a full one; 1–12 lines per section. A section with one trivial line
folds into `🛠 Другое`.

## Emoji vocabulary

Reuse the same emoji for the same area release after release — the reader scans by icon.

| Area | Emoji |
|---|---|
| Doctors, profiles | `👨‍⚕️` |
| Clinics | `🏥` |
| SEO, indexing | `🛡️` `🔍` |
| Search, filters, catalog | `🔎` |
| Notifications | `🔔` |
| Email, mailings | `📧` |
| SMS, auth | `📱` `🔐` |
| Geo, cities | `🌍` |
| Analytics | `📊` `📈` |
| Monetisation, prices | `💰` |
| Promo codes, partner programs | `🎁` `🤝` |
| AI features | `🤖` |
| Widget, integrations | `🔌` `🔗` |
| Content, documents | `📝` `📄` |
| Admin panel | `🛠` `⚙️` |
| Infrastructure, deploy | `⚙️` |
| Logs | `📚` |
| UI, design | `🎨` `✨` |
| Fixes | `🐛` |
| Mini-release marker | `🔧` |

## Wording

- Perfective past passive, agreeing with the subject: `Добавлен раздел…`, `Добавлена страница…`, `Добавлено поле…`,
  `Добавлены фильтры…`. Same for `Реализован`, `Переработан`, `Обновлён`, `Настроен`, `Подключён`, `Запущен`,
  `Исправлен`, `Убран`.
- Or start from the subject when it reads better: `Новый фильтр «В ближайшие 2 часа» — показывает врачей с доступными
  слотами`.
- UI names in «ёлочки»: `раздел «Промокоды»`, `кнопка «Записаться в клинику»`.
- Em dash for the explanation half: `Автоотмена неоплаченной заявки: 30 мин → 1 час`, `Блок «Подборка кормов» — не
  показывается, пока каталог пуст`.
- Real user-facing nouns are welcome: URLs (`/simptomy/`), admin section names, integration names (`DaData`,
  `Unisender`, `Tbank`), field names the team uses.
- Ops caveat inside its section:
  `⚠️ Важно: в релизе подготовлена интеграция — для работы нужно получить и настроить API-ключи в окружении проекта`.

## Right / wrong

| Wrong | Right |
|---|---|
| `feat(catalog): add nearest-slot filter` | `Новый фильтр «В ближайшие 2 часа» — показывает врачей с доступными слотами` |
| `Рефакторинг NotificationService (a1b2c3d)` | `Добавлена очередь обработки уведомлений` |
| `Поправлено в app/Http/Controllers/DoctorController.php` | `Онлайн-врачи сортируются с учётом реально доступных слотов` |
| `Бэкенд: добавлено API. Фронт: добавлена форма` | `Добавлена форма «Оставить заявку на услугу»` |
| `Улучшена работа с городами и, кроме того, добавлены подсказки в форме регистрации` | two lines, one change each |
| `В этом релизе мы сосредоточились на…` | no preamble at all |

## Reference sample (abridged, real)

```
2.06.2026

🩺 Раздел «Симптомы»

Запущен отдельный раздел /simptomy/ — материалы не смешиваются с обычным блогом
У постов в админке колонка «Отображается в»: Блог или Симптомы
В sitemap и на сайте у симптомов свои URL; в /blog/ они не попадают

🛡️ SEO — клиники и каталог врачей

На /clinics/ выводится SEO-блок: title, H1, описание, текст, FAQ — настраивается в админке
Несуществующая специальность или город → 404, а не редирект на другую страницу
URL с фильтрами (?filter-...) закрыты от индексации, canonical ведёт на «чистую» страницу каталога

🏠 Выезд на дом

Врач настраивает услуги выезда в профиле
На фронте — блок «Выезд на дом» в редактировании профиля

🔧 Профиль врача

Исправлено сохранение услуг выезда и отображение цены специальности после модерации
Убрано лишнее поле в блоке образования
```
