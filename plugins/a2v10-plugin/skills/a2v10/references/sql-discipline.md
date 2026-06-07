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
| `CREATE TABLE`   | `INFORMATION_SCHEMA.TABLES`                                            |
| `ADD COLUMN`     | `COL_LENGTH('<schema>.<Table>', '<Column>') is null`                   |
| `ADD CONSTRAINT` | `sys.objects WHERE type IN ('F','C','UQ','D')`                         |
| `CREATE INDEX`   | `sys.indexes`                                                          |
| `CREATE SEQUENCE`| `INFORMATION_SCHEMA.SEQUENCES`                                         |

```sql
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES
    where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Samples')
    create sequence cat.SQ_Samples as bigint start with 100 increment by 1;
go

if not exists(select * from INFORMATION_SCHEMA.TABLES
    where TABLE_SCHEMA = N'cat' and TABLE_NAME = N'Samples')
create table cat.[Samples] ( ... );
go
```

`TableType` and dependent procedures are recreated via `drop ... if exists` + `create`:

```sql
drop procedure if exists cat.[Sample.Metadata];
drop procedure if exists cat.[Sample.Update];
drop type      if exists cat.[Sample.TableType];
go
```
