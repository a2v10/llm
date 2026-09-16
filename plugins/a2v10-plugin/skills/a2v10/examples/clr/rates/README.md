# Example: clr.rates — a command that runs C#

A page listing currency rates and a **`clr` command** that fills it from the National Bank of
Ukraine. Use it as the clone donor for anything that has to leave the database — an external API,
an integration.

The API needs no key
(`bank.gov.ua/NBUStatService/v1/statdirectory/exchangenew?json`), so the example runs as it stands
for whoever clones it. An example that needed a key would not.

## Folder structure in a real application

```
MainApp/
└── catalog/
    └── currencyrate/
        ├── model.json
        ├── schema.sql
        ├── logic.sql            ← must be named logic.sql to be collected (sql.json)
        ├── index.d.ts
        ├── index.template.ts
        ├── index.view.vxaml
        └── RatesHandler.cs      ← C# lives beside the endpoint it serves
```

The `.cs` sits in `MainApp` like any other file of the endpoint — `assembly=MainApp`, nothing to
wire. Its **namespace is what the file declares**, not the folder. When C# outgrows the app project
(heavy dependencies, its own structure), the types move to a separate library and `assembly=` names
that one instead — see `references/clr.md`.

## Files

| File | Purpose |
|------|---------|
| `model.json` | One `action` (the page) and one `commands` element: `type: "clr"` + `clrType`. |
| `schema.sql` | Sequence, table, and the `Code`+`Date` unique constraint the merge matches on. |
| `logic.sql` | `CurrencyRate.Index` (verb **Index**, feeds the page) and `CurrencyRate.Merge` — a TVP procedure named **explicitly**, because a clr command derives nothing. |
| `index.d.ts` | Types for the list. |
| `index.template.ts` | The `load` command: `$invoke` then `$requery`. |
| `index.view.vxaml` | Toolbar (Load / Reload) + grid. |
| `RatesHandler.cs` | The class the platform instantiates: fetch → map → one `SaveListAsync`. |
| `_default.uk.txt` *(append)* | `@CurrencyRates`, `@Rates.Load`, `@Code`, `@Rate` |

## What each layer contributes

| Layer | The part that is platform, not C# |
|-------|-----------------------------------|
| `model.json` | `clrType` in its literal form — `clr-type:<type>;assembly=<assembly>`, lowercase words, no `procedure` key |
| template | a clr command is invoked like any other: `$invoke(name, args, path)` |
| `RatesHandler.cs` | implements `IClrInvokeTarget`; **ctor takes a single `IServiceProvider`**; `IHttpClientFactory` for the call out; `SaveListAsync` for the write back; `UI:` on a user-facing error |
| `logic.sql` | data still moves only through procedures — the handler calls `CurrencyRate.Merge` by name |

## Two sets of names, deliberately kept apart

The API's names (`cc`, `txt`, `rate`, `exchangedate`) live only on the DTO and are mapped over in
one `Select`. What crosses into SQL is `CurrencyRateRow`, whose property names **are** the columns of
`cat.[CurrencyRate.TableType]` — `Code`, `Name`, `Date`, `Rate`. Nothing checks that agreement; a
rename on either side binds silently wrong. Letting a foreign API's spelling reach the TVP is how
that starts.

## Running it

1. Copy the folder into `MainApp` and apply the SQL bundle.
2. Add to `MainApp.csproj`: `A2v10.Infrastructure`, `A2v10.Data.Interfaces` and
   `Microsoft.Extensions.Http`.
3. Ask the user to **rebuild and restart the app** (Run in Visual Studio) — the host loads the
   assembly from its own output at startup, unlike xaml and `model.json`, which are read live.
4. Open the page and press **Load**: the rates appear. That is the whole chain proving itself —
   declaration → type resolved → instantiated → outbound call → one bulk write → page requeried.

The API can change shape and the example would rot silently, so a check should assert that rows
arrived — not their values.
