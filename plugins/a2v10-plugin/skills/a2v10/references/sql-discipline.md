# SQL authoring discipline

Conventions for **tidy, re-runnable SQL**. None of it is a platform requirement — the
engine ignores constraint names, table/model spelling, and re-run guards. Rename or drop
any of it and the app still works; we keep it for consistency and safe migrations.
Platform-enforced binding rules → `sql-rules.md`; what proc to write per case → `sql-procedures.md`.

## Naming

- Catalog tables live in the `cat` schema; documents — in their business schemas (`doc`, `jrn`, …).
- Table name is **plural**: `cat.Samples`. Model name (in `model.json` and procedure names) is **singular**: `Sample`. The runtime derives the proc name from whatever `model` you declare (SKILL.md §3) — singular is just the readable convention, not a requirement.
- Sequence for the surrogate PK: `cat.SQ_Samples` (plural).
- Type token in markers: `T` + singular model — `Sample → TSample`, `Agent → TAgent`.
- Reserved words always wrapped in square brackets: `[Name]`, `[Status]`, `[Date]`, `[Type]`.

**Constraint naming:**

| Type         | Pattern                                  | Example                  |
|--------------|------------------------------------------|--------------------------|
| Primary key  | `PK_<Table>`                             | `PK_Samples`             |
| Default      | `DF_<Table>_<Column>`                    | `DF_Samples_Id`          |
| Foreign key  | `FK_<Table>_<Column>_<RefTable>`         | `FK_Orders_Agent_Agents` |
| Check        | `CK_<Table>_<Column>`                    | `CK_Banks_Status`        |
| Unique       | `UQ_<Table>_<Columns>`                   | `UQ_OpLinks_Key`         |

> FK column names skip the `Id` suffix: `Agent bigint`, `Category bigint`.

## Idempotency

All SQL scripts are **idempotent** — they can be re-run without errors or side effects. Each DDL block ends with `go`.

Guard catalog:

| DDL              | Guard                                                                  |
|------------------|------------------------------------------------------------------------|
| `CREATE SCHEMA`  | `sys.schemas` (`name`) — **and the statement goes through `exec sp_executesql`**: `create schema` must be the first statement in its batch, so it cannot sit under `if` directly. Scaffold ships `cat`/`doc`/`jrn`/`rep` in `_sql/_schemas.sql` |
| `CREATE TABLE`   | `INFORMATION_SCHEMA.TABLES`                                            |
| `ADD COLUMN`     | `INFORMATION_SCHEMA.COLUMNS` (`TABLE_SCHEMA`+`TABLE_NAME`+`COLUMN_NAME`)|
| `ADD CONSTRAINT` | `sys.objects WHERE type IN ('F','C','UQ','D')`                         |
| `CREATE INDEX`   | `sys.indexes` — key is `object_id(N'<schema>.<table>')` **+** `name`. Index names are unique per **table**, not per database: a `name`-only guard is satisfied by a same-named index on another table and the index is then silently never created |
| `CREATE SEQUENCE`| `INFORMATION_SCHEMA.SEQUENCES`                                         |

```sql
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES
    where SEQUENCE_SCHEMA = 'cat' and SEQUENCE_NAME = 'SQ_Samples')
    create sequence cat.SQ_Samples as bigint start with 100 increment by 1;
go

if not exists(select * from INFORMATION_SCHEMA.TABLES
    where TABLE_SCHEMA = 'cat' and TABLE_NAME = 'Samples')
create table cat.[Samples] ( ... );
go
```

> No `N''` prefix in guards: `INFORMATION_SCHEMA` columns are `sysname` (nvarchar) — the literal is widened automatically, `N` adds nothing.

`TableType` and dependent procedures are recreated via `drop ... if exists` + `create`:

```sql
drop procedure if exists cat.[Sample.Metadata];
drop procedure if exists cat.[Sample.Update];
drop type      if exists cat.[Sample.TableType];
go
```

## How the bundle is assembled — the one thing here that is *not* a convention

Your `.sql` files never reach the database as written: `sql.json` concatenates them into one
`outputFile` (SKILL.md §4), and that script is what gets applied. Two properties of the
concatenation decide where a statement may live.

- **Across masks — guaranteed.** `inputFiles` is an explicit ordered list, and the build follows
  it exactly: platform base → `_sql/_schemas.sql` → `/**/schema.sql` → `/**/keys.sql` →
  `/**/logic.sql` → `/**/init.sql`. This is why every table exists before any FK, and every table
  before any procedure — the guarantee comes from the array, not from any cleverness.
- **Within one mask — none.** The fragments arrive in filesystem enumeration order: not
  alphabetical, not creation order, and `_`-prefixed folders (`_home`, `_components`) are **in**,
  they sort after the letters. Treat the order as unspecified: **no fragment may depend on another
  fragment collected by the same mask.**

Consequence, and the reason for the ownership rule below: a table's whole DDL — the `create table`
and every `alter table … add` — belongs to the single `schema.sql` that owns the table. Put an
`alter` in another folder's `schema.sql` and it may run *before* the `create`; the guard sees no
column, fires the `alter`, SQL Server rejects it as an unknown object, and the apply stops there
with the rest of the bundle unapplied.

## Schema evolution — no separate migrations

There is **no** `migrations.sql`, no version table, no migration runner. Because every script is idempotent and re-runs on each deploy, the schema files *are* the migration: a `schema.sql` is an **idempotent recipe** that brings any DB (empty or old) to the current shape, not a one-time snapshot. The canonical current shape lives in the DB — read it with the `a2` CLI, not from the file.

The schema grows **additively only**:

- **New column** — append a guarded `alter table ... add` block to the `schema.sql` that owns the table. The `CREATE TABLE` (guarded) runs first in the same file, the `ALTER` after it; on an existing DB the `CREATE` is skipped and only the `ALTER` fires.
- **New FK** — two files: the column goes in `schema.sql`, the `foreign key` constraint goes in `keys.sql` (always present, even if empty, so all tables exist before any FK is created).
- **Rename / drop / type-narrow** — the skill does **not** do these (tracking them idempotently is not worth it). To rename, *add the new column, leave the old one untouched*, and tell the user: "added X; if you want, migrate the data from the old column and drop it manually." Same for removals — a human does them deliberately.
