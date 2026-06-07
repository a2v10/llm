# SQL ↔ runtime rules — markers & bindings

The **platform contract**: how a stored procedure's output binds to the client model.
This is not stylistic — break a marker and the runtime mis-binds, duplicates, or drops
data. The names *inside* a marker are arbitrary to the engine; the **role token**
(`!Id`, `!Array`, `!ParentId`, …) is what it acts on — `[xxx!Id]` means "this is the
identifier" no matter what `xxx` is or what column sits under it.

Siblings: concrete column/proc names a project chose → `semantic.md`; SQL-authoring
hygiene (idempotency, constraint/table naming) → `sql-discipline.md`; slot-fill proc
templates → `sql-procedures.md`.

## Marker shape

A marker is `[<name>!<type>!<role>]`.

- **`<type>`** — the entity type token, written `T<Entity>` (`TSample`, `TAgent`). The
  `T`+singular spelling is a naming convention → `sql-discipline.md`; the engine only
  needs the token to be consistent across the markers that describe one entity.
- The **collection name** (the leading part of an Array marker, e.g. `Samples` in
  `[Samples!TSample!Array]`) is referenced from templates — e.g. `persistSelect: ["Samples"]`.
  See [template.md](template.md).

## Two kinds of marker

Markers split on **what they describe**:

- **Recordset markers** — the *shape* of a whole result set.
- **Column markers** — the *role* of a single column inside a result set.

### Rule: recordset marker sits in the first field, value `null`

A recordset marker is always the **first field** of the SELECT, and its value is
**`null`** (`[Samples!TSample!Array] = null`). The `= null` is not cosmetic — it is how
the engine recognises the field as the recordset descriptor rather than data.

### Recordset markers

| Marker        | Purpose                                                    |
|---------------|------------------------------------------------------------|
| `!Object`     | Single object                                              |
| `!Array`      | Collection (rows)                                          |
| `!Map`        | Lookup map, resolved by `Id`                               |
| `!Tree`       | Hierarchical result (static via recursive CTE + `!ParentId`, or dynamic with an `.Expand` proc). → [sql/tree.md](https://docs-llm.a2v10.com/sql/tree.md) |
| `!Group`      | Grouped/subtotal hierarchy from `GROUP BY ROLLUP` (not explicit parent ids). Rows sorted so subtotals precede details; nests via `!Items`. → [sql/grouping.md](https://docs-llm.a2v10.com/sql/grouping.md) |
| `!MapObject`  | Like `!Map`, but keyed by a `!Key` value (a set of named keys) instead of `Id`: each distinct key becomes a named property on the parent object. Placeholder lists the expected keys — `[Logins!TLogin!MapObject!ApiKey:Basic]`. |
| `!CrossArray` | Pivot/cross-tab: a horizontal array whose columns emerge from data values (like SQL `PIVOT`, but columns need not be known ahead). Element order from `!Key`. → [sql/cross.md](https://docs-llm.a2v10.com/sql/cross.md) |
| `!CrossObject`| Like `!CrossArray` but an object keyed by value instead of an array. → [sql/cross.md](https://docs-llm.a2v10.com/sql/cross.md) |

### Recordset marker as a column → child recordset

The same shape markers may appear **as a column marker** inside a parent recordset.
There they are a **placeholder**: the next result set is the child that fills the slot,
and that child carries `[!<Parent>.<Field>!ParentId]` to bind its rows back to the
parent. (Concrete parent-child invariants → [mapping.md](mapping.md) §2, Pair 6.)

- No placeholder → child rows land on the model root instead of inside the parent.
- No `!ParentId` in the child → rows are not bound to the parent.

### Column markers

| Marker         | Purpose                                                          |
|----------------|------------------------------------------------------------------|
| `!Id`          | Primary key / identity of the row                                |
| `!Key`         | Per-row key in `!MapObject`/`!Cross*` sets (`!!` form). MapObject: becomes the parent property name. Cross: orders elements, exposed via `$cross`. |
| `!Name`        | Display name field                                               |
| `!UtcDate`     | Convert the column UTC→local on model load. Uses the **server's** local time, not the client's. |
| `!RefId`       | FK reference to another entity (paired with a `!Map`)            |
| `!ParentId`    | Binds a child row to its parent (`[!<Parent>.<Field>!ParentId]`) |
| `!RowCount`    | Total row count for paging                                       |
| `!RowNumber`   | Ordinal number of the row                                        |
| `!HasChildren` | Tree node has children → UI shows the expand arrow. Computed in SQL (`case when exists(...) then 1 else 0 end`); `!!` form, no type token. |
| `!Items`       | Nested-children placeholder column in `!Tree`/`!Group` results; always `= null`. |
| `!Expanded`    | Tree node renders pre-expanded in the UI. Static trees only — no effect on dynamic (`.Expand`) trees. |
| `!Permissions` | Int bitmask of row access rights — `cast(CanView as int) + cast(CanEdit as int)*2 + cast(CanDelete as int)*4 + cast(CanApply as int)*8` (same bits as [model-json.md](model-json.md#permissions)). |
| `!GroupMarker` | In a `!Group` set: holds `grouping(col)` (0=detail, 1=subtotal) for one `ROLLUP` column; one per rolled-up column, ordered `desc`. `!!` form. |
| `!ReadOnly`    | In `$System` only, `[!!ReadOnly] = 0/1`: when 1, the platform disables every UI control and blocks saving the model. |
| `!SortOrder`   | Echo of the active sort column (in `$System`)                    |
| `!SortDir`     | Echo of the active sort direction (in `$System`)                 |
| `!PageSize`    | Echo of the page size (in `$System`)                             |
| `!Offset`      | Echo of the paging offset (in `$System`)                         |
| `!Filter`      | Echo of a filter parameter back to the form (in `$System`)       |
| `!Json`        | Text column holding valid JSON; deserialized into an object in the model (not a string). **The object is NOT reactive.** |

## `$System` — special recordset

`[!$System!]` (name mid-marker, not a suffix) — echoes paging/sort/filter state back so the form keeps it on refresh. Holds `!PageSize`, `!Offset`, `!SortOrder`, `!SortDir`, `!Filter`, `!RowCount`, plus `!ReadOnly` (control flag, not echo).

## `Metadata` — the `.Metadata` proc

`[<param>!<modelPath>!Metadata]` — `.Metadata` declares the model shape before `.Update` (one empty result set per TVP). Full → [sql/update-model.md](https://docs-llm.a2v10.com/sql/update-model.md).

## Cross-layer bindings — the «правила зв'язок»

The expanded cross-layer invariants (TVP column = client property; sort/filter pairs;
FK projection; parent-child Array; TableType ⇔ MERGE) live in [mapping.md](mapping.md)
§2 as named pairs, each with its failure mode. Use them as a post-generation
sanity-check.

---
> Full documentation: [sql.md](https://docs-llm.a2v10.com/sql.md)
