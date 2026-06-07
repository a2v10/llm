# CLI — принципи (LLM-first)

## Наявність

Перед використанням переконайся, що CLI `a2` доступний. Якщо ні — встанови його сам або попроси користувача.

> TODO: зафіксувати точну команду встановлення та спосіб перевірки (напр. `a2 --version`).

## Основний принцип: CLI для LLM, не для людини

Кожен виклик ізольований. LLM отримує тільки те, що повернула команда. Якщо не повернула — не знає.

## Що з цього випливає

**Немає:**
- `init` / `new` / scaffold — LLM читає references і пише файли напряму.
- Інтерактивних промптів — "Are you sure?" зависне. Ніколи.
- ANSI кольорів — шум для парсера.
- `--json` як opt-in — JSON є завжди.

**Є:**
- JSON вивід за замовчуванням, завжди.
- Ідемпотентність — безпечно запустити двічі.
- Verbose за замовчуванням — LLM потребує повноти, не стислості.
- Повний опис що змінилося, не тільки success/fail.
- Структуровані помилки з `available` / actionable guidance.

## Формат відповіді

Успіх:
```json
{ "success": true, "data": { ... } }
```

Помилка:
```json
{ "success": false, "error": { "message": "..." } }
```

## Канонічний формат таблиці

`schema.[Table]` — використовується скрізь: як аргумент команд і у відповідях.

Приклади: `cat.[Agents]`, `doc.[Invoice]`, `cat.[Agent.Addresses]`.

Дужки обов'язкові — назва таблиці може містити крапку.

## Команда `a2 app config` — конфігурація проєкту

Повертає рішення рівня застосунку, які треба **записати в CLAUDE.md** під час онбордингу існуючого проєкту (SKILL.md §5 → `references/existing-project.md`), і перелік модулів.

```json
{
  "success": true,
  "data": {
    "multiTenant": false,
    "modules": [
      { "prefix": "$admin",    "root": null },
      { "prefix": "",          "root": "MainApp" },
      { "prefix": "$meta",     "root": null },
      { "prefix": "$workflow", "root": null }
    ]
  },
  "error": null
}
```

- `multiTenant` — чи проєкт багатоорендний (впливає на параметри/WHERE процедур).
- `modules` — перелік модулів застосунку (див. нижче).

У `data` можуть бути й інші поля — **не твої**: вони обслуговують інші інструменти. Ігноруй їх, читай лише `multiTenant` і `modules`.

> TODO: підтвердити повний склад полів (idType, схеми, базова локалізація, …).

### `modules` — модулі й маршрутизація

URL endpoint-а може починатися з модульного префікса: `/[$<module>]/<path>/<action>/<id>`. Кожен запис:

- **`prefix`** — дослівний URL-токен модуля, **разом із `$`** (`"$admin"`); `""` — головний застосунок (без префікса).
- **`root`** — папка-source модуля, шлях **від кореня проєкту, без провідного слеша** (`"MainApp"`). `null` — у модуля немає локальної папки.

LLM складає з цих полів дві формули:

- **URL** = `prefix` + `/<path>/<action>/<id>` — завжди (працює і для `root: null`).
- **Файл** = `root` + `/<path>/...` → `…/model.json` — **тільки коли `root` не `null`**.

`root: null` → endpoint-и модуля існують лише як зібраний артефакт: їх можна викликати й лінкувати (`prefix`-формула), але **писати нікуди — source-розташування фізично немає**. Не створюй для них папок.

## Команди `a2 db`

### `a2 db tables [schema]`

Список таблиць згрупованих за схемою. `schema` — необов'язковий фільтр.

```json
{ "success": true, "data": ["cat.[Agents]", "cat.[Units]", "doc.[Invoice]"] }
```

### `a2 db table-columns cat.[Agents]`

Структура таблиці. Конвенції: `Id` — завжди PK, FK-колонки nullable.

```json
{
  "success": true,
  "data": {
    "columns": [
      { "name": "Id",    "type": "bigint" },
      { "name": "Name",  "type": "nvarchar(255)" },
      { "name": "Agent", "type": "bigint", "ref": "cat.[Agents]" }
    ]
  }
}
```

`ref` — канонічний формат таблиці.

### `a2 db referenced-by cat.[Agents]`

Таблиці і колонки, що посилаються на дану таблицю.

```json
{
  "success": true,
  "data": [
    { "table": "doc.[Invoice]", "column": "Agent" },
    { "table": "doc.[Order]",   "column": "Agent" }
  ]
}
```

## Команди `a2 endpoint` — сімейство `resolve-*`

По команді на секцію model.json. Кожна резолвить один елемент так, як його бачить рантайм: під які процедури й файли він зв'язаний і яку форму моделі віддає. Це answer key для звірки шарів — не вгадуй форму зі своїх маркерів, звір її з тим, що рантайм реально зібрав.

`route` адресує елемент (`/[$<module>]/<path>/<element>`), напр. `catalog/agent/edit`. **Без `id`** — типи беруться зі схеми result-set-ів (метадані колонок), не з даних; реальний запис не потрібен.

`dataModel` дістається **викликом** `load/index`-процедури, тож якщо її нема — команда падає цілком (`success: false`, `error`), а не повертає частковий результат.

**Коли кликати — post-deploy, дискреційно.** Це верифікаційна половина петлі «написав → звір», не authoring-time: процедури мусять уже існувати (міграції застосовані) і `build` зроблений. До деплою команда падає **за дизайном** — це означає «ще не задеплоєно», не «зламано». Виклик не обов'язковий після кожної дрібниці; деплой може бути не в руках LLM — тоді просто нема чого звіряти.

Зараз є три команди нижче. `resolve-popup` / `resolve-report` / `resolve-files` — додаються в міру потреби.

### `a2 endpoint resolve-action <route>` · `a2 endpoint resolve-dialog <route>`

Renderable — `actions` (page) і `dialogs` (modal). **Форма виводу однакова**; різниця лише в тому, в якій секції model.json шукати ім'я (команда = дзеркало секції, не різниця контракту).

```json
{
  "success": true,
  "data": {
    "route": "catalog/agent/edit",
    "model": "Agent",
    "view":     { "dir": "catalog/agent/edit", "file": "view.dialog.xaml" },
    "template": { "dir": "catalog/agent/edit", "file": "edit.template.ts" },
    "sqlProcedures": {
      "load":   "cat.[Agent.Load]",
      "update": "cat.[Agent.Update]"
    },
    "dataModel": {
      "types": {
        "TRoot":  { "props": { "Agent": { "type": "TAgent", "len": null } }, "id": null, "name": null },
        "TAgent": { "props": { "Id":    { "type": "number", "len": null },
                               "Name":  { "type": "string", "len": 100 },
                               "Store": { "type": "TStore", "len": null } }, "id": "Id", "name": "Name" },
        "TStore": { "props": { "Id":   { "type": "number", "len": null },
                               "Name": { "type": "string", "len": 100 } }, "id": "Id", "name": "Name" }
      }
    }
  },
  "error": null
}
```

- **`model`** — головний редагований об'єкт; інші кореневі props (lookup-списки для комбо) — не сутність.
- **`view`/`template`** — `{ dir, file }`: `dir` через `/` (як `route`), `file` — реальне ім'я з розширенням, готове відкрити. `template.file` — **source для правки** (`.ts`; якщо нема — `.js`), не скомпільований `.js`. Перевірки наявності нема навмисно: відсутній або невірно названий файл покаже `build`, не resolve.
- **`sqlProcedures`** — verb (нижній регістр) → реальне SQL-ім'я процедури, яке рантайм покличе, готове до `CREATE OR ALTER` (схема без дужок, як канон `cat.[T]`). Набір залежить від елемента: `edit` → `load`+`update`, без `index`. Explicit і derived не розрізняються — потрібне ім'я, не походження.
- **`dataModel.types`** — типове дерево, яке рантайм згенерував зі схеми result-set-ів; проєкція платформного model-опису 1:1. Кожен prop має `type` + `len`: `len` = `null`, крім рядка із заданою довжиною (`"string"`, `len: 100`). Примітиви — нижній регістр (`number`/`string`/…); іменований тип — `T…`; масив → `{ "item": "T…" }`. `id`/`name` присутні завжди (`null`, коли нема, як у `TRoot`). Це те, з чим звіряєш XAML-binds і що мали віддати твої SQL-маркери.

### `a2 endpoint resolve-command <route>`

Callable — секція `commands`. На відміну від renderable: **`view`/`template` відсутні**; `sqlProcedures` = те, що команда реально кличе (derived verb або explicit `procedure`/clr/api); `dataModel` — **лише якщо команда повертає модель**, інакше null.
