# Example: report.list — on-screen report (flat list)

The minimal **on-screen report**: a period (+ optional agent) filter, a flat list of
documents, a total. Use it as the clone donor for screen reports; for trees and drill-down
(`SheetTreeSection`, with a working example) →
[xaml/layouts/sheet.md](https://docs-llm.a2v10.com/xaml/layouts/sheet.md).

> "Report" here means **on-screen** — an `action` rendering a `Sheet`, the common case.
> A report exported **to a file** (PDF/xlsx) is a different thing — the `reports` section
> of `model.json`. See `references/screen-report.md` for the split.

## Folder structure in a real application

```
MainApp/
└── reports/
    ├── _common/
    │   └── _plain.template.ts       ← report engine (once per app)
    ├── _components/
    │   └── report.components.vxaml  ← toolbar + NoRunPanel (once per app)
    └── list/                        ← one report endpoint
        ├── model.json
        ├── logic.sql                ← must be named logic.sql to be collected (sql.json)
        ├── documentlist.template.ts
        └── documentlist.view.vxaml
```

> The proc file **must** be `logic.sql` (alongside `schema.sql`/`keys.sql`/`init.sql`) — the
> build's `sql.json` collects those names by pattern; any other name is silently skipped.

`_common` and `_components` are written **once per app** and shared by every report.
A new report adds only an endpoint folder (here `list/`). A `reports/x/model.json` may
hold several unrelated report models — grouping is the author's choice (see SKILL.md §4).

## Files

| File | Purpose |
|------|---------|
| `_common/_plain.template.ts` | Report engine: `generate` (Filter round-trip), dirty/loading/Run lifecycle. Extended by every report template. |
| `_components/report.components.vxaml` | `ReportToolbar` (run / print / export / regenerate alert) and `NoRunPanel` (pre-run empty state). |
| `list/model.json` | `schema: rep`; one `action` → model `Report.Document.List`. |
| `list/logic.sql` | `rep.[Report.Document.List.Load]` — verb **Load**. Filter applied once into a `#docs` temp table, then flat `Array` + lookup `Map`s (`group by` over `#docs`) + `Filter` echo. |
| `list/documentlist.template.ts` | Extends `_plain`; adds one computed `Sum`. |
| `list/documentlist.view.vxaml` | Taskpad filters + `Sheet` (header params, column header, total, data rows). |

## The three layers that make a screen report

| Layer | Fixed (infra) | Per-report |
|-------|---------------|------------|
| model.json | `schema: rep`, action+view+template | `model: Report.*`, action name |
| SQL | verb `Load`, `Filter!TFilter!Object` echo, period default | data result sets (`Array`/`Tree` + `Map`) |
| template | `_plain.template` (generate / dirty / Run / loading) | computed properties |
| view | Taskpad filters, `Sheet` + styles, `report.components`, `NoRunPanel` | the Sheet columns/rows |

## Filter round-trip (the report's contract)

Names must agree across three points or a filter silently won't apply:

```
Filter.Agent (Selector value, view)  ↔  @Agent (proc param)  ↔  [Agent!TAgent!RefId] (Filter echo)
```

The echoed `Agent` is a `RefId` into the same `TAgent` map the rows use — its name comes from
that one map, not a second lookup. So `@Agent` is inserted into `#docs` before the map is built,
which keeps the filtered agent in the map even when it has no documents in the period.

`generate` (in `_plain`) flattens `Filter` into URL params — `Period` → DateUrl, a Selector
object → its `.Id`, an array → `.$ids` — then `$requery`s. The proc echoes the parameters
back in the `[Filter!TFilter!Object]` result so the Sheet header can print them and the
next regenerate re-posts them.

## Lifecycle (Run / dirty)

1. **Not run yet** — `Filter.Run` is false: the `Sheet` is hidden (`If="{Bind Filter.Run}"`),
   `NoRunPanel` invites the user to generate.
2. **Run, clean** — data shown.
3. **Run, dirty** — a filter changed since the last run: `$AlertVisible` lights the toolbar
   alert ("parameters changed — regenerate") and `$SheetPageClass` dims the sheet.

## Markers worth noting

- `[RepData!TRepData!Array]` — flat list. (A drill-down report uses `!Tree` with a self
  `ParentId`; out of scope here.)
- `[Operation!TOperation!RefId]` + `[!TOperation!Map]` — carry a lookup by id in the data
  rows, resolve it once in a separate `Map` result, instead of joining per row.
- `[Filter!TFilter!Object]` — the parameter echo (see round-trip above).

## Dependencies

- Tables `doc.Documents`, `doc.Operations` (from the `document.operation` example) and a
  `cat.Agents` catalog with a `/catalog/agent` endpoint (the `Agent` FK that example declares).
- Localization keys to append to `_default.uk.txt`: `@[Report.Documents]`, `@[Generate]`,
  `@[Generate.Now]`, `@[Report.ParamsChanged]`, `@[Report.NotRunYet]`,
  `@[Placeholder.All.Agent]`, plus the standard `@[Period]`/`@[Agent]`/`@[Date]`/`@[Sum]`/etc.
