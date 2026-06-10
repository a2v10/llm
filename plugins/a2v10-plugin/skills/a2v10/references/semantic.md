# Semantics — what to know about a project

The engine defines no domain meaning (SKILL.md §1). **Semantics** is everything the
project decides and you must know before touching it. It lives in **two files**, split
by grain:

- **Skeleton → `CLAUDE.md` (`## Semantics`)** — project-wide decisions fixed at setup:
  a one-line app identity, the global conventions (idType, tenancy, naming, standard
  columns), and kind *definitions* **only where the project deviates** from this skill's
  defaults (see *Kinds* below). Bounded — does not grow with the table count; thin
  (near-empty) for a vanilla cat/doc/jrn app, and that is correct.
- **Domain → `DOMAIN.md`** — per-entity meaning, grown over time, never dumped at setup
  (see *DOMAIN.md — the per-entity registry* below).

This file says **what semantics consists of** — read it to know what to discover (existing
project) or decide (new project).

## Dimensions to know — the skeleton (→ `CLAUDE.md`)

- **Kinds** — the entity categories the project uses; a *kind* bundles a schema,
  standard columns, a verb/procedure set, and a view set. `catalog`/`document`/`journal`
  (schemas `cat`/`doc`/`jrn`) are only the common default — never assume them; read the
  project's actual kinds. **Record a kind's *definition* in `## Semantics` only when it
  departs from the default** — own kinds (`leads`/`devices`), changed standard columns, a
  different verb/view set. For the defaults the skill (this file + `examples/`) is the home —
  point, don't copy. Two non-facts to keep out: the *list* of kinds in use (derivable from
  `DOMAIN.md` as `DISTINCT kind`) and any restatement of default kind behaviour. *Which*
  kind each entity is lives in its `DOMAIN.md` entry, not here.
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

## DOMAIN.md — the per-entity registry

The project's accumulated domain knowledge: one entry per entity, carrying meaning the
code **cannot** express — never a restatement of the schema (that rots; the `a2` CLI
already reports columns and refs). It doubles as the registry of what exists, so each
entry carries a status.

Entry shape:

```markdown
## <Entity> — <kind>
confirmed at catalog/agent
depends on: <Entity>, <Entity>          (or  —  when nothing)
<one line: what it is and its role in the domain>
- relationships, invariants, "don't do X" — only what the schema can't say
```

### State line — one axis, three values

The second line is the **state line**: the model's grounded relation to the entity, on a single
axis. The path is the endpoint folder (e.g. `catalog/agent`).

- **`planned`** — decided, not built. Next: build it.
- **`confirmed at <path>`** — built and verified (procedure read, residue captured). Next: trust it.
- **`out of scope`** — seen and deliberately not worked out (a dead table, an unreachable tail).
  Next: don't touch — the recorded form of *"don't know → don't touch"*; the tail is named, not absent.

One line, the **worklist and index in one**: what is left (`planned`), what is known (`confirmed`),
what is parked (`out of scope`). Two entry points converge at `confirmed`:

- **new project** — `planned → confirmed`: building is knowing (you authored it).
- **existing project** — an entry is **born `confirmed` on first touch**: the touch reads the
  procedure (that read *is* the verification), then writes the entry. Until touched, an entity has
  no entry — an empty registry over a built app is the normal state, not a gap. `planned` does not
  occur — everything is already built.

The deep meaning (invariants, relationships, "don't do X") is written **when the entity is touched**,
not guessed ahead — a `planned` entry is a one-line stub, a `confirmed` one carries the residue.

### Grounding

Every line of an entry must be groundable — the schema, a procedure body, or the user's word says it.
Can't ground it → leave it out, or mark the entity `out of scope`.

**`depends on`** — the entities this one actually references (`—` when none). A *preference,
not a gate*: a build order (dependents after their targets) and what to read first (their
entries; the built schema of any `confirmed` — don't invent columns/keys). FK constraints go
to `keys.sql` after all tables, so order is free — a not-yet-built or **cyclic** dependency
never blocks; reference its `Id`. Only real references: a cycle is tolerated, not a licence to
invent edges. In an **existing project** `depends on` is filled **on touch** (from `table-columns`
`ref`) — build-order is moot when everything is already built, and reading every
table's FKs up front is the bomb the 90/10 line forbids.

- **before** working an entity — read its entry, if any;
- **after** building or changing it — write or update the entry, residue-only. In the
  current phase, confirm the entry with the user before writing it.

A **bare app** (no domain) has an empty `DOMAIN.md` and a stub `## Semantics` in CLAUDE.md — the
stub is what routes its first domain task to `new-semantic.md` (SKILL.md §6). Treat any
entry as belief to verify against code, not ground truth — never a restatement of the schema.
