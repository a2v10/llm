# Printed forms

A **printed form** is a fixed document the server builds from a template and returns as a PDF —
downloaded, sent to the print dialog, or previewed on a form. It is a **`reports`** element,
never an `action`.

**You do not know the template language — do not invent it.** It is not WPF and not the view
dialect, although the file is `.vxaml` too: its own elements, its own binding syntax. Before
writing a template, open [report/overview.md](https://docs-llm.a2v10.com/report/overview.md),
[report/elements.md](https://docs-llm.a2v10.com/report/elements.md) and
[report/table.md](https://docs-llm.a2v10.com/report/table.md), and write only what they show.
Hub — [report.md](https://docs-llm.a2v10.com/report.md); section keys →
[model/reports.md](https://docs-llm.a2v10.com/model/reports.md). This page is the wiring and the bans.

Working example (clone donor) → `examples/document/operation/` — `invoice/`: `reports.print`, `invoice.report.vxaml`, the `print` preview page, `doc.[Document.Report]`.

> **Not an on-screen report.** An interactive, filterable `Sheet` page is an `action`
> (→ `screen-report.md`). The axis is what the thing is, not where it appears: a printed form
> previewed on a form (`PdfReportViewer`) is still a `reports` element.

## Four pieces, and the names that must agree

| Piece | What it is |
|---|---|
| `reports` element in `model.json` | `"type": "pdf"`, `model`, `report` (template file name, no extension), `name` (download filename, `{{Prop.Path}}` macros) |
| template file beside `model.json` | `<report>.vxaml` (`.xaml` where the project uses that), root `<Page xmlns="clr-namespace:A2v10.Xaml.Report;assembly=A2v10.Xaml.Report">` |
| procedure `<schema>.[<Model>.Report]` | parameters as for `Load` (`@UserId`, `@Id`, plus `parameters` and query); returns the object tree the template binds |
| entry point in a view | `{BindCmd Report, Report=<key>, Url='<endpoint folder>', Argument={Bind <object>}}` with `Print=True` / `Export=True`, and/or `<PdfReportViewer Url= Report= Argument=/>` |

The `reports` key is the report's name (`Report=` on the command and the viewer); `report` is the
file. They are two different things and are often spelled alike — check both after a clone.

## Don't

- **Never omit `"type": "pdf"`.** The default type is `stimulsoft`; a Xaml template declared
  without it is never reached — no error, no document.
- **`type: "xlsx"` does not work.** The Excel engine is not implemented, though the docs list the
  value. PDF is the only form the platform builds for you.
- **No `procedure` key.** The name is always `<schema>.[<Model>.Report]` — the runtime derives it
  and never reads `procedure` here. Two reports that need different data get different `model`s,
  not different procedures.
- **Never put `If` on a `TableCell`.** The engine has no rows: cells flow one after another, so a
  hidden cell pulls every following cell back one slot and the grid shifts silently. To hide what
  a cell shows, put `If` on an element inside it — the cell keeps its slot.
- **A `Table` inside a `TableCell` is allowed** — the way to lay out a tree without `RowSpan`
  → [report/table.md § Nested tables](https://docs-llm.a2v10.com/report/table.md).
- **Never omit `Table.Columns`.** Without it the table has one full-width column: the cells of a
  row stack one under another, with no error. Text extracted from the PDF looks right — only the
  rendered page shows it.
- **Fixed column widths must fit the width they stand in** — the page for a table, the cell for a
  nested one. Otherwise the document is not built, and the error ("conflicting size constraints")
  names neither the table nor the cause.
- **`a2 view validate` checks views; a report template is not a view.** **There is no offline check
  for printed forms**: the only verification is requesting the report from the running application.
- **`Url` is the endpoint folder, not an action** — `/document/invoice`, not
  `/document/invoice/index`. The same value on the buttons and on the viewer.
- **`Argument` is not optional.** Bind the object even when its id is already in the page URL:
  that is where the procedure's `@Id` comes from.
