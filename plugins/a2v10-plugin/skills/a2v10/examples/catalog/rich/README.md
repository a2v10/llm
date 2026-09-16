# Example: catalog.rich

A rich catalog (`cat.Agents` — контрагент) that shows, in **one model / one endpoint**, the
full range a reference entity reaches in practice:

- **references** across their whole range — a plain FK (`Manager`), an FK rendered with a
  color (`State`), and FKs **inside** a table-part row (`Bank`, `Currency`);
- **boolean flags** (`IsCustomer`, `IsSupplier`);
- **two table parts** — `Addresses` (plain scalars) and `Accounts` (two references per row);
- **tags** — a many-to-many link, modelled as a reference-only table part.

Same header `cat.Agents` that `document/operation` references — this example defines it.

## Files

| File                  | Purpose                                                   |
|-----------------------|-----------------------------------------------------------|
| `schema.sql`          | Sequences + `cat.Agents`, 3 table parts, 5 stub FK targets |
| `keys.sql`            | FK constraints                                            |
| `logic.sql`           | All stored procedures + table types                      |
| `model.json`          | Action `index`; `edit` + `browse` dialogs; `fetch` command |
| `index.d.ts`          | Type definitions for the list form                       |
| `index.template.ts`   | List template; shared by index and browse                |
| `edit.d.ts`           | Type definitions for the edit form (header + 3 arrays)   |
| `edit.template.ts`    | Edit form template (`$$Tab`, `Name` validator, `tagSettings` delegate) |
| `index.view.vxaml`    | List page (State badge, tags via `<TagsList>`, State + Tags filters) |
| `edit.dialog.vxaml`   | Edit dialog (form + tabbed table parts; Taskpad = Manager, Tags) |
| `browse.dialog.vxaml` | Pick-record dialog                                       |
| localization *(append)* | Entity keys: `@Agent`, `@Agents`, `@Browse.Agent`, plus field keys below |

## Procedures

| Procedure         | Purpose                                        |
|-------------------|------------------------------------------------|
| `Agent.Index`     | Paginated list; filters `Fragment` + `State` + `Tags` |
| `Agent.Load`      | Header + 3 arrays + Map result sets            |
| `Agent.Metadata`  | Edit form metadata (header + 3 table types)    |
| `Agent.Update`    | Save — one header + 3 children (see below)     |
| `Agent.Fetch`     | Quick search for the browse dialog             |
| `Agent.Delete`    | Soft delete (`Void = 1`)                        |

## Design notes

**The spine is `Agent.Update`.** Everything else is fields hung on it. One `merge` for the
header (keyed by `@id` from `output inserted.Id`), then one `merge` per child — addresses,
accounts, tags — **each keyed by `t.Agent = @id`**. No `GUID` / `ParentGUID` anywhere: the
parent already has `@id`, so first-level children link to it directly. `ParentGUID` is only
needed one level deeper (a table part inside a table part), which this catalog does not have.

**References across their range** (each is the SQL `RefId` + `Map` pair, see
`references/mapping.md` Pair 5):

| Where            | Reference kind                    |
|------------------|-----------------------------------|
| `Manager`        | plain single FK in the header     |
| `State`          | single FK, rendered with a color  |
| `Bank`, `Currency` | FK **inside** a table-part row   |
| `Tag`            | FK inside a reference-only row = m2m |

**Tags — a shared dictionary edited with `<TagsControl>`.** `cat.Tags` is generic — one tags
table for every entity, discriminated by `[For]` (here `'Agent'`, matching model.json `"model"`).
The per-entity m2m binding stays in `cat.AgentTags`. The edit dialog's Taskpad uses the
dedicated control:

- `Value="{Bind Agent.Tags}"` — the linked tags (the m2m rows; each carries a `Tag` RefId).
- `ItemsSource="{Bind Tags}"` — a **root-level** collection of the available tags, loaded by
  `Agent.Load` as `select [Tags!TTag!Array] ... where [For] = N'Agent'`.
- `SettingsDelegate="tagSettings"` — a template delegate that opens the shared Tags dictionary
  via `$showDialog('/catalog/tag/settings', null, { For: 'Agent' })`, so `[For]` flows through.

Save is unchanged — the `@Tags` TVP into `cat.AgentTags`, keyed by `@id`.

**Tags in the list.** `Agent.Index` gives each row its own `Tags` child array (Pair 6: the
placeholder `[Tags!TTag!Array]` in the row projection + a second result set carrying
`[!TAgent.Tags!ParentId]`). The Name column renders it with `<TagsList>` next to the name inside
a `<Block>`. Because that column's content is a `Block` (not a plain `Content` bind), the sort
field can't be inferred — `SortProperty="Name"` names it. Tag chips use `cat.Tags.Color`.

**Edit in a dialog, classification in the Taskpad.** Editing is a `dialogs.edit` (`edit.dialog`,
root `<Dialog>`), not a page — so the list / browse open it with `Dialog Action=Append/EditSelected/Edit`.
The dialog's `<Dialog.Taskpad>` holds *our* classification of the agent — `Manager` and `Tags` —
kept apart from its real properties (name, memo, addresses, accounts) in the main form.

**Stub FK targets.** `Employees`, `AgentStates`, `Banks`, `Currencies`, `Tags` are defined
here minimally, only so FKs / `Map` / selectors resolve. In a real project each is a full
catalog of its own — `Tags` in particular is a shared, generic dictionary (see above).

## Verify before reuse

- **State color** is rendered as `<Span CssClass="{Bind State.Color}"/>`, with the CSS class
  stored in `AgentStates.Color`. Confirm the project's badge/color convention.
- **`<TagsControl>`** — root `Tags` (`TTag`) and `Agent.Tags` (`TAgentTag`) share the field name
  at different scopes (root pool vs. child links); confirm the engine keeps them distinct. The
  `/catalog/tag/settings` dialog and the `cat.Tags` endpoint are stubs (the future Tags example).
  Check whether the linked-tags `Map` is still needed once `ItemsSource` resolves names.
- **IBAN validator** on `Accounts.Iban` is intentionally not written yet (planned for
  `edit.template.ts`).

## Localization keys

`@Agent`, `@Agents`, `@Browse.Agent`, `@Manager`, `@State`, `@Customer`, `@Supplier`,
`@GeneralInfo`, `@Addresses`, `@Accounts`, `@Tags`, `@Kind`, `@City`, `@Street`, `@Zip`,
`@Bank`, `@Currency`, `@Iban`, `@Tags`, `@Tag.Choose`, `@Tag.Settings`, `@AddRow`, `@RowNo`,
`@All`, `@Filters`.
