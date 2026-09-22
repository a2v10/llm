# validate — валідація metadata

Команда є: **`a2 meta validate <endpoint>`**. Вона збирає один endpoint і викидає зібране — те саме, що робить рантайм, тільки нічого не пишеться й база не читається. Повідомлення, які вона віддає, — повідомлення платформи; власного набору перевірок у CLI немає.

## Команда

```
a2 meta validate <endpoint>
```

`<endpoint>` — тека endpoint'а (`catalog/agent`, `document/waybillout`), `$prefix` — модуль. Запускається з кореня застосунку (де лежить `WebApp` / `WebApiHost` з `appsettings.json`). Застосунок мусить оголосити `platformid` в `app.json`: валідація типізує `Id`, не заглядаючи в базу, і базу більше нізвідки взяти — без неї падає **інструмент**, а не endpoint.

**Області «весь проект» немає.** Валідують той endpoint, який щойно правили.

## Вихід — JSON

```json
{ "success": true,
  "data": { "endpoint": "document/waybillout",
            "checks": { "declaration": "passed", "screen": "passed", "print": "passed" },
            "error": null },
  "error": null }
```

| Ключ | Що значить |
|---|---|
| `checks` | **кожна** стадія, яка для цього endpoint'а існує, зі статусом — щоб «не перевірено» читалось на місці |
| `passed` / `failed` / `unknown` | пройдено / впало / не дійшли (усе після невдалої стадії) |
| `data.error` | повідомлення тієї єдиної стадії, що впала; яка саме — видно з `failed` у мапі |
| `error` (зовнішній) | **інструмент не зміг запуститись**. Знахідка про endpoint сюди не потрапляє ніколи |

Розділення зовнішнього `error` і `data.error` — те, заради чого ця відповідь має таку форму: «endpoint не зібрався» і «команду не вдалося виконати» не змішуються. Код виходу завжди `0`, відповідь читають із JSON.

Стадії йдуть ланцюгом у порядку залежності й зупиняються на першій невдачі:

| Стадія | Що збирається | У кого є |
|---|---|---|
| `declaration` | endpoint, як його вантажить рантайм: декларація поверх сховища, seed'и, імена, зібрані форми, граф посилань, форма `post` | у кожної адреси |
| `screen` | XAML, шаблон і `.d.ts` кожної **зібраної форми** (у `browse` шаблон спільний з `index`, тож не дублюється) | у звичайного endpoint'а і в `report` — там своїм білдером |
| `print` | `Model` кожного оголошеного бланка, перетворений у SQL; розкладка не читається взагалі | у звичайного endpoint'а |

Перевірено на стенді: `catalog`, `document` (і гола адреса родини), `journal`, `enum`, `state`, `accplan`, `ledger`, `autonum` дають усі три стадії; `report` — дві, бо власного бланка в нього немає: він друкує ту сторінку, яку й малює. Системний endpoint — жодної, крім завантаження.

Форми беруться з `BakedForms`, тому в shape, який ніхто не рендерить (набір, нумерація), стадія `screen` просто порожня — «нема чого будувати» не є знахідкою. У системного endpoint'а (екран і дані в коді) стадій немає зовсім, і порожній `checks` читається як «нічого тут не перевірено», а не як згода.

Падіння виглядає так:

```json
{ "success": true,
  "data": { "endpoint": "catalog/nosuch",
            "checks": { "declaration": "failed" },
            "error": "catalog/nosuch/metadata.json: declares neither 'table' nor 'storage', so nothing says where the data lives.\n    \"table\":   \"<TableName>\"     - if this endpoint has its own table;\n    \"storage\": \"/catalog/<name>\" - if it is a second one over a table declared elsewhere (an operation, a second screen).\n  There is no default: an absent 'table' is not a shared table and not a derived name." },
  "error": null }
```

Тека без `metadata.json` дає це саме повідомлення: вона не оголосила нічого — рівно як порожній `{}`.

**Помилка за раз.** Генератори кидають, а не накопичують: одна правка — один прогін. Повідомлення береться **найзовнішнє** — саме воно несе контекст (`form 'edit': …`), який голий текст усередині вже втратив.

## 🚧 Далі — прийнята форма повідомлень, не поведінка

Інструмент сьогодні віддає **один рядок** у `data.error`; полів `file` / `path` / `available` у відповіді немає. Виняток — повідомлення про `table` / `storage` / `surface`: вони вже такі, як описано нижче, бо їх кидає сама платформа.

## Формат message

Дві складові:

1. **Що** не так і **де** — `'Total' not found in document/metadata.json fields`
2. **Де шукати** — посилання на файл/колекцію де має бути поле

`available` — замість «did you mean»: CLI повертає список, LLM сам визначає правильне значення. Простіше реалізувати, надійніше ніж fuzzy matching.

Приклади:

```json
{
  "file": "document/invoice/metadata.json",
  "path": "post[0].document.Sum",
  "message": "'Total' not found in document/metadata.json fields",
  "available": ["Sum", "Qty", "Price", "Item"]
}
{
  "path": "post[0].row",
  "message": "block 'row' requires 'each' to be set"
}
{
  "path": "post[0].journal.Sum",
  "message": "'Sum' resolves both in document fields and in details.Rows.fields — name it in 'document' or 'row'"
}
{
  "path": "post[0].each.kinds[0]",
  "message": "kind 'Goods' not declared in details.Rows.kinds",
  "available": ["Stock", "Service"]
}
{
  "path": "post[0].each.kinds",
  "message": "details.Rows declares kinds — name the ones meant; 'all of them' has no spelling",
  "available": ["Stock", "Service"]
}
```

**Немає поля `code`** — інвестиція у якість message важливіша. `code` додати коли з'явиться реальна потреба (CI-підавлення, i18n).

## Звідки форма — `table` / `storage` / `surface`

Обов'язкова перевірка на кожному endpoint-і. Три ключі — це **одна вісь**: звідки endpoint бере форму, з якою працює (`table` — своя таблиця; `storage` — таблиця, оголошена деінде, у яку я пишу; `surface` — форма, яку я тільки читаю). Легальне написання рівно одне, і **яке саме — вирішує тека**:

| Kind | Правило |
|---|---|
| `document` | рівно один із `table` / `storage` (див. `metadata.md` → «`document` — один шар або два») |
| `report` | тільки `surface`; `table` і `storage` — помилка |
| решта | тільки `table`; `storage` і `surface` — помилка |

Помилка стосується файлу цілком, тому `path` порожній — це і є ознака «дивись на файл, а не в позицію».

Повідомлення тут формулюється **як вибір між двома варіантами розкладки**, а не як «відсутній обов'язковий ключ». Різниця істотна: голе «required property missing» штовхає дописати ключ навмання, а варіант доводиться обирати свідомо — і вибір неможливо зробити випадково правильно.

```json
{
  "file": "document/goods-receipt/metadata.json",
  "path": "",
  "message": "declared both 'table' and 'storage' — these are different layouts. 'table' = own table (doc.GoodsReceipts); 'storage' = shares a table with other operations. Keep one."
}
{
  "file": "document/goods-receipt/metadata.json",
  "path": "",
  "message": "neither 'table' nor 'storage' declared — no data location. Add 'table': \"GoodsReceipts\" for an own table, or 'storage': \"document\" for an operation over shared doc.Documents."
}
{
  "file": "catalog/role/metadata.json",
  "path": "",
  "message": "does not declare 'table', so nothing says where the data lives. Add \"table\": \"<TableName>\". There is no default: a table name is never derived from the folder name."
}
{
  "file": "catalog/agent/metadata.json",
  "path": "",
  "message": "declares 'storage', which only a document endpoint may do. 'storage' shares one table across a family of operations; every other kind owns its table. Declare \"table\": \"<TableName>\" instead."
}
{
  "file": "report/stockturnover/metadata.json",
  "path": "",
  "message": "does not declare 'surface', so nothing says which shape this report reads. Add \"surface\": \"/journal/<name>\". There is no default: an absent 'surface' is not a shape of the report's own."
}
{
  "file": "report/stockturnover/metadata.json",
  "path": "",
  "message": "declares 'storage', which a report may not do. A report is a window into a shape declared elsewhere: it owns no table and writes to none. Declare \"surface\": \"<path to a journal>\" instead."
}
```

Порожній `{}` і папка без `metadata.json` ловляться цією ж перевіркою: обидва не оголосили нічого, тому дають третє повідомлення. Окремої помилки «empty file» не заводимо — вона сказала б менше.

## Ключ не в тому блоці

`fields` описує **колонку**; повнота, видимість, обчислення і успадкування — блок `rules` ([metadata.md](metadata.md) → «Що НЕ пишеться у field»). Склад ключів поля закритий (`additionalProperties: false`), тому написане в полі `required` відхиляється в будь-якому разі. Але відхилити його як **невідомий ключ** — програш: помилка передбачувана (індустрія скрізь пише її саме там), отже повідомлення під неї має бути написане заздалегідь і називати нове місце, а не факт незнайомства.

```json
{
  "file": "catalog/agent/metadata.json",
  "path": "fields.FullName.required",
  "message": "'required' is not part of a field: 'fields' describes the column, completeness is checked by the application at a moment the field cannot know. It is declared in the 'rules' block next to 'fields', and the key there is the rule, not the field: \"rules\": { \"required\": [\"FullName\"] }."
}
{
  "file": "document/invoice/metadata.json",
  "path": "details.Rows.fields.Price.required",
  "message": "'required' is not part of a field. In an operation it belongs to 'details.Rows.rules', which is also the only block an operation may write for a collection: \"details\": { \"Rows\": { \"rules\": { \"required\": [\"Price\"] } } }."
}
```

Другий частий випадок того ж класу — правильний блок, але **ключем узято поле**: `"rules": { "FullName": { "required": true } }`. Повідомлення називає інверсію прямо, бо навмання її не вгадати:

```json
{
  "file": "catalog/agent/metadata.json",
  "path": "rules.FullName",
  "message": "in 'rules' the key is the rule, not the field: \"rules\": { \"required\": [\"FullName\"] }. Each rule has its own shape - 'required' takes names, 'visible' and 'computed' take field-to-expression maps, 'inherit' takes field-to-source.",
  "available": ["required", "visible", "computed", "inherit", "when"]
}
```

Той самий клас — ключі, у яких є дім, але не тут:

| Написано в полі | Повідомлення веде | Чому |
|---|---|---|
| `required`, `visible`, `computed`, `inherit` | блок `rules` своєї області | правило поля, не форма колонки |
| `notNull`, `nullable` | ключ `default` на цьому ж полі | nullability оголошенню не підлягає: `NOT NULL` — наслідок названого значення |
| `grid`, `searchable`, `sortable`, `total`, `rows` | блок `forms` | що і де показується, вирішує форма |
| `control`, `multilineHeight` | домен поля (`type`) | контрол і вигляд виводяться, не оголошуються |
| `label`, `caption` | ключ `title` цього ж поля | підпис — locale-binding, а не вільний текст |

Повідомлення для `notNull` формулюється **як ціна входу**, а не як заборона — інакше воно штовхає шукати обхід:

```json
{
  "file": "catalog/agent/metadata.json",
  "path": "fields.Region.notNull",
  "message": "there is no 'notNull' key. A column becomes NOT NULL exactly when the field declares a 'default' — the only way in is to name the value. If what you need is a completeness check on save, that is \"rules\": { \"required\": [\"Region\"] } and it leaves the column nullable."
}
```

Обидві половини тут навмисні: сказати тільки «ключа немає» — значить лишити модель із задачею «зробити поле обов'язковим» і без адреси, а тоді найкоротшою відповіддю стане вигаданий `default` на домені, у якого нульового значення за змістом немає.

## 🚧 resolved metadata

Цього в команді немає: успішний прогін віддає лише мапу стадій. Прийнята форма — повертати повний ефективний metadata з усіма застосованими defaults:

```json
{
  "valid": true,
  "resolved": { ...повний ефективний metadata... }
}
```

LLM використовує `resolved` для верифікації: написав sparse metadata → перевірив що resolved відповідає наміру → якщо ні → править файл.

`resolved` — read only. Не переписувати вміст назад у `metadata.json`.
