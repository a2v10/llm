# Migrations

## A single `migrations.sql` file

All DDL changes live in one file at the project root, in versioned blocks:

```sql
-- version 1->2
if not exists(select * from INFORMATION_SCHEMA.COLUMNS
              where TABLE_SCHEMA='cat' and TABLE_NAME='Customers' and COLUMN_NAME='Email')
    alter table cat.Customers add Email nvarchar(255);
go

-- version 2->3
exec sp_rename 'cat.Customers.Memo', 'Notes', 'COLUMN';
go

-- version 3->4 (pending)
alter table ...
```

## Two-level idempotency

1. **Version in `__a2v10_migrations`** (a table in the DB) — "this block has already been applied".
2. **Each statement is idempotent** — guarded via `INFORMATION_SCHEMA` / `sys.*`.

Catalog of guard templates:

| DDL | Guard |
|---|---|
| `CREATE TABLE` | `INFORMATION_SCHEMA.TABLES` |
| `ADD COLUMN` | `INFORMATION_SCHEMA.COLUMNS` |
| `ADD CONSTRAINT` | `sys.objects WHERE type IN ('F','C','UQ')` |
| `CREATE INDEX` | `sys.indexes` |
| `CREATE SEQUENCE` | `INFORMATION_SCHEMA.SEQUENCES` |
| `ALTER COLUMN` type | separately: `DATA_TYPE` / `MAX_LENGTH` |

## Renaming fields

A rename is `sp_rename`, **not** `DROP + ADD` (otherwise data is lost):

```sql
exec sp_rename 'cat.Customers.Memo', 'Notes', 'COLUMN';
go
```

## Destructive operations

`DROP COLUMN`, `DROP TABLE`, type narrowing — are generated **commented out**:

```sql
-- DESTRUCTIVE: review before applying
-- alter table cat.Customers drop column Notes;
```

A human explicitly uncomments after review.

## Data migrations

The generator emits DDL only. If a data move is needed — add a section manually:

```sql
-- == DDL (generated) ==
alter table cat.Customers add Email nvarchar(255);
go

-- == DATA (manual) ==
update cat.Customers
set Email = lower([Name]) + '@example.com'
where Email is null;
go
```

Idempotency of the DATA section is the developer's responsibility (`where Email is null` stops triggering after the first roll-out).
