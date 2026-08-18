# XAML Conventions

**Full docs — [docs-llm.a2v10.com/xaml.md](https://docs-llm.a2v10.com/xaml.md).** That hub lists
every control and layout page with a one-line description. Element names, properties, syntax —
always there, never guessed. It is a catalogue of what exists, **not** a menu of what to use: an
element you had no reason to look for is not one your form was missing. Non-obvious entry points —
where mainline facts hide:

- [base-classes.md](https://docs-llm.a2v10.com/xaml/base-classes.md) — properties inherited by
  every element (`UIElementBase` / `UIElement` / `Control` / `ValuedControl` / `Container`).
  Read it before concluding an element lacks a property: most properties are declared here, not
  on the element's own page. Its list of derived classes is also the fullest inventory of
  controls in the docs — several of them (`Radio`, `MultiSelect`, `TimePicker`, `PeriodPicker`,
  `UploadFile`) have no page of their own.
- [bind.md](https://docs-llm.a2v10.com/xaml/bind.md) — `Bind` / `BindCmd`, all `DataType` and
  `CommandType` values.
- [layouts/fieldset.md](https://docs-llm.a2v10.com/xaml/layouts/fieldset.md) — a labeled frame
  around a group of fields. `Grid` has no `Border`; framing is `FieldSet`'s job.
- [layouts/sheet.md](https://docs-llm.a2v10.com/xaml/layouts/sheet.md) — spreadsheet-style
  tables, tree groups, cross columns. For on-screen reports start at [screen-report.md](screen-report.md).

> **A2v10 XAML is a WPF dialect, not WPF.** Names overlap — some elements and properties match
> WPF, some don't, some differ. Don't trust your WPF prior: verify every element and property
> name against the docs or the examples.

Working markup — `examples/`. Column → control projection and SQL ⇔ XAML invariants (sortable
column, `FilterItem` ⇔ procedure parameter, FK ⇔ `Map` ⇔ `SelectorSimple`) — [mapping.md](mapping.md).

The rest of this file is only what the docs structurally don't have: project conventions and
elements with no doc page.

> File extension on disk follows the project's `XAML naming convention` (`.vxaml` or legacy `.xaml`, CLAUDE.md). Content is identical either way; paths in `view:`/`Components` stay extension-less.

## Root elements → files

| Element | File |
|---|---|
| `Page` | `index.view`, `edit.view` |
| `Dialog` | `edit.dialog`, `browse.dialog` |
| `ComponentDictionary` | file of named XAML fragments (no doc page — see below) |

## ComponentDictionary — reusable components

A file containing a `ComponentDictionary` holds named XAML fragments.
It is attached to a `Page` or `Dialog` via the `Components` attribute:

```xml
<Page Components="{Components '../_components/_common'}">
```

The path is relative to the view file, without an extension.
A single file may attach several dictionaries separated by commas.

Using a component in markup:

```xml
<Component Name="Document.Toolbar"/>
<Component Name="Document.Header" Scope="{Bind Document}"/>
```

`Scope` is optional and changes the binding context inside the component.

## Toolbar — aligning the trailing group

Use `<ToolbarAligner/>`: an invisible spacer placed before the trailing elements, which pushes
them to the right edge. The attached property `Toolbar.Align="Right"` also works but is **no
longer recommended**; the examples use `ToolbarAligner` throughout
→ [controls/toolbaraligner.md](https://docs-llm.a2v10.com/xaml/controls/toolbaraligner.md).

## browse.dialog: column selection

In a browse dialog, only fields by which the user **identifies** the record when picking are shown.

**Include:** `Name` + context-key fields (phone, email, code, SKU — what people search by).
**Omit:** descriptive fields without identification value (`Address`, `Memo`, long notes).

Example: for an agent — `Name`, `Phone`, `Email`; `Address` and `Memo` are not needed.

## TabIndex

Set `TabIndex="1"` only on the **first** field of the form. Do not set `TabIndex` on the rest — tab order is determined by element order in the markup. This makes editing easier: rearranging rows is enough; you don't have to renumber indices.

## Index page

Canonical example: [examples/catalog/simple/index.view.xaml](../examples/catalog/simple/index.view.xaml).

**Sorting** — pick one of two modes, depending on the procedure:
- `<DataGrid Sort="True">` — when **all** columns are sortable (typical for catalogs).
- `<DataGrid Sort="False">` + `Sort="True"` on individual columns — when only some columns have
  a branch in the procedure's `case @Order when N'...'` (typical for documents/journals). A
  column without `Sort="True"` is shown but cannot be sorted.

**Filters — Taskpad or inline:**
- **Taskpad** (`<Page.Taskpad>`, to the right of the grid) — when there are **3+** filters
  (period + statuses + categories), to avoid eating vertical space above the grid.
- **Inline `StackPanel`** above the grid — when there are 1–2 filters (period or fragment).
