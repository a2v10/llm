# XAML Conventions

> File extension on disk follows the project's `XAML naming convention` (`.vxaml` or legacy `.xaml`, CLAUDE.md). Content is identical either way; paths in `view:`/`Components` stay extension-less.

> Document is being filled in. Up-to-date examples — in `examples/`.
>
> For column → control mapping (Money / FK / Date / Boolean / Enum) and SQL ↔ XAML invariants (sortable column, FilterItem ⇔ procedure parameter, FK ⇔ Map ⇔ SelectorSimple, etc.) see [mapping.md](mapping.md).

## Namespace

```xml
xmlns="clr-namespace:A2v10.Xaml;assembly=A2v10.Xaml"
```

> **A2v10 XAML is a WPF dialect, not WPF.** Names overlap — some elements and properties match WPF, some don't, some differ. Don't trust your WPF prior: verify every element and property name against the examples or the full docs.

## Root elements

| Element              | Purpose                                  |
|----------------------|------------------------------------------|
| `Page`               | Page (index.view, edit.view)             |
| `Dialog`             | Dialog (edit.dialog, browse.dialog)      |
| `ComponentDictionary`| File with named XAML fragments           |

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

## SelectorSimple — selecting an FK value

Used for reference fields. Opens the related catalog's browse dialog and calls the fetch command for autocomplete.

```xml
<SelectorSimple Label="@[Category]" Value="{Bind Sample.Category}" Url="/catalog/category" />
```

| Attribute | Purpose |
|---|---|
| `Label` | Field label |
| `Value` | Binding to the object's FK field |
| `Url` | Catalog URL (without `/browse` — the platform appends it) |

## browse.dialog: column selection

In a browse dialog, only fields by which the user **identifies** the record when picking are shown.

**Include:** `Name` + context-key fields (phone, email, code, SKU — what people search by).
**Omit:** descriptive fields without identification value (`Address`, `Memo`, long notes).

Example: for an agent — `Name`, `Phone`, `Email`; `Address` and `Memo` are not needed.

## TabIndex

Set `TabIndex="1"` only on the **first** field of the form. Do not set `TabIndex` on the rest — tab order is determined by element order in the markup. This makes editing easier: rearranging rows is enough; you don't have to renumber indices.

## Index page — structure

Canonical example: [examples/catalog/simple/index.view.xaml](../examples/catalog/simple/index.view.xaml).

Index page skeleton:

```xml
<Page Title="@[Samples]">
  <Page.CollectionView>
    <CollectionView ItemsSource="{Bind Samples}" RunAt="ServerUrl">
      <CollectionView.Filter>
        <FilterDescription>
          <FilterItem Property="Fragment" DataType="String"/>
          <!-- one FilterItem per non-paging procedure parameter -->
        </FilterDescription>
      </CollectionView.Filter>
    </CollectionView>
  </Page.CollectionView>

  <Grid Rows="Auto,1*,Auto" Height="100%">
    <Toolbar>...</Toolbar>
    <DataGrid ItemsSource="{Bind Parent.ItemsSource}" FixedHeader="True">...</DataGrid>
    <Pager Source="{Bind Parent.Pager}"/>
  </Grid>
</Page>
```

**`FilterItem` rules** — one per filter parameter of the procedure (other than `@Offset`/`@PageSize`/`@Order`/`@Dir`):

| `DataType` | Procedure parameters | UI control |
|---|---|---|
| `Period` | a pair `@From` + `@To` | `<PeriodPicker Value="{Bind Parent.Filter.Period}"/>` |
| `String` | a single nvarchar (`@Fragment`, `@Status`, `@Category`) | `<SearchBox>` for search, `<ComboBox>` for a flag |

`<Pager>` is mandatory and is bound to `Parent.Pager`. `<DataGrid ItemsSource>` is always `{Bind Parent.ItemsSource}`.

## DataGrid — column conventions

| Column class | Attributes | Example |
|---|---|---|
| PK | `Role="Id"` | `<DataGridColumn Content="{Bind Id}" Role="Id"/>` |
| Date (`date`) | `DataType="Date"`, `Role="Date"` | `<DataGridColumn Content="{Bind Date, DataType=Date}" Role="Date" Sort="True"/>` |
| DateTime (`datetime2`) | `DataType="DateTime"`, `Role="Date"` | `<DataGridColumn Content="{Bind Modified, DataType=DateTime}" Role="Date"/>` |
| Money | `{BindSum}`, `Role="Number"` | `<DataGridColumn Content="{BindSum Sum}" Role="Number" Sort="True"/>` |
| Boolean | `Role="CheckBox"` | `<DataGridColumn Content="{Bind IsActive}" Role="CheckBox"/>` |
| FK Map | dot notation in Bind | `<DataGridColumn Content="{Bind Agent.Name}" LineClamp="2"/>` |
| Long text | `LineClamp="2"` or `Fit="True" Wrap="NoWrap"` | `<DataGridColumn Content="{Bind Memo}" LineClamp="2"/>` |
| Stretcher | empty trailing column | `<DataGridColumn />` |

**Sort rules:**
- `<DataGrid Sort="True">` — when **all** columns are sortable (typical for catalogs).
- `<DataGrid Sort="False">` + `Sort="True"` on individual columns — when only some columns have a branch in the procedure's `case @Order when N'...'` (typical for documents/journals). A column without `Sort="True"` is shown but cannot be sorted.

FK Map (`{Bind Agent.Name}`) works because the procedure's SELECT contains `[Agent!TAgent!RefId] = d.Agent` + a Map result set — the platform automatically resolves `Agent.Name` via Id.

## Taskpad — sidebar of filters

An alternative layout to filters-above-grid: place filters in `<Page.Taskpad>` to the right of the grid.

```xml
<Page.Taskpad>
  <Taskpad>
    <Panel Header="@[Filters]">
      <PeriodPicker Label="@[Period]" Value="{Bind Parent.Filter.Period}" Placement="BottomRight"/>
      <ComboBox Label="@[Status]" Value="{Bind Parent.Filter.Status}">
        <ComboBoxItem Value="all"    Content="@[All]"/>
        <ComboBoxItem Value="active" Content="@[Active]"/>
        <ComboBoxItem Value="closed" Content="@[Closed]"/>
      </ComboBox>
    </Panel>
  </Taskpad>
</Page.Taskpad>
```

**When Taskpad, when inline:**
- **Taskpad** — when there are **3+** filters (period + statuses + categories), to avoid eating vertical space above the grid.
- **Inline `StackPanel`** above the grid — when there are 1–2 filters (period or fragment).

A ComboBox filter requires an nvarchar parameter in the procedure with a default value of `'all'` and a branch:
```sql
@Status nvarchar(32) = N'all'
-- ...
and (@Status = N'all' or s.[Status] = @Status)
```
Plus `<FilterItem Property="Status" DataType="String"/>` in `FilterDescription`.

---
> Full documentation: [xaml.md](https://docs-llm.a2v10.com/xaml.md)
