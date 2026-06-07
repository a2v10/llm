# SQL Procedures — slot-filling templates

Each procedure is a fixed sequence of slots. Fill each slot from the endpoint specification; skip a slot only when explicitly marked optional.

## Common rules

- Naming: `<schema>.[<Model>.<Action>]` — e.g. `cat.[Sample.Index]`.
- Always `create or alter procedure`.
- Multi-tenant param order: `@TenantId int = 1` first (default), then `@UserId bigint`. Single-tenant — drop `@TenantId` everywhere.
- Standard prolog:
  ```sql
  set nocount on;
  set transaction isolation level read uncommitted;
  -- Update/Delete: read committed
  ```

For semantic-type → SQL/TableType mapping see [mapping.md](mapping.md). For cross-layer invariants (sort/filter/FK pairs) — same file.

## TenantId — multi-tenant plumbing

`TenantId` is a **project-level decision** (recorded in `semantic.md` / CLAUDE.md): it is
either present in every table and procedure, or absent entirely. Pick once at project start
(check any existing table or procedure of the project). When multi-tenant, every procedure
below carries this plumbing:

- Signature: `@TenantId int = 1` always **first**, before `@UserId`.
- WHERE in every query: `where TenantId = @TenantId and ...`
- MERGE ON: `on (t.TenantId = @TenantId and t.Id = s.Id)`
- INSERT: `(TenantId, [Name], ...) values (@TenantId, s.[Name], ...)`
- **TableType — without `TenantId`.** It is external, passed as a procedure parameter, not by client data.

When single-tenant — `TenantId` is absent from tables, parameters, and WHERE clauses; drop it everywhere in the templates.

---

## Index — paginated list

### Parameters (fixed order)

1. `@TenantId int = 1` *(multi-tenant only)*
2. `@UserId bigint`
3. `@Id <pk_type> = null` *(scope id like MarketplaceId; optional)*
4. `@Offset int = 0`
5. `@PageSize int = 20`
6. `@Order nvarchar(32) = N'<default>'`
7. `@Dir nvarchar(5) = N'asc'`
8. `@From datetime = null`, `@To datetime = null` *(if date-range filter)*
9. `@Fragment nvarchar(255) = null` *(if text search)*
10. Other filters: `@Status nvarchar(32) = N'all'`, `@Category bigint = null`, … *(add only what's used)*

### Slots

**Slot 1 — normalize.**
```sql
set @Order = lower(@Order);
set @Dir   = lower(@Dir);
-- + lower() on every nvarchar enum-style filter
```

**Slot 2 — date-range bounds.** *(only if `@From`/`@To`)*
```sql
set @From = isnull(@From, cast(getutcdate() as date));
set @To   = isnull(@To, @From);
declare @start datetime = @From;
declare @end   datetime = dateadd(day, 1, @To);
```
Half-open range (`< @end`) is safe for both `date` and `datetime2`. Inclusive `<= @To` loses records with non-zero time on `datetime2`.

**Slot 3 — fragment LIKE.** *(only if `@Fragment`)*
```sql
declare @fr nvarchar(255) = N'%' + @Fragment + N'%';
```

**Slot 4 — temp table.**
```sql
declare @<entities> table (
    <pk>     <pk_type>,
    rowno    int identity(1,1),
    rowcnt   int
    -- + every FK column that feeds a Map (slot 8)
);
```
Decision: include FK columns if the result set in slot 7 has a `RefId` marker for them.

**Slot 5 — INSERT with filters.**
```sql
insert into @<entities>(<pk>, rowcnt /*, fk_cols*/)
select <pk>, count(*) over() /*, fk_cols*/
from <schema>.<table>
where Void = 0
    -- multi-tenant:   and TenantId = @TenantId
    -- scope:          and MarketplaceId = @Id
    -- date range:     and [Date] >= @start and [Date] < @end
    -- fragment:       and ([Name] like @fr or [Memo] like @fr)
    -- enum filter:    and (@Status = N'all' or [Status] = @Status)
order by /* slot 6 */
offset @Offset rows fetch next @PageSize rows only
option(recompile);
```

**Slot 6 — ORDER BY.**
One `asc/desc` pair per **type group** (SQL Server forbids mixing types inside one CASE — Operand type clash):
```sql
order by
    -- nvarchar group
    case when @Dir = N'asc'  then case @Order when N'name' then [Name] when N'memo' then [Memo] end end asc,
    case when @Dir = N'desc' then case @Order when N'name' then [Name] when N'memo' then [Memo] end end desc,
    -- date group
    case when @Dir = N'asc'  then case @Order when N'date' then [Date] end end asc,
    case when @Dir = N'desc' then case @Order when N'date' then [Date] end end desc,
    -- bigint group
    case when @Dir = N'asc'  then case @Order when N'id' then <pk> end end asc,
    case when @Dir = N'desc' then case @Order when N'id' then <pk> end end desc,
    <pk>  -- deterministic fallback
```

**Slot 7 — result set 1 (data).**
```sql
select [<Entities>!T<Entity>!Array] = null,
    [<pk>!!Id]   = e.<pk>,
    [Name!!Name] = e.[Name],
    [!!RowCount] = t.rowcnt,
    -- business columns
    e.[Memo],
    -- FK refs:
    [<ref>!T<Ref>!RefId] = e.<fk_col>
from <schema>.<table> e
    inner join @<entities> t on e.<pk> = t.<pk>
    -- multi-tenant: and e.TenantId = @TenantId
order by t.rowno;
```

**Slot 8 — result set 2 (Map for FK).** *(only if slot 7 has RefId markers)*

Decision:
- 1 FK column → join temp table directly.
- ≥2 FK columns to the **same** ref table → TCU/TU CTE with `union all`.
- FK columns to **different** ref tables → separate Map per ref table.

Single FK:
```sql
select [!T<Ref>!Map] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name]
from <schema>.<refs> r
where r.Id in (select <fk_col> from @<entities> where <fk_col> is not null);
```

Multi-FK to the same ref:
```sql
;with TCU as (
    select ref_id = <fk1> from @<entities> where <fk1> is not null
    union all
    select ref_id = <fk2> from @<entities> where <fk2> is not null
),
TU as (select ref_id from TCU group by ref_id)
select [!T<Ref>!Map] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name]
from <schema>.<refs> r
    inner join TU on r.Id = TU.ref_id;
```

**Slot 9 — result set 3 (`$System`).**
```sql
select [!$System!] = null,
    [!<Entities>!Offset]               = @Offset,
    [!<Entities>!PageSize]             = @PageSize,
    [!<Entities>!SortOrder]            = @Order,
    [!<Entities>!SortDir]              = @Dir
    -- echo each filter; Period uses two keys, not a nested object:
    , [!<Entities>.Period.From!Filter] = @From
    , [!<Entities>.Period.To!Filter]   = @To
    , [!<Entities>.Fragment!Filter]    = @Fragment
    , [!<Entities>.Status!Filter]      = @Status;
```

---

## Load — single object by Id

### Parameters
- `@TenantId int = 1` *(multi-tenant only)*
- `@UserId bigint`
- `@Id <pk_type>`

### Slots

**Slot 1 — result set 1 (Object).**
```sql
select [<Entity>!T<Entity>!Object] = null,
    [<pk>!!Id]   = e.<pk>,
    [Name!!Name] = e.[Name],
    e.[Memo],
    -- business fields
    [<ref>!T<Ref>!RefId] = e.<fk_col>,
    -- placeholder for child arrays:
    [Rows!TRow!Array] = null
from <schema>.<table> e
where e.<pk> = @Id
    -- multi-tenant: and e.TenantId = @TenantId
;
```

**Slot 2 — Map(s).** *(one per FK reference)*
```sql
select [!T<Ref>!Map] = null, [Id!!Id] = r.Id, [Name!!Name] = r.[Name]
from <schema>.<refs> r
where r.Id = (select <fk_col> from <schema>.<table> where <pk> = @Id);
```

**Slot 3 — child arrays.** *(if detail rows exist)*
```sql
select [!TRow!Array] = null,             -- NO name on the placeholder filler!
    [Id!!Id] = r.Id,
    r.Qty, r.Price,
    [!T<Entity>.Rows!ParentId] = r.<parent_fk>
from <schema>.<details> r
where r.<parent_fk> = @Id
order by r.RowNo;
```

Decision: leave the second result set **unnamed**. Naming it (`[Rows!TRow!Array]`) duplicates rows into `Object.Rows` **and** the model root.

---

## Update — MERGE + Load

### Parameters
- `@TenantId int = 1` *(multi-tenant only)*
- `@UserId bigint`
- `@<Entity> <schema>.[<Entity>.TableType] readonly`
- `@<Entity>.Rows <schema>.[<Entity>.Row.TableType] readonly` *(if detail rows)*

### Slots

**Slot 1 — isolation level.**
```sql
set transaction isolation level read committed;
```

**Slot 2 — capture id for Load.**
```sql
declare @id <pk_type>;
declare @rtable table(id <pk_type>);
```

**Slot 3 — header MERGE.**

Single-header (typical edit dialog):
```sql
merge <schema>.<table> as t
using @<Entity> as s on t.<pk> = s.<pk>
    -- multi-tenant: and t.TenantId = @TenantId
when matched then update set
    t.[Name] = s.[Name], t.[Memo] = s.[Memo] /* + business fields */
when not matched by target then insert
    (<pk>, [Name], [Memo] /* + fields; multi-tenant adds TenantId */)
    values (s.<pk>, s.[Name], s.[Memo])
output inserted.<pk> into @rtable(id);

select @id = id from @rtable;
```

**Slot 4 — child rows MERGE.** *(if detail rows)*
```sql
merge <schema>.<details> as t
using @<Entity>.Rows as s on t.Id = s.Id and t.<parent_fk> = @id
when matched then update set
    t.Qty = s.Qty, t.Price = s.Price /* ... */
when not matched by target then insert
    (<parent_fk>, RowNo, Qty, Price)
    values (@id, s.RowNo, s.Qty, s.Price)
when not matched by source and t.<parent_fk> = @id then delete;
```

**Slot 5 — return current state.**
```sql
exec <schema>.[<Entity>.Load]
    @TenantId = @TenantId,  -- multi-tenant only
    @UserId   = @UserId,
    @Id       = @id;
```

### FK columns in the TableType — RefId naming

When a field is exposed in `Load` via `!RefId` (e.g. `[Agent!TAgent!RefId] = e.AgentId`), the client receives an **object** named without the `Id` suffix (`Agent`, not `AgentId`). The runtime maps that object's `Id` to the TVP column **by property-name equality**, so the TVP column must match the client property name:

| Table column | Load marker | Client property | TVP column |
|---|---|---|---|
| `AgentId bigint` | `[Agent!TAgent!RefId]` | `Agent` (object) | `Agent bigint` |
| `WarehouseId bigint` | `[Warehouse!TWarehouse!RefId]` | `Warehouse` (object) | `Warehouse bigint` |

```sql
create type <schema>.[<Entity>.TableType] as table(
    Id     <pk_type>,
    [Name] nvarchar(255),
    Agent  bigint,        -- TVP column = client property (no Id suffix)
    ...
);
```

In `MERGE`, map the TVP column explicitly to the table column:
```sql
when matched then update set
    t.AgentId = s.Agent,            -- TVP "Agent" → table "AgentId"
    t.WarehouseId = s.Warehouse
```

> Rule: **TVP column name = client property name** (no `Id` suffix for RefId references); the `…Id` lives only on the physical table column.

### Variant: bulk parents + children via GUID/ParentGUID

Use **only** when one `Update` call inserts >1 parent records, or three+ levels of nesting where the middle level is both parent and child. For the typical edit dialog (one header + its rows) — use the slots above.

TableTypes carry synthetic keys:
```sql
create type <schema>.[<Entity>.TableType] as table(
    [GUID] uniqueidentifier,
    Id     <pk_type>,
    /* fields */
);

create type <schema>.[<Entity>.Row.TableType] as table(
    ParentGUID uniqueidentifier,
    Id         <pk_type>,
    /* fields */
);
```

Header MERGE writes `(new id, GUID)` pairs:
```sql
declare @rtable table(id <pk_type>, [guid] uniqueidentifier);

merge <schema>.<table> as t
using @<Entity> as s on t.Id = s.Id
when matched then update set ...
when not matched by target then insert (...) values (...)
output inserted.Id, s.[GUID] into @rtable(id, [guid]);
```

Children join `@rtable` by GUID:
```sql
with T as (
    select r.*, [Parent] = t.id
    from @<Entity>.Rows r
        inner join @rtable t on t.[guid] = r.ParentGUID
)
merge <schema>.<details> as t
using T as s on t.Id = s.Id and t.[Parent] = s.[Parent]
when matched then update set ...
when not matched by target then insert (...) values (...)
when not matched by source and t.[Parent] in (select id from @rtable) then delete;
```

`scope_identity()` returns only the last id and is incorrect for bulk; `output ... into` is the only correct pattern.

---

## Metadata — empty TableType

### Parameters
- `@TenantId int = 1` *(multi-tenant only)*
- `@UserId bigint`

```sql
declare @<Entity> <schema>.[<Entity>.TableType];
select [<Entity>!<Entity>!Metadata] = null, * from @<Entity>;
```

Marker syntax: `[<paramName>!<modelPath>!Metadata]`.
- **First part** — the `Update` parameter name (without `@`).
- **Second part** — the **path in the client model** (dotted), *not* the type name.

One metadata result set **per TVP parameter** of `Update` (excluding `@UserId` / `@TenantId`). For a header + rows the procedure declares and emits both:

```sql
declare @<Entity>      <schema>.[<Entity>.TableType];
declare @<Entity>.Rows <schema>.[<Entity>.Row.TableType];

-- header: param @<Entity>, model path <Entity>
select [<Entity>!<Entity>!Metadata] = null, * from @<Entity>;
-- rows: param @Rows, model path <Entity>.Rows  ← path, not the type name
select [Rows!<Entity>.Rows!Metadata] = null, * from @<Entity>.Rows;
```

> ⚠️ The second element is the model path (`Invoice.Rows`), **not** the TVP type (`InvoiceRow`).

---

## Fetch — quick search for browse dialog

### Parameters
- `@TenantId int = 1` *(multi-tenant only)*
- `@UserId bigint`
- `@Text nvarchar(255) = null`

```sql
declare @fr nvarchar(255) = N'%' + @Text + N'%';

select top(100) [<Entities>!T<Entity>!Array] = null,
    [Id!!Id]     = e.Id,
    [Name!!Name] = e.[Name],
    -- + identifying fields only (phone / email / code)
    e.<phone>, e.<email>
from <schema>.<table> e
where e.Void = 0
    -- multi-tenant: and e.TenantId = @TenantId
    and (@Text is null or [Name] like @fr or <phone> like @fr or <email> like @fr)
order by e.[Name];
```

Decision: the column list **must match** `browse.dialog.xaml`. Identifying fields only (Name + phone/email/code/SKU). Do not include descriptive fields like `Address` or `Memo`.

---

## Delete — soft delete

```sql
update <schema>.<table>
set Void = 1
where <pk> = @Id
    -- multi-tenant: and TenantId = @TenantId
;
```

Hard delete (`delete from ...`) — only by explicit archetype choice with documented reason.
