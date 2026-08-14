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
| `!Object`     | Single object. → [sql/object.md](https://docs-llm.a2v10.com/sql/object.md) |
| `!Array`      | Collection (rows)                                          |
| `!Map`        | Lookup map, resolved by `Id`. Exists only to serve `!RefId`. → [sql/object.md](https://docs-llm.a2v10.com/sql/object.md) |
| `!Tree`       | Hierarchical result (static via recursive CTE + `!ParentId`, or dynamic with an `.Expand` proc). → [sql/tree.md](https://docs-llm.a2v10.com/sql/tree.md) |
| `!Group`      | Grouped/subtotal hierarchy from `GROUP BY ROLLUP` (not explicit parent ids). Rows sorted so subtotals precede details; nests via `!Items`. → [sql/grouping.md](https://docs-llm.a2v10.com/sql/grouping.md) |
| `!MapObject`  | Like `!Map`, but keyed by a `!Key` value instead of `Id`: each distinct key becomes a named property on the parent object. → [sql/map-object.md](https://docs-llm.a2v10.com/sql/map-object.md) |
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
| `!Utc`         | Convert the column UTC→local on model load. Uses the **server's** local time, not the client's. |
| `!RefId`       | FK reference to another entity (paired with a `!Map`). → [sql/object.md](https://docs-llm.a2v10.com/sql/object.md) |
| `!ParentId`    | Binds a child row to its parent (`[!<Parent>.<Field>!ParentId]`) |
| `!RowCount`    | Total row count for paging. → [sql/paging.md](https://docs-llm.a2v10.com/sql/paging.md) |
| `!RowNumber`   | Ordinal number of the row                                        |
| `!HasChildren` | Tree node has children → UI shows the expand arrow. Computed in SQL (`case when exists(...) then 1 else 0 end`); `!!` form, no type token. |
| `!Items`       | Nested-children placeholder column in `!Tree`/`!Group` results; always `= null`. |
| `!Expanded`    | Tree node renders pre-expanded in the UI. Static trees only — no effect on dynamic (`.Expand`) trees. |
| `!Permissions` | Int bitmask of row access rights — `cast(CanView as int) + cast(CanEdit as int)*2 + cast(CanDelete as int)*4 + cast(CanApply as int)*8` (same bits as [model-json.md](model-json.md#permissions)). |
| `!GroupMarker` | In a `!Group` set: holds `grouping(col)` (0=detail, 1=subtotal) for one `ROLLUP` column; one per rolled-up column, ordered `desc`. `!!` form. |
| `!ReadOnly`    | In `$System` only, `[!!ReadOnly] = 0/1`: when 1, the platform disables every UI control and blocks saving the model. |
| `!SortOrder`   | Echo of the active sort column (in `$System`). → [sql/system-datasets.md](https://docs-llm.a2v10.com/sql/system-datasets.md) |
| `!SortDir`     | Echo of the active sort direction (in `$System`). → [sql/system-datasets.md](https://docs-llm.a2v10.com/sql/system-datasets.md) |
| `!PageSize`    | Echo of the page size (in `$System`). → [sql/system-datasets.md](https://docs-llm.a2v10.com/sql/system-datasets.md) |
| `!Offset`      | Echo of the paging offset (in `$System`). → [sql/system-datasets.md](https://docs-llm.a2v10.com/sql/system-datasets.md) |
| `!Filter`      | Echo of a filter parameter back to the form (in `$System`); several written forms per filter kind. → [sql/system-datasets.md](https://docs-llm.a2v10.com/sql/system-datasets.md) |
| `!Json`        | Text column holding valid JSON; deserialized into an object in the model (not a string). **The object is NOT reactive.** |

## System recordsets — `$`-prefixed type token

Besides the sets that *form* the model, a procedure may return **system** sets: they steer
the processing, not the shape. Three exist — that is the whole list:

| Set | Purpose | Position among the result sets |
|---|---|---|
| `$System` | Echoes paging/sort/filter state back so the form keeps it on refresh; also carries `!ReadOnly`. Written `[!$System!]` — name mid-marker, not a suffix. | **After** every element it references (in practice, last) |
| `$Aliases` | Passes a field name **by value** where SQL only allows a literal; substitution applies to all *following* sets. **ONLY** for a `MapObject` whose set of keys is unknown until runtime — see the ban below. | **Before** the first use of an alias |
| `$Defaults` | Default values for not-yet-loaded elements of the model root. *NET.Core only.* | Anywhere |

**`$Aliases` — one use only.** It is legal **solely** when a `!MapObject`'s set of keys is not
known until runtime. Everything else is forbidden: **never** reach for `$Aliases` to shorten a
name, to avoid repeating a column, or to make the SQL read better. Substitution applies to
**every** name in **all** following result sets, so a "convenience" alias silently renames
columns in sets you were not thinking about — and nothing fails loudly.

→ [sql/system-datasets.md](https://docs-llm.a2v10.com/sql/system-datasets.md)

## `Metadata` — the `.Metadata` proc

`[<param>!<modelPath>!Metadata]` — `.Metadata` declares the model shape before `.Update` (one empty result set per TVP). Full → [sql/update-model.md](https://docs-llm.a2v10.com/sql/update-model.md).

## Cross-layer bindings — the «правила зв'язок»

The expanded cross-layer invariants (TVP column = client property; sort/filter pairs;
FK projection; parent-child Array; TableType ⇔ MERGE) live in [mapping.md](mapping.md)
§2 as named pairs, each with its failure mode. Use them as a post-generation
sanity-check.

---
> Full documentation: [sql.md](https://docs-llm.a2v10.com/sql.md)
