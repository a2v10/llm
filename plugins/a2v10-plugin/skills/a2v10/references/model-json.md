# model.json

The `model.json` file describes the configuration of A2v10 application endpoints: actions, dialogs, popups, commands, reports, and files.

## Inheritance

The properties `source`, `schema`, `model` defined at the top level of the file are inherited by all sections (`actions`, `dialogs`, `popups`, `commands`, `reports`, `files`). A value set inside a section or element overrides the parent.

```json
{
  "source": "default",
  "model": "MyModel",
  "actions": {
    "browse": {
      "model": "BrowseModel"
    }
  }
}
```

---

## Top level

| Property      | Type   | Description                                    |
|---------------|--------|------------------------------------------------|
| `$schema`     | string | Reference to JSON Schema                       |
| `description` | string | Endpoint archetype, e.g. `catalog.simple`      |
| `source`      | string | Default data source (inherited)                |
| `model`       | string | Default model (inherited)                      |
| `schema`      | string | Default DB schema (inherited)                  |

---

## permissions

An object with arbitrary key names. Each value is one of:

`view` | `edit` | `delete` | `apply` | `create` | `unapply` | `flag64` | `flag128` | `flag256`

```json
"permissions": {
  "Alice": "edit",
  "Bob": "view"
}
```

---

## actions / dialogs / popups

An object with arbitrary key names. Each element is a configuration object.

### Common properties

| Property      | Type    | A | D | P | Description                                     |
|---------------|---------|---|---|---|-------------------------------------------------|
| `index`       | boolean | + | + | — | Index endpoint (calls `.Index`)                 |
| `copy`        | boolean | + | + | — | Record copy mode (calls `.Copy`)                |
| `source`      | string  | + | + | + | Data source (overrides top-level)               |
| `schema`      | string  | + | + | + | DB schema (overrides top-level)                 |
| `model`       | string  | + | + | + | Model (overrides top-level)                     |
| `view`        | string  | + | + | + | View file name                                  |
| `template`    | string  | + | + | + | Template                                        |
| `signal`      | boolean | + | + | — | Action may emit a SignalR message to the user   |
| `parameters`  | object  | + | + | + | Default parameters                              |
| `permissions` | object  | + | + | + | Access rights (see [permissions](#permissions)) |

> **A** = actions, **D** = dialogs, **P** = popups.
> `index` and `copy` are mutually exclusive.

### Properties for actions only

| Property        | Type     | Description                                       |
|-----------------|----------|---------------------------------------------------|
| `skipDataStack` | boolean  | Skip the data stack                               |
| `plain`         | boolean  | Plain (non-model) response                        |

## commands

An object with arbitrary key names. Each element describes a command.

### type

| Value            | Description                                       |
|------------------|---------------------------------------------------|
| `sql`            | Stored procedure call                             |
| `clr`            | .NET CLR type call (implements `IInvokeTarget`)   |
| `file`           | Returns a file for download                       |

### Command properties

| Property     | Type    | Description                                                  |
|--------------|---------|--------------------------------------------------------------|
| `source`     | string  | Data source                                                  |
| `schema`     | string  | DB schema                                                    |
| `model`      | string  | Model                                                        |
| `command`    | string  | Command name                                                 |
| `procedure`  | string  | Stored procedure name (for `sql`)                            |
| `target`     | string  | Target in `Object.Method` format                             |
| `clrType`    | string  | CLR type (format: `clr-type:My.Type;assembly=MyAssembly`)    |
| `async`      | boolean | Asynchronous execution                                       |
| `parameters` | object  | Default parameters                                           |
| `debugOnly`  | boolean | Debug mode only                                              |
| `signal`     | boolean | Command may emit a SignalR message to the user               |
| `permissions`| object  | Access rights (see [permissions](#permissions))              |

---

## reports

An object with arbitrary key names.

### type

| Value    | Description    |
|----------|----------------|
| `xml`    | XML report     |
| `json`   | JSON report    |
| `pdf`    | PDF document   |
| `xlsx`   | Excel spreadsheet |

### Report properties

| Property     | Type     | Description                                                           |
|--------------|----------|-----------------------------------------------------------------------|
| `source`     | string   | Data source                                                           |
| `schema`     | string   | DB schema                                                             |
| `model`      | string   | Model                                                                 |
| `procedure`  | string   | Stored procedure name (defaults to `[model].Report`)                  |
| `name`       | string   | Download file name; supports `{{Property.Path}}` macros               |
| `encoding`   | string   | Encoding (`utf-8`, `utf-16`, `windows-1251`)                          |
| `xmlSchemas` | string[] | XML schemas for validation                                            |
| `permissions`| object   | Access rights (see [permissions](#permissions))                       |

---

## files

An object with arbitrary key names. Describes uploaded file handling.

### type

| Value         | Description                  |
|---------------|------------------------------|
| `parse`       | File parsing                 |
| `clr`         | Handled by a .NET CLR type   |
| `sql`         | Handled by SQL               |
| `azureBlob`   | Azure Blob Storage           |
| `blobStorage` | Blob storage                 |
| `json`        | JSON file                    |
| `excel`       | Excel file                   |
| `text`        | Text file                    |

### parse

| Value    | Format           |
|----------|------------------|
| `excel`  | Excel (auto)     |
| `xlsx`   | Excel 2007+      |
| `xls`    | Excel 97-2003    |
| `csv`    | CSV              |
| `dbf`    | DBF              |
| `xml`    | XML              |
| `auto`   | Auto-detect      |
| `json`   | JSON             |

### File properties

| Property         | Type    | Description                                                  |
|------------------|---------|--------------------------------------------------------------|
| `source`         | string  | Data source                                                  |
| `schema`         | string  | DB schema                                                    |
| `model`          | string  | Model                                                        |
| `async`          | boolean | Asynchronous processing                                      |
| `clrType`        | string  | CLR type (format: `clr-type:My.Type;assembly=MyAssembly`)    |
| `locale`         | string  | Locale for parsing data                                      |
| `container`      | string  | Container name (for blob)                                    |
| `outputFileName` | string  | Output file name                                             |
| `zip`            | boolean | Archive the result                                           |
| `azureSource`    | string  | Azure connection string                                      |
| `blobSource`     | string  | Blob source                                                  |
| `blobStorage`    | string  | Blob storage                                                 |
| `key`            | string  | Key                                                          |
| `availableModels`| array   | List of allowed models for import (see below)                |
| `permissions`    | object  | Access rights (see [permissions](#permissions))              |

### availableModels

An array of objects. Each object:

| Property     | Type   | Description            |
|--------------|--------|------------------------|
| `name`       | string | Model name             |
| `columns`    | string | Columns description    |
| `source`     | string | Data source            |
| `schema`     | string | DB schema              |
| `model`      | string | Model                  |
| `parameters` | object | Default parameters     |

---
> Full documentation: [model.md](https://docs-llm.a2v10.com/model.md)
