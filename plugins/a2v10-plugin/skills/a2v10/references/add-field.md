# How to add a field to an existing entity

Step-by-step checklist for a focused change to a single endpoint.

> For semantic-type → artifacts projection (which control / TableType / d.ts to use per column type) see [mapping.md](mapping.md). The per-type sections below are concrete examples of that projection.

## Layers — what to change and where

| Layer | File | What exactly |
|---|---|---|
| Schema | `schema.sql` (owns the table) | additive DDL — `alter table ... add` (guarded) |
| FK constraint | `keys.sql` | `foreign key` constraint — ref fields only |
| SQL | `<endpoint>.sql` | `TableType`, `Load`, `Index`, `Update` / `Metadata` |
| XAML edit | `edit.dialog.xaml` / `edit.view.xaml` | Field on the form |
| XAML index | `index.view.xaml` | Column in DataGrid; filter (if filtered) |
| XAML browse | `browse.dialog.xaml` | Column (only for identifying fields) |
| Types | `edit.d.ts` | Field in the corresponding type *(if the file exists — update it; if not — do not create it)* |
| Validator | `edit.template.ts` | If the field is required or has a rule |
| Localization | `_localization/*.txt` | Field/column label |

Not every layer is required — depends on the field type.

> XAML files above are named `.xaml` for brevity; on disk they carry the project's `XAML naming convention` extension (`.vxaml` or `.xaml`, CLAUDE.md). When locating a file to edit, match the base name (`edit.view.*`) — don't assume the extension.

## Field types

### Primitive (nvarchar / int / money / date / bit)

```sql
-- schema.sql (the file that owns cat.Banks)
if not exists(select * from INFORMATION_SCHEMA.COLUMNS
    where TABLE_SCHEMA='cat' and TABLE_NAME='Banks' and COLUMN_NAME='Foo')
    alter table cat.Banks add Foo nvarchar(255);
go
```

SQL — add `Foo` to `TableType`, the `Load` SELECT, the `Index` SELECT, and the `Update` MERGE.

XAML edit: `<TextBox Label="@[Foo]" Value="{Bind Bank.Foo}"/>`

d.ts: add `Foo: string` (or `number`) to the type.

### FK reference (ref)

```sql
-- schema.sql (the file that owns cat.Banks) — column only
if not exists(select * from INFORMATION_SCHEMA.COLUMNS
    where TABLE_SCHEMA='cat' and TABLE_NAME='Banks' and COLUMN_NAME='Country')
    alter table cat.Banks add Country bigint;
go

-- keys.sql — FK constraint (runs after all tables exist)
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS
    where CONSTRAINT_NAME='FK_Banks_Country_Countries')
    alter table cat.Banks add
        constraint FK_Banks_Country_Countries foreign key (Country) references cat.Countries(Id);
go
```

SQL — `TableType`: add `Country bigint`.

`Load` SELECT + Map:
```sql
[Country!TCountry!RefId] = b.Country
-- a separate result set after the main one:
select [!TCountry!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
from cat.Countries c where c.Id = (select Country from cat.Banks where Id = @Id);
```

`Index` — add `Country bigint` to the temp table; in SELECT `[Country!TCountry!RefId] = b.Country`; Map via the temp table:
```sql
select [!TCountry!Map] = null, [Id!!Id] = c.Id, [Name!!Name] = c.[Name]
from cat.Countries c where c.Id in (select Country from @banks where Country is not null);
```

`Update` MERGE — add `Country` to `SET` and `INSERT`.

XAML edit:
```xml
<SelectorSimple Label="@[Country]" Value="{Bind Bank.Country}" Url="/catalog/country"/>
```

XAML index (if a column is needed):
```xml
<DataGridColumn Content="{Bind Country.Name}" Header="@[Country]"/>
```

d.ts:
```ts
Country: TRefItem   // { Id: number, Name: string }
```

### Enum / status (char + CHECK)

```sql
if not exists(select * from INFORMATION_SCHEMA.COLUMNS
    where TABLE_SCHEMA='cat' and TABLE_NAME='Banks' and COLUMN_NAME='Status')
    alter table cat.Banks add [Status] char(1) not null
        constraint DF_Banks_Status  default 'A'
        constraint CK_Banks_Status  check([Status] in ('A', 'I'));
go
```

XAML edit: `<ComboBox>` with static `<ComboBoxItem>` entries.

d.ts: `Status: string`.

### Boolean (bit)

```sql
if not exists(select * from INFORMATION_SCHEMA.COLUMNS
    where TABLE_SCHEMA='cat' and TABLE_NAME='Banks' and COLUMN_NAME='IsActive')
    alter table cat.Banks add IsActive bit not null constraint DF_Banks_IsActive default 1;
go
```

XAML edit: `<CheckBox Label="@[IsActive]" Value="{Bind Bank.IsActive}"/>`.

XAML DataGrid: `Role="CheckBox"` (**not** `DataType="CheckBox"`).

d.ts: `IsActive: boolean`.

## "Don't forget" checklist

- [ ] DDL is idempotent and additive: `if not exists(... INFORMATION_SCHEMA.COLUMNS ...)` guards the `add`; no `N''` in guards; never rename/drop (add new, tell the user).
- [ ] FK field: column in `schema.sql`, `foreign key` constraint in `keys.sql`.
- [ ] Multi-tenant: a new column in a table without `TenantId` (it is already in the table); but in a new procedure — `@TenantId` in parameters, WHERE, and MERGE INSERT.
- [ ] `TableType` updated.
- [ ] `Update` MERGE: field in `SET` **and** in `INSERT`.
- [ ] `Index`: field in SELECT + Map (for FK) + temp table (for FK) + parameter + `$System` (if filtered).
- [ ] `edit.d.ts`: if the file exists — update the type. If not — do not create it.
- [ ] `TabIndex="1"` — only on the first field of the form; do not set it on the rest.
