# Semantics — what to know about a project

The engine defines no domain meaning (SKILL.md §1). **Semantics** is everything
the project decides and you must know before touching it. It is recorded in the
project's CLAUDE.md; this file says **what it consists of** — read it to know what
to discover (existing project) or decide (new project).

## Dimensions to know

- **Kinds** — the entity categories the project uses. A *kind* bundles a schema,
  standard columns, a verb/procedure set, and a view set. **Project-defined**:
  `catalog`/`document`/`journal` (schemas `cat`/`doc`/`jrn`) are only the common
  default — an app may instead use `leads`/`contacts`, `devices`, anything. Never
  assume cat/doc/jrn; read the project's actual kinds.
- **idType** — surrogate PK type (default `bigint`, sequence per table).
- **Tenancy** — multi- or single-tenant; all-or-nothing across the project.
- **Naming** — model singular vs table plural; constraint patterns.
- **Standard columns** — per kind.

Naming defaults (table/model spelling, constraint patterns) live in
`sql-discipline.md`; the catalog standard-column set is below. The project's actual
choices go in CLAUDE.md.

## Standard columns

Default catalog set — every `cat.*` table carries these before any business field:

```sql
Id       bigint not null   -- surrogate PK; default next value for cat.SQ_<Table>
IsSystem bit    not null   -- system record;     default 0
Void     bit    not null   -- soft delete flag;  default 0
[Name]   nvarchar(255)
[Memo]   nvarchar(255)
```

Order: `Id` first, then flags (`IsSystem`, `Void`), then business fields. Other kinds
carry their own set (e.g. document headers: `Id · Void · Date · No · Operation · Memo`).

## Per-kind patterns — examples to adopt

The platform has no opinion on kinds (§1). The patterns below are the ones this
skill **demonstrates** in `examples/`; a project adopts, adapts, or replaces them
and records its actual choice in CLAUDE.md. They are the canonical reference
target for `examples/`, docs, and other layers — keep all in agreement. Authoring
detail lives in each example's README; here, only the recognition-level bundle.

**catalog** (`cat`) — flat reference entity. → `examples/catalog/simple`
- Table plural + `cat.SQ_<Table>` sequence; columns `Id · IsSystem · Void · Name · Memo` (see Standard columns above).
- Views: `index` (list page) · `edit` (dialog) · `browse` (pick dialog).
- Verbs: `Index` (list+filter) · `Load` · `Metadata` · `Update` (insert/update) · `Fetch` (browse search) · `Delete` (soft, `Void=1`).

**document** (`doc`) — header + rows, posted to journals. → `examples/document/operation`
- *Operation archetype*: one physical `doc.Documents` table for **all** document types, keyed by `Operation` (FK → `doc.Operations`); endpoints never create their own table. Header `Id · Void · Date · No · Operation · Memo` + operation-specific nullable FKs; rows in `doc.DocDetails`.
- One shared `model: "Document"`; endpoint selects its type via `parameters.Operation`. Shared verbs `Index · Load · Metadata · Update · Delete` (+ optional `<Op>.Post`).
- Posting rules in `doc.OpTrans` (`Dir ±1`, `Storno ±1`, amount `× Dir × Storno`); inter-doc links via `doc.OpLinks`/`doc.DocLinks`. Alternative `document.typed` (no shared table) — not yet exemplified.

**journal** (`jrn`) — accumulation register documents post into. → described within `examples/document/operation` (no standalone example yet)
- Endpoint at `journal/<name>/`; table `jrn.<Name>Journal`. Single-identifier convention: `OpTrans.Journal = "Stock"` → `jrn.StockJournal` → `/journal/stock`.
- Filled by document posting (`doc.OpTrans`), not edited directly.
