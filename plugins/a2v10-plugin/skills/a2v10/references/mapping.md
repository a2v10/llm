# Mapping — semantic types and cross-layer pairs

Two reference tables in one document. Use **Section 1** as the projection lookup when generating an endpoint from a SQL schema; use **Section 2** as a sanity-check after generation.

---

## Section 1: Semantic types

Each DB column has a **semantic type** on top of its SQL type. The semantic type is what determines projection into TableType, d.ts, the XAML edit control, and the DataGrid column.

Input: `(SQL type, context: PK / FK / CHECK / nullable)`.
Output: full row of artifacts.

| Semantic | SQL pattern | TableType | d.ts | XAML edit control | DataGrid Role + extras |
|---|---|---|---|---|---|
| **Id (surrogate PK)** | `bigint not null` + sequence | `bigint null` | `number` | (not shown) | `Role="Id"` |
| **Name** | `nvarchar(255-500)` | same | `string` | `<TextBox>` | (default) `LineClamp="2"` |
| **Memo / free text** | `nvarchar(255)` or `nvarchar(max)` | same | `string` | `<TextBox>` (single line) or `<TextArea>` for max | `LineClamp="2"` or `Fit="True" Wrap="NoWrap"` |
| **Code / phone** | `nvarchar(50-100)` | same | `string` | `<TextBox>` | (default) |
| **Money** | `money` or `decimal(10,4)` | same | `number` | `<TextBox DataType="Currency">` | `Role="Number"` + `{BindSum col}` |
| **Quantity** | `decimal(18,4)` | same | `number` | `<TextBox DataType="Number">` | `Role="Number"` |
| **Rate / VAT** | `decimal(6,4)` | same | `number` | `<TextBox DataType="Number">` | `Role="Number"` |
| **Date** | `date` | `date` | `Date` | `<DatePicker>` | `DataType="Date"` `Role="Date"` |
| **DateTime** | `datetime2` | `datetime2` | `Date` | `<DatePicker>` | `DataType="DateTime"` `Role="Date"` |
| **Boolean** | `bit not null default 0` | `bit` | `boolean` | `<CheckBox>` | `Role="CheckBox"` *(not `DataType="CheckBox"`)* |
| **Enum** | `char(N) + CHECK in (...)` | same | `string` | `<ComboBox>` with static `<ComboBoxItem>` | (default) |
| **FK reference** | `bigint null` + FK constraint | `bigint` | `TRefItem` (`{Id, Name}`) | `<SelectorSimple Url="/<kind>/<endpoint>">` | `{Bind <col>.Name}` `LineClamp="2"` |
| **System flags** (`Void`, `IsSystem`) | `bit not null default 0` | `bit` | `boolean` | (usually hidden) | (usually hidden) |

**Notes:**
- `Money` with `decimal(10,4)` keeps 4 fractional digits for intermediate math; round on display. `money` is legacy — prefer `decimal` in new tables.
- FK URL is derived from the target schema: `cat → /catalog/<endpoint>`, `doc → /document/<endpoint>`, `jrn → /journal/<endpoint>`. If the target endpoint does not yet exist in the project, flag and decide before linking.
- `Name`, `Memo` are not really semantics — they're standard column names (see `semantic.md → Standard columns`). Listed here for projection completeness.

---

## Section 2: Cross-layer pairs

Each pair is an invariant that must hold across layers. If broken, the endpoint is inconsistent. Each pair includes a **failure mode** for diagnosis.

### Pair 1 — sortable column

**SQL** `case @Order when N'col' then ... end` ⇔ **XAML** `<DataGridColumn Sort="True"/>`

If the procedure has a branch for `'col'` — the matching column needs `Sort="True"` (assuming `<DataGrid Sort="False">` globally). And vice versa.

*Failure:* user clicks the column header → request goes out with `@Order='col'` → procedure silently ignores it → result is unsorted. Silent bug.

### Pair 2 — filter parameter

**SQL** filter param (e.g. `@Status nvarchar(32)`) ⇔ **XAML** `<FilterItem Property="Status" DataType="String"/>` + UI control bound to `Parent.Filter.Status`.

Every non-paging procedure parameter that affects WHERE must have a `<FilterItem>` and a UI control.

*Failure:* the form has the filter but the value never reaches the procedure (or the procedure parameter stays at its default).

### Pair 3 — text search

**SQL** `@Fragment nvarchar(255)` ⇔ **XAML** `<SearchBox Value="{Bind Parent.Filter.Fragment}"/>` + `<FilterItem Property="Fragment" DataType="String"/>`

A triad: procedure parameter, FilterItem, SearchBox.

*Failure:* search box shows but does nothing; or the parameter exists with no UI.

### Pair 4 — Period range

**SQL** `@From + @To` pair ⇔ **XAML** `<PeriodPicker Value="{Bind Parent.Filter.Period}"/>` + `<FilterItem Property="Period" DataType="Period"/>`

`DataType="Period"` is the platform marker that maps to a `@From/@To` parameter pair.

*Failure:* period picker shown, request not filtered.

### Pair 5 — FK reference projection

Five synchronized points for each FK column:

1. **SQL** main SELECT: `[<col>!T<Ref>!RefId] = e.<col>`
2. **SQL** separate Map result set: `[!T<Ref>!Map] = null, [Id!!Id], [Name!!Name]`
3. **d.ts**: `<col>: TRefItem`
4. **XAML edit**: `<SelectorSimple Url="/<kind>/<ref-endpoint>">`
5. **XAML index**: `{Bind <col>.Name}`

*Failure:* "I see 12345 instead of the agent's name" (missing Map). Or "the agent doesn't save — the field is empty" (missing TableType column / MERGE column / RefId marker).

### Pair 6 — parent-child Array

**SQL** Object SELECT contains placeholder `[<Field>!T<Child>!Array] = null` ⇔ **next result set** is unnamed `[!T<Child>!Array] = null` with `[!T<Parent>.<Field>!ParentId] = c.<fk>`.

- No placeholder → rows land on the model root.
- No `ParentId` → rows are not bound to the parent.
- Named filler (`[Rows!TRow!Array]`) → rows duplicated into both `Object.Rows` and a root-level `Rows`.

*Failure:* detail table missing / shown twice / shown but not refreshed after header save.

### Pair 7 — TableType ⇔ MERGE columns

**TableType** column list ⇔ **MERGE INSERT** column list ⇔ **MERGE SET** clause.

All three must agree (minus identity / default-only fields excluded by design).

*Failure:* a field silently fails to save on insert or update.

### Pair 8 — date column type

**SQL** `date` ⇔ **XAML** `DataType="Date"` | **SQL** `datetime2` ⇔ **XAML** `DataType="DateTime"`.

*Failure:* `date` + `DataType="DateTime"` shows zero time and confuses users about UTC.

### Pair 9 — localization key

**XAML** `@[<Key>]` ⇔ **`_localization/_default.uk.txt`** entry `@<Key>=<text>`.

*Failure:* form displays the raw key (`@Foo`) instead of the localized text.

### Pair 10 — filter echo in `$System`

**SQL** `[!<Entities>.<Field>!Filter] = @<Field>` in the `$System` result set ⇔ **XAML** `FilterItem` reading the same name back.

*Failure:* on refresh, the form drops the user's filter values.

---

## Usage

- **At generation time:** for each column → Section 1 → emit the projection across SQL + d.ts + XAML edit + XAML index.
- **As a sanity-check after generation:** walk Section 2; for each layer that has the left side, verify the right side exists, and vice versa.
