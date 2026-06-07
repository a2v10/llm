# Example: catalog.simple

A simple flat catalog without FKs or detail tables. Fields: `Name`, `Memo`.

## Files

| File                  | Purpose                                         |
|-----------------------|-------------------------------------------------|
| `schema.sql`          | Sequence + table                                |
| `logic.sql`           | All stored procedures                           |
| `model.json`          | Definition of actions, dialogs, commands        |
| `index.d.ts`          | Type definitions for the list form              |
| `index.template.ts`   | List template; shared by index and browse       |
| `edit.d.ts`           | Type definitions for the edit form              |
| `edit.template.ts`    | Edit form template                              |
| `index.view.xaml`     | List page                                       |
| `edit.dialog.xaml`    | Create / edit record dialog                     |
| `browse.dialog.xaml`  | Pick-record dialog for the catalog              |
| `_default.uk.txt` *(append)* | Entity keys: `@Sample`, `@Samples`, `@Browse.Sample` |

## Procedures

| Procedure          | Purpose                            |
|--------------------|------------------------------------|
| `Sample.Index`     | Paginated list with filter         |
| `Sample.Load`      | Load a single record               |
| `Sample.Metadata`  | Edit form metadata                 |
| `Sample.Update`    | Save (insert/update)               |
| `Sample.Fetch`     | Quick search for the browse dialog |
| `Sample.Delete`    | Soft delete (Void = 1)             |
