# On-screen reports

An **on-screen report** is an interactive, filterable page that renders a `Sheet` —
the default meaning of "report" (звіт) in this skill. It is an **`action`** (Renderable),
not the `reports` section.

> **Not the same as a file report.** The `reports` *section* of `model.json` is for reports
> exported **to a file** (PDF/xlsx/xml/json), rendered by the server → `references/model-json.md`.
> They split by rendering path: on screen → `action` here; to a file → `reports` section.
> A task that says "report" without naming a file/format means this one.

Working example (clone donor) → `examples/report/`. This page is the index and the contract;
`Sheet` authoring — sections, row/cell styles, spans, column grammar, tree groups, cross
columns, Excel export → [xaml/layouts/sheet.md](https://docs-llm.a2v10.com/xaml/layouts/sheet.md).

## What is infrastructure vs. per-report

A screen report is mostly shared engine plus a thin per-report layer.

| Layer | Shared, once per app | Written per report |
|-------|----------------------|--------------------|
| model.json | `schema: "rep"`, action binds view+template | `model` (`Report.*`), action name |
| SQL | verb **`Load`**, `Filter` echo, period default | data result sets + lookup `Map`s |
| template | `/reports/_common/_plain.template` (engine) | computed properties only |
| view | `/reports/_components/report.components` (`ReportToolbar`, `NoRunPanel`), Taskpad + `Sheet` shell | the Sheet's columns and rows |

`_plain.template` and `report.components` are **app files you copy once**, not engine surface
and not scaffold — they ship with the first report (see `examples/report/`). A new report
reuses them; it does not rewrite the lifecycle.

## Conventions (not engine rules)

`schema rep`, the `Report.*` model namespace, the `reports/` folder, and verb `Load` are how
apps usually arrange screen reports — not platform requirements. The engine only sees an
`action` with a `view`+`template` and a `Load` proc. Match the project's existing reports;
where it has none, the example's layout is a reasonable default.

## Filter round-trip — the report's contract

The filter object travels client → proc → client, and the names must agree at all three
points or the filter silently fails to bind:

```
Filter.<X>  (Selector/Picker value in the view)
   ↔  @<X>            (proc parameter)
   ↔  [<X>.Id!T<X>!Id] / [<X>!T..!RefId]  (Filter echo result set)
```

- **Client half** (`generate`, in `_plain.template`): flattens `Filter` into URL params —
  `Period` → `DateUrl`, a Selector object → its `.Id`, an array → `.$ids` — then `$requery`.
- **Server half**: the `Load` proc reads those params, and **echoes them back** in a
  `[Filter!TFilter!Object]` result so the Sheet header can print the chosen parameters and
  the next regenerate re-posts them.

## Lifecycle (Run → clean → dirty)

Driven by `_plain.template` + `report.components`:

1. **Not run** — `Filter.Run` false → `Sheet` hidden (`If="{Bind Filter.Run}"`), `NoRunPanel` shown.
2. **Run, clean** — data displayed.
3. **Run, dirty** — a filter changed since last run → `$AlertVisible` shows the "regenerate"
   alert, `$SheetPageClass` dims the sheet. Pressing generate re-runs and clears dirty.

## Data shape

The data result sets are ordinary result-set markers (→ `references/sql-rules.md`); reports
lean on two in particular:

- **Flat list** — `[RepData!TRepData!Array]`.
- **Drill-down tree** — `[RepData!TRepData!Tree]` with a self `ParentId`, rendered by a
  `SheetTreeSection`. Levels with colliding ids are kept distinct with a synthetic id
  (`<realId, level>`). `SheetTreeSection` authoring, with a working drill-down example →
  [xaml/layouts/sheet.md](https://docs-llm.a2v10.com/xaml/layouts/sheet.md).
- **Lookups** — `[<X>!T..!RefId]` in the rows + a `[!T..!Map]` result that supplies each
  referenced object once, instead of joining per row.

## Don't

- Don't put a screen report in the `reports` section — that's file export only.
- Don't reach for verb `Index` (that's the list of an *entity* endpoint); a report loads as
  one object (Filter + data) → verb `Load`.
- Don't rewrite the lifecycle in each report — extend `_plain.template`, don't replace it.
- Don't wrap the report data in a `CollectionView`. It auto-reloads on any filter change —
  in a report that re-runs a heavy query needlessly and defeats the Stale → regenerate
  lifecycle (the result must stay put until **Generate**). Keep the filter a plain `Filter`
  object and refresh by hand (`generate` → `$requery`).
- Don't paginate — no `Offset`/`PageSize`. A report returns the **whole** filtered set; the
  `Total` (a client `$sum` over `RepData`) and print/export run over all rows, so a page would
  silently corrupt the total and truncate the output. (Contrast `Sample.Index`, which pages.)
