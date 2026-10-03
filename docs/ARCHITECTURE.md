# ASCEND — Architecture Plan

Статус: **draft v1, на согласование**. Код пока не пишем.
Источник требований: `ASCEND_Flutter_Productivity_TZ.docx`.

Слоган: *Plan. Focus. Complete. Ascend.*

---

## 1. Принципы

1. **Offline-first.** Никакого аккаунта и сети в MVP. Единственный источник правды — локальная БД (Drift/SQLite).
2. **Бизнес-логика не в UI.** Экран только читает состояние и вызывает use-case.
3. **Один вход для сложных операций.** «Завершить задачу» — один use-case в одной транзакции (статус, XP, статистика, achievements, milestone). UI получает результат и анимирует.
4. **XP-формула в одном месте.** Меняется конфигом, UI о ней ничего не знает.
5. **Готовность к backend без самого backend.** UUID-идентификаторы, `createdAt/updatedAt`, репозитории за интерфейсами. Ничего сверх этого в MVP.
6. **Backup — часть схемы данных, а не «потом».** Любое изменение схемы БД обязано обновлять экспорт/импорт.
7. **Минимум зависимостей, без лишнего codegen.** Codegen только там, где он неизбежен (Drift).

---

## 2. Стек и зависимости

| Назначение | Пакет | Комментарий |
|---|---|---|
| UI | Flutter, Material 3 | Кастомная тема, не дефолтный вид |
| State | `flutter_riverpod` | `Notifier` / `AsyncNotifier` / `StreamProvider`, **без** `riverpod_generator` |
| Навигация | `go_router` | `StatefulShellRoute.indexedStack` для 5 вкладок |
| БД | `drift`, `drift_flutter` (или `sqlite3_flutter_libs`), dev: `drift_dev`, `build_runner` | Streams из запросов → UI реактивный |
| Уведомления | `flutter_local_notifications`, `timezone`, `flutter_timezone` | Нужны для корректных scheduled-уведомлений |
| Даты | `intl` | |
| Графики | `fl_chart` | |
| Мелкие настройки | `shared_preferences` | За интерфейсом `SettingsRepository` |
| Backup: шифрование | `cryptography` | AES-256-GCM + PBKDF2/Argon2 |
| Backup: файлы | `share_plus`, `file_picker`, `path_provider` | Native share / SAF picker |
| Backup: хэш/архив | `crypto`, `archive` (или `dart:io` gzip) | SHA-256, gzip |
| Идентификаторы | `uuid` | |
| Тесты | `flutter_test`, `mocktail` | In-memory Drift для репозиториев |

Шрифт **Inter кладём в `assets/fonts/`**, а не через `google_fonts`: приложение offline-first, шрифт не должен зависеть от сети.

Entities пишем вручную (immutable + `copyWith` + `==`), без `freezed`. Если их станет неудобно поддерживать, это отдельное решение.

---

## 3. Структура проекта

```
lib/
├── main.dart                     # только runApp + ProviderScope
├── app.dart                      # MaterialApp.router, тема, локаль
├── core/
│   ├── theme/                    # tokens, color scheme, text theme, component themes
│   ├── router/                   # GoRouter, route names/paths
│   ├── constants/
│   ├── database/                 # AppDatabase (Drift), tables, migrations, DAOs
│   ├── services/                 # NotificationService, Clock, IdGenerator
│   └── utils/                    # date helpers, formatters
├── features/
│   ├── tasks/        {data, domain, presentation}
│   ├── planner/      {data, domain, presentation}
│   ├── goals/        {data, domain, presentation}   # + milestones
│   ├── habits/       {data, domain, presentation}
│   ├── focus/        {data, domain, presentation}   # timer + FocusSession
│   ├── gamification/ {data, domain, presentation}   # XP, level, rank, streak, achievements
│   ├── statistics/   {data, domain, presentation}
│   ├── profile/      {data, domain, presentation}
│   ├── settings/     {data, domain, presentation}
│   └── backup/       {data, domain, presentation}
└── shared/
    ├── widgets/                  # ProgressRing, XpBar, TaskCard, EmptyState, ErrorState, Skeleton...
    └── models/                   # общие value-objects (Priority, DateRange)
test/
assets/fonts/
docs/ARCHITECTURE.md
```

Отличия от п. 18 ТЗ: добавлены `focus`, `gamification`, `planner`, `settings`, `backup` как отдельные фичи. Иначе XP/streak/achievements «размазались» бы по tasks и profile, а backup оказался бы в settings без своей логики.

### Правила слоёв

- `domain` — чистый Dart: entities, интерфейсы репозиториев, use-cases, `XpEngine`. Не импортирует Flutter и Drift.
- `data` — реализации репозиториев, DAO, мапперы Drift-row ↔ entity.
- `presentation` — экраны, виджеты, providers. Зависит от `domain`, **не** от `data` напрямую (только через провайдер репозитория).
- `shared/widgets` не знает про конкретные фичи.

---

## 4. Поток данных

```
Screen ──watch──▶ Provider (Notifier / StreamProvider)
                     │ вызывает
                     ▼
                 UseCase / Service   (domain)
                     │ через интерфейс
                     ▼
                 Repository (data) ──▶ Drift DAO ──▶ SQLite
```

Чтение: DAO отдаёт `Stream`, провайдер маппит в entity, экран перерисовывается автоматически.

### Ключевой use-case: `CompleteTask`

В **одной транзакции**:

1. `tasks.status = completed`, `completedAt = now`, `actualMinutes`.
2. Рассчитать XP через `XpEngine` и записать `xp_event`.
3. Если задача привязана к milestone: пересчитать прогресс цели, при закрытии milestone дать +100 XP.
4. Обновить `daily_stats` за день.
5. Проверить «выполнен дневной план» → bonus XP.
6. Обновить streak.
7. Проверить achievements.
8. Отменить scheduled-уведомления задачи.

Возвращает `CompletionResult { xpGained, levelBefore, levelAfter, rankChanged, unlockedAchievements }` — на этом строятся XP-анимация и Level Up. UI сам ничего не считает.

Обратная операция (вернуть задачу в Todo) удаляет связанный `xp_event`, чтобы XP нельзя было накрутить повторным завершением.

---

## 5. Схема БД (Drift)

Общие правила:
- PK — `TEXT` UUID (готовность к sync).
- Во всех сущностях `createdAt`, `updatedAt` (UTC, epoch ms).
- Даты «дня» хранятся отдельно как локальный ключ `yyyy-MM-dd` (`dayKey`), чтобы переходы часовых поясов не ломали streak и статистику.
- Удаление пока физическое. Если понадобится sync, добавим `deletedAt`.
- `schemaVersion` с первого дня, миграции через `MigrationStrategy` и тесты на каждую.

| Таблица | Поля (ключевые) |
|---|---|
| `categories` | id, name, colorValue, iconKey, isDefault, sortOrder |
| `tasks` | id, title, description, categoryId, priority(0–3), status(0–3), dueDate, startTime, estimatedMinutes, actualMinutes, xpReward, completedAt, goalId?, milestoneId?, recurrenceRuleId?, dayKey |
| `recurrence_rules` | id, type(daily/weekdays/weekly/custom), interval, weekdays, startDate, endDate? |
| `goals` | id, title, description, categoryId, deadline, status, completedAt |
| `milestones` | id, goalId, title, sortOrder, isDone, completedAt, xpAwarded |
| `habits` | id, name, frequencyType, targetPerPeriod, xpReward, isArchived |
| `habit_logs` | id, habitId, dayKey, count — UNIQUE(habitId, dayKey) |
| `focus_sessions` | id, taskId?, mode(countdown/stopwatch), plannedSeconds, actualSeconds, startedAt, endedAt, xpAwarded |
| `xp_events` | id, amount, sourceType, sourceId, note, createdAt — UNIQUE(sourceType, sourceId) |
| `achievements` | key (PK), unlockedAt?, progress |
| `daily_stats` | dayKey (PK), tasksPlanned, tasksCompleted, focusSeconds, xpEarned, planCompleted |
| `user_profile` | id=1, name, createdAt |

Решения:

- **`xp_events` — журнал, итог считается суммой.** Так XP/уровень можно пересчитать, а формулу поменять без потери истории. `UNIQUE(sourceType, sourceId)` защищает от двойного начисления.
- **Level и Rank не хранятся.** Выводятся из суммарного XP через `XpEngine`.
- **`daily_stats` — кэш**, полностью восстанавливается из `tasks`/`focus_sessions`/`xp_events`. При restore можно пересчитать, а не доверять данным из файла.
- **Привычки отдельно от tasks.** У них другая модель (частота + логи), смешивать их с задачами значит усложнить обе.
- **Повторяющиеся задачи.** Правило хранится в `recurrence_rules`, экземпляры материализуются на скользящее окно (например, 14 дней вперёд) при запуске и в фоне. Задача `isRecurring` в UI = «есть `recurrenceRuleId`».

---

## 6. XP / Level / Rank / Streak

### XpEngine (`features/gamification/domain`)

Чистый Dart, `XpConfig` — иммутабельный конфиг (в п. «XP settings» пользователь сможет менять множители, дефолты в коде).

```
xpForTask(task)         = base(priority, estimatedMinutes)   // 10–50
                          + highPriorityBonus
xpForMilestone()        = 100
xpForDailyPlan()        = dailyPlanBonus
xpForStreak(days)       = streakBonus (по порогам)
xpForFocus(seconds)     = опционально, небольшой (решить на этапе фокуса)
```

- `task.xpReward` фиксируется при создании (виден на карточке), бонусы добавляются при завершении.
- XP начисляется **только за действия** (завершение, milestone, фокус-сессия, план дня), не за открытие приложения.

### Level и Rank

- Кривая уровня: стартовое предложение `xpToNext(level) = round(100 * level^1.5)` (мягкий рост). Значения подбираем на реальном использовании. Менять придётся только эту функцию.
- Ранги привязаны к уровню (предложение, настраивается):

| Rank | Levels |
|---|---|
| Beginner | 1–4 |
| Starter | 5–9 |
| Focused | 10–14 |
| Disciplined | 15–24 |
| Advanced | 25–34 |
| Elite | 35–49 |
| Master | 50+ |

### Streak

- День считается активным, если выполнена **хотя бы одна задача** (определение вынесено в одну функцию, легко расширить привычками/фокусом).
- Current / Best / Completed days считаются по `daily_stats`, не хранятся отдельно.
- Граница дня — локальная полночь пользователя (`dayKey`).

### Achievements

Каждое достижение — декларативное правило `(key, условие, порог)`. Проверяются в `CompleteTask` и при окончании focus-сессии. MVP-набор из ТЗ: First Step, 7 Day Focus, 100 Tasks, Deep Worker (10 ч фокуса), Goal Crusher, Elite.

---

## 7. Backup & Restore

Формат файла `.plannerbackup` — единый контейнер:

```jsonc
{
  "magic": "ASCEND_BACKUP",
  "backupVersion": 1,          // версия формата контейнера
  "schemaVersion": <db>,       // версия схемы БД на момент экспорта
  "appVersion": "x.y.z",
  "createdAt": "...",
  "encrypted": false,
  "kdf": { ... },              // только если encrypted: алгоритм, salt, параметры
  "nonce": "...",              // только если encrypted
  "checksum": "sha256:...",    // по payload (до шифрования)
  "payload": "<base64 gzip(JSON)>"   // либо ciphertext при encrypted
}
```

Payload: tasks, recurrence_rules, goals, milestones, habits, habit_logs, focus_sessions, xp_events, achievements, categories, user_profile, settings. `daily_stats` в файл не обязателен: пересчитывается после restore.

### Создание
1. Снять консистентный snapshot (транзакция чтения).
2. Сериализовать → gzip → (опционально) AES-256-GCM с ключом из пароля (PBKDF2/Argon2 с salt).
3. Посчитать checksum, записать файл.
4. Save/Share через native picker (`share_plus` / SAF).

### Восстановление
1. Выбор файла (`file_picker`), проверка `magic`.
2. Проверка `backupVersion` и `schemaVersion`: файл **новее** приложения → отказ с понятным сообщением; **старше** → прогон через цепочку мигратторов (`v1→v2→…`).
3. Если encrypted: запрос пароля; неверный пароль и повреждённый файл различаем (GCM-тег vs checksum).
4. Проверка checksum.
5. **Preview**: дата, версия, количество tasks/goals/habits, уровень/XP. Подтверждение пользователем.
6. **Автоматический safety-backup текущих данных** перед заменой.
7. Замена данных **в одной транзакции** (всё или ничего), пересчёт `daily_stats`, перепланирование уведомлений.

MVP-режим: **Replace** (полная замена). Merge не делаем: он требует разрешения конфликтов и тесно связан с будущим sync.

### Автоматический backup (опционально)
Простая схема без фоновых сервисов: при запуске, если прошло N дней, пишем файл в app-папку, храним последние 5. WorkManager не добавляем в MVP.

### Android-нюансы
- `android:allowBackup` решаем сознательно: системный Auto Backup может восстановить БД частично/несогласованно. Предложение: отключить и полагаться на собственный `.plannerbackup`.
- Никаких прав на внешнее хранилище: только SAF/share.

### Тесты (обязательные)
Roundtrip (backup → restore = идентичные данные), повреждённый файл, неверный пароль, файл новее приложения, миграция v(N-1)→N, большой объём данных.

---

## 8. Уведомления

- `NotificationService` — интерфейс в `core/services`, реализация на `flutter_local_notifications`. Доменный код зависит только от интерфейса.
- Типы: напоминание о задаче, скорое событие (за N минут), незавершённый дневной план (вечерний).
- Глобальный выключатель в настройках: выключено → ничего не планируем и отменяем существующие.
- Android: runtime-разрешение `POST_NOTIFICATIONS` (API 33+), перепланирование после перезагрузки (`RECEIVE_BOOT_COMPLETED`), по умолчанию **inexact**-расписание; exact alarms только если реально нужны (политика Google на `SCHEDULE_EXACT_ALARM`).
- ID уведомления детерминированно выводится из `task.id` + типа, чтобы отменять и обновлять без хранения таблицы.
- Источник правды для расписания: пересобираем из БД при старте и при изменении задач.

---

## 9. Навигация (GoRouter)

Нижняя панель: **Home / Planner / Goals / Stats / Profile**, FAB `+` → bottom sheet: New Task / Goal / Habit / Note.

| Path | Экран |
|---|---|
| `/home` | Home |
| `/planner` | Planner (Today / Tomorrow / Week / Month) |
| `/goals`, `/goals/:id` | Список целей, деталь + milestones |
| `/stats` | Statistics |
| `/profile` | Profile |
| `/tasks/:id` | Деталь/редактирование задачи (+ создание через sheet) |
| `/focus/:taskId` | Focus Timer (полноэкранный, вне shell) |
| `/habits` | Привычки |
| `/achievements` | Достижения |
| `/settings`, `/settings/backup` | Настройки, Data & Backup |
| `/onboarding` | Первый запуск (имя) |

`StatefulShellRoute.indexedStack` сохраняет состояние вкладок. Focus и модальные сценарии лежат вне shell.

> Заметка из ТЗ: в FAB указан пункт **New Note**, но сущности Note в моделях (п. 19) нет. См. «Открытые вопросы».

---

## 10. Design system (tokens)

Реализуются как `ThemeExtension` + `ColorScheme` Material 3, без разбросанных hardcoded значений.

**Цвета**

| Token | Значение |
|---|---|
| `background` | `#07070A` (альтернатива `#0A0A0F`) |
| `surface` | `#101016` |
| `surfaceElevated` | `#15151D` |
| `surfaceHighest` | `#1A1822` |
| `primary` | `#7C3AED` |
| `primaryLight` | `#8B5CF6` |
| `accent` | `#A855F7` (violet/indigo) |
| `border` | белый с низкой прозрачностью (~6–8%) |
| `textPrimary / Secondary / Muted` | подбираем по контрасту WCAG AA на тёмном фоне |
| `success / warning / danger` | сдержанные, только для статусов |

**Радиусы:** карточки 16–22 px (по умолчанию 18), кнопки/инпуты 14, чипы — pill.

**Spacing:** шкала 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40.

**Typography:** Inter (bundled). Крупные числа (прогресс, XP, уровень) — отдельный `display`-стиль; `tabular figures` для таймера и статистики.

**Elevation/glow:** мягкая тень + очень умеренный radial glow только для выбранного пункта навигации, главного прогресса и Level Up. Без neon и тяжёлых градиентов.

**Motion:** 150–300 ms, ease-out. XP-анимация и Level Up короткие, без «игровых» эффектов. Уважаем системную настройку reduce motion.

**Адаптивность:** `SafeArea`, `LayoutBuilder`, `Flexible/Expanded`, без hardcoded размеров экрана; проверка на маленьких экранах и большом `textScaleFactor`.

---

## 11. Состояния экранов

Единый набор в `shared/widgets`: `LoadingSkeleton` (повторяет форму контента), `EmptyState`, `ErrorState` (с retry). Любой `AsyncValue` в UI обрабатывает все три состояния. Белых экранов и «голых» исключений быть не должно: глобальный error handler + `ErrorWidget.builder`.

---

## 12. Тестирование и качество

- **Unit:** `XpEngine` (формулы, границы уровней, ранги), расчёт streak (включая смену дня/часового пояса), генерация recurring-задач, `CompleteTask` (атомарность, идемпотентность XP).
- **Data:** репозитории на in-memory Drift, тесты миграций схемы.
- **Backup:** roundtrip, шифрование, повреждения, версии (см. п. 7).
- **Widget:** ключевые компоненты (TaskCard, ProgressRing, empty/error states), несколько golden-тестов для Home.
- **Gate на каждый этап:** `flutter analyze` без warnings, `flutter test` зелёный, сборка проходит, нет overflow в runtime.
- Время и случайность (`Clock`, `IdGenerator`) инжектируются, иначе тесты streak/XP будут нестабильными.

---

## 13. Задел под backend (не реализуем в MVP)

Сделано сейчас, чтобы потом не переписывать:
UUID-идентификаторы, `updatedAt` везде, `dayKey` независим от часового пояса, репозитории за интерфейсами (`TaskRepository` можно заменить на local+remote реализацию), `xp_events` как журнал (удобно синхронизировать), версионированный формат данных.

Не делаем: сетевой слой, auth, очередь синхронизации, Docker, FastAPI-заглушки.

---

## 14. План реализации и коммиты

Каждый этап = отдельный PR/коммит с проверкой `analyze` + `test` + сборка.

| # | Этап | Коммит |
|---|---|---|
| 0 | Architecture plan | `docs: add ASCEND architecture plan` |
| 1 | Flutter project, структура папок, зависимости, lint-правила | `chore: bootstrap project structure` |
| 2 | Тема и design tokens, базовые shared-виджеты | `feat(theme): ASCEND design system` |
| 3 | Entities + Drift schema + миграции + DAO | `feat(db): schema v1 and repositories` |
| 4 | Сервисы: Clock, Id, XpEngine, Settings | `feat(core): services and XP engine` |
| 5 | GoRouter + bottom nav + FAB sheet | `feat(nav): shell navigation` |
| 6 | Tasks: создание, завершение, `CompleteTask` | `feat(tasks): ...` |
| 7 | Home | `feat(home): ...` |
| 8 | **Backup/Restore** (рано, пока схема ещё мала) | `feat(backup): ...` |
| 9 | Planner, Goals, Habits, Focus | по фичам |
| 10 | Gamification UI (XP/Level Up), Achievements, Streak | `feat(gamification): ...` |
| 11 | Statistics, Profile, Settings | по фичам |
| 12 | Notifications | `feat(notifications): ...` |
| 13 | Полировка, анимации, a11y, `analyze` + `test` + APK | `chore: release polish` |

Backup поднят вперёд относительно п. 23 ТЗ намеренно: ТЗ требует его с первой версии, а его проще и дешевле строить на небольшой схеме, чем «догонять» ею все фичи.

---

## 15. Открытые вопросы (нужно решение до этапа 1)

1. **New Note.** В FAB есть «New Note», но модели Note нет. Варианты: (a) убрать из MVP, (b) простая сущность `notes` (id, title, body, taskId?/goalId?). Предложение: (b), минимальная.
2. **Recurring tasks.** Подтвердить подход «правило + материализация на скользящее окно» и набор правил MVP (daily / weekdays / weekly).
3. **Restore: Replace vs Merge.** Предложение: только Replace в MVP.
4. **Шифрование backup в v1** или во v1.1? Архитектура готова в любом случае. Предложение: сразу, т.к. формат контейнера проще заложить целиком.
5. **Android:** минимальная версия SDK (предложение: API 24+) и `applicationId`.
6. **Android Auto Backup:** отключить (предложение) или оставить.
7. **XP за фокус-сессии:** начислять отдельно или считать часть награды задачи.
8. **Язык интерфейса:** только English (как в ТЗ) или сразу локализация (en/ru) через `intl` ARB. Дешевле заложить сейчас, чем добавлять потом.
