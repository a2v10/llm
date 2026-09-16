# document.operation — Document-with-operations archetype

Archetype for documents where different operation types are stored in **a single table**.
Example: warehouse operations (Receipt, Issue, Transfer).

## Principle: a single `doc.Documents` table for the whole system

`document.operation` is not just "an archetype for warehouse". It is an architectural decision about
**a single physical `doc.Documents` table for all document types in the application**:
invoices, bills, payments, contracts, timesheets, requests — all in one table,
distinguished by `Operation`.

**Consequences:**
- The `doc.Documents` header is extended by adding columns as the application
  needs them. 10–20 FK columns is fine — not a problem for SQL (use `SPARSE`
  for rarely populated columns if needed).
- A new column is added to the **shared** `document/schema.sql`, not to an endpoint.
  For operations where the field is unused — NULL.
- The endpoint of a specific operation does not create its own table. Ever.

**Why this architecture:** a unified document table is the foundation of an accounting
system. Posting journals (`doc.OpTrans`, `jrn.*Journal`) work with a single
entry point; document-to-document links (`doc.DocLinks`) likewise rely on a
unified PK. Splitting documents across typed tables breaks journals
and posting.

**When this archetype is NOT a fit:** if the application has no
accounting logic at all (pure CRUD without journals, posting, or
document-to-document links) — consider `document.typed` (when ready).

## Folder structure in a real application

```
MainApp/
└── document/                        ← shared files (once for all operations)
    ├── schema.sql                   — tables: Operations, Documents, Details, OpLinks, OpTrans, DocLinks
    ├── keys.sql                     — FKs
    ├── logic.sql                    — Document.Index, Load, Metadata, Update, Delete
    ├── index.d.ts / edit.d.ts       — base TypeScript types
    ├── index.template.ts / edit.template.ts — base templates
    │
    └── invoice/                     ← endpoint of a specific operation
        ├── model.json               — parameters.Operation = "invoice"
        ├── init.sql                 — INSERT INTO doc.Operations
        ├── index.view.vxaml         — journal of documents for this operation
        ├── edit.view.vxaml          — edit form
        ├── print.view.vxaml         — printed form preview page (PdfReportViewer)
        ├── invoice.report.vxaml     — printed form template (A2v10.Xaml.Report)
        └── logic.sql                ← optional: operation-specific procedures (Invoice.Post, etc.)
```

> **Note about `examples/document/operation/`**
> This folder is a combined example: shared SQL files (`schema.sql`, `keys.sql`, `logic.sql`)
> and endpoint files (`model.json`, `init.sql`, `*.view.vxaml`) live together.
> In a real application the shared files live in `document/`, the endpoint in `document/invoice/`.

## File structure

### Shared files (document/)

| File | Purpose |
|------|---------|
| `schema.sql` | Tables `doc.Operations`, `doc.Documents`, `doc.DocDetails`, `doc.OpLinks`, `doc.OpTrans`, `doc.DocLinks` |
| `logic.sql` | Procedures: `Document.Index`, `Document.Load`, `Document.Metadata`, `Document.Update`, `Document.Delete`, `Document.Report` |
| `keys.sql` | FKs to catalogs |
| `index.d.ts`, `edit.d.ts` | Base types for templates |
| `index.template.ts`, `edit.template.ts` | Base templates |

### _components/

Folder for XAML components shared across all operations of the application.
The `ComponentDictionary` pattern — see `references/xaml.md`.

### Operation endpoint files (document/{operation}/)

| File | Purpose |
|------|---------|
| `model.json` | Configuration with `parameters: { Operation: '...' }` |
| `init.sql` | `INSERT INTO doc.Operations` (if not exists) |
| `index.view.vxaml` | XAML for the operation's document list |
| `edit.view.vxaml` | XAML for the edit form |
| `print.view.vxaml` | Printed form preview: `PdfReportViewer` + Print / Export buttons |
| `invoice.report.vxaml` | Printed form template — its own dialect, not a view (→ `references/print-form.md`) |
| `index.d.ts`, `edit.d.ts` | *(optional)* Type extensions |
| `index.template.ts`, `edit.template.ts` | *(optional)* Template extensions |
| `logic.sql` | *(optional)* Operation-specific logic (e.g. `Invoice.Post`) |

## Edit form: keep the TabBar scaffold

The document edit form (`edit.view.vxaml`) keeps `TabBar` + `Switch` even with a **single** tab. It looks redundant for one tab, but it is the extension point: a new section (payments, document links, history) is one `TabButton` + one `Case`. Collapsing it to a bare section trades a couple of lines now for rebuilding the form's structure on the next extension. Do not remove it.

## Printed form

The shared `Document.Toolbar` leaves a `Print` slot (`<ComponentSlot Name="Print"/>`); each operation fills it, because only the operation knows its endpoint. The chain in `invoice/`:

- the `Print` button → `{BindCmd Open, Url='/document/invoice/print', SaveRequired=True}` — the document is saved first, so the report has an `Id`;
- action `print` (`print.view`) — a page with `PdfReportViewer` and Print / Export buttons, all pointing at `Report=print`, `Url='/document/invoice'`;
- `reports.print` in `model.json` — `type: pdf`, template `invoice.report`;
- `doc.[Document.Report]` — calls `Document.Load`, so the form prints exactly the model the edit page shows.

## DB schema

### doc.Operations
Catalog of operation kinds. `Id` is a text key, matching the endpoint name.

Fields: `Id nvarchar(20) PK`, `Name nvarchar(255)`

### doc.Documents
A single table for all operations. `Operation` is an FK to `doc.Operations`.

Required fields: `Id bigint`, `Void bit`, `Date date`, `No nvarchar(32)`, `Operation nvarchar(20)`, `Memo nvarchar(255)`

Additional fields are operation-specific; for others, `NULL`.

### doc.DocDetails
Detail rows (optional). FK `Doc bigint → doc.Documents`.

### doc.OpLinks
Rules for links between operations — defines which documents can be created "based on" another.

Fields: `Id int identity PK`, `Parent nvarchar(20)`, `Child nvarchar(20)`, `Kind nvarchar(50)`
Unique constraint on `(Parent, Child, Kind)`.

Example: `('Invoice', 'Receipt', 'Shipment')` — a receipt can be created from an invoice.

### doc.OpTrans
Rules for posting to journals.

Fields: `Operation nvarchar(20)`, `Journal nvarchar(20)`, `Dir smallint`, `Storno smallint`
PK: `(Operation, Journal, Dir)`. CHECK constraints: `Dir IN (1,-1)`, `Storno IN (1,-1)`.

`Dir`: `+1` receipt, `-1` issue. Posting formula: `Amount * Dir * Storno`.

The "Transfer" operation — two rows with different `Dir` (one +1, one -1).

### doc.DocLinks
Actual links between specific documents.

Fields: `ParentId bigint FK → doc.Documents`, `ChildId bigint FK → doc.Documents`, `LinkId int FK → doc.OpLinks`

## Binding the operation in model.json

```json
"actions": {
    "index": {
        "index": true,
        "model": "Document",
        "parameters": {
            "Operation": "invoice"
        }
    },
    "edit": {
        "model": "Document",
        "parameters": {
            "Operation": "invoice"
        }
    }
}
```

The SQL procedures are shared (`doc.[Document.Index]` etc.) — the operation is passed as a parameter.

## Journals

Journals are a separate archetype, the endpoint lives at `journal/{name}/`. Single-identifier convention:

| In OpTrans | Table | Endpoint |
|-----------|---------|----------|
| `Stock` | `jrn.StockJournal` | `/journal/stock` |

## Dependencies

Before applying `keys.sql`, all catalogs referenced by FKs in `document/schema.sql` must exist.

## Initialization

Each endpoint has an `init.sql` that registers its operation:

```sql
if not exists (select 1 from doc.Operations where Id = N'invoice')
    insert into doc.Operations (Id, [Name]) values (N'invoice', N'Invoice');
```
