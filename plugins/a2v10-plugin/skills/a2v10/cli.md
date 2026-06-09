# CLI — principles (LLM-first)

## Working directory

Run `a2` from the **application root** — the project root, **not** `WebApp`, `MainApp`, or any module folder. The CLI resolves config, modules, and DB connection relative to the current directory; from the wrong folder it will not work.

## Availability

Before using it, make sure the `a2` CLI is available — check with `a2 --version`. If it is not, it's a .NET global tool ([A2v10.CLI](https://www.nuget.org/packages/A2v10.CLI) on NuGet), so install it (requires the .NET SDK):

```
dotnet tool install --global A2v10.CLI
```

Already installed but outdated → `dotnet tool update --global A2v10.CLI`.

The command set grows over time. If `a2` reports an **unknown command or flag** that this skill documents, the local tool is stale: run `dotnet tool update --global A2v10.CLI` once and retry. Do this before assuming a command doesn't exist.

## Core principle: a CLI for the LLM, not for a human

Every call is isolated. The LLM gets only what the command returned. If it didn't return something — the LLM doesn't know it.

## What follows from this

**There is no:**
- `init` / `new` / scaffold — the LLM reads the references and writes files directly.
- Interactive prompts — an "Are you sure?" would hang. Never.
- ANSI colors — noise for the parser.
- `--json` as opt-in — JSON is always on.

**There is:**
- JSON output by default, always.
- Idempotency — safe to run twice.
- Verbose by default — the LLM needs completeness, not brevity.
- A full description of what changed, not just success/fail.
- Structured errors with `available` / actionable guidance.

## Response format

Success:
```json
{ "success": true, "data": { ... } }
```

Error:
```json
{ "success": false, "error": { "message": "..." } }
```

## Canonical table format

`schema.[Table]` — used everywhere: as a command argument and in responses.

Examples: `cat.[Agents]`, `doc.[Invoice]`, `cat.[Agent.Addresses]`.

Brackets are mandatory — a table name may contain a dot.

## Command `a2 app config` — project configuration

Returns application-level decisions that must be **written into CLAUDE.md** during onboarding of an existing project (SKILL.md §6 → `references/existing-project.md`), plus the list of modules.

```json
{
  "success": true,
  "data": {
    "multiTenant": false,
    "modules": [
      { "prefix": "$admin",    "root": null },
      { "prefix": "",          "root": "MainApp" },
      { "prefix": "$meta",     "root": null },
      { "prefix": "$workflow", "root": null }
    ]
  },
  "error": null
}
```

- `multiTenant` — whether the project is multi-tenant (affects procedure parameters / WHERE clauses).
- `modules` — the list of application modules (see below).

`data` may contain other fields too — **not yours**: they serve other tools. Ignore them, read only `multiTenant` and `modules`.

### `modules` — modules and routing

An endpoint URL may start with a module prefix: `/[$<module>]/<path>/<action>/<id>`. Each entry:

- **`prefix`** — the literal URL token of the module, **including the `$`** (`"$admin"`); `""` — the main application (no prefix).
- **`root`** — the module's source folder, a path **from the project root, without a leading slash** (`"MainApp"`). `null` — the module has no local folder.

From these fields the LLM builds two formulas:

- **URL** = `prefix` + `/<path>/<action>/<id>` — always (works even for `root: null`).
- **File** = `root` + `/<path>/...` → `…/model.json` — **only when `root` is not `null`**.

`root: null` → the module's endpoints exist only as a built artifact: they can be invoked and linked (the `prefix` formula), but **there is nowhere to write them — the source location physically does not exist**. Do not create folders for them.

## Commands `a2 db`

### `a2 db tables [schema]`

A list of tables grouped by schema. `schema` — an optional filter.

```json
{ "success": true, "data": ["cat.[Agents]", "cat.[Units]", "doc.[Invoice]"] }
```

### `a2 db table-columns cat.[Agents]`

Table structure. Conventions: `Id` — always PK, FK columns nullable.

```json
{
  "success": true,
  "data": {
    "columns": [
      { "name": "Id",    "type": "bigint" },
      { "name": "Name",  "type": "nvarchar(255)" },
      { "name": "Agent", "type": "bigint", "ref": "cat.[Agents]" }
    ]
  }
}
```

`ref` — the canonical table format.

### `a2 db referenced-by cat.[Agents]`

Tables and columns that reference the given table.

```json
{
  "success": true,
  "data": [
    { "table": "doc.[Invoice]", "column": "Agent" },
    { "table": "doc.[Order]",   "column": "Agent" }
  ]
}
```

## Commands `a2 endpoint` — the `resolve-*` family

One command per model.json section. Each resolves a single element the way the runtime sees it: which procedures and files it is bound to, and which model shape it returns. This is the answer key for cross-checking the layers — don't guess the shape from your own markers, verify it against what the runtime actually assembled.

`route` addresses the element (`/[$<module>]/<path>/<element>`), e.g. `catalog/agent/edit`. **No `id`** — types come from the schema of the result sets (column metadata), not from data; an actual record is not needed.

`dataModel` is obtained by **invoking** the `load`/`index` procedure, so if it doesn't exist the command fails entirely (`success: false`, `error`) rather than returning a partial result.

**When to call — post-deploy, discretionary.** This is the verification half of the "wrote → verify" loop, not authoring-time: the procedures must already exist in the DB — the **module you edited** rebuilt so its `main.sql` is regenerated, and that script applied. Rebuild **just that module** — `dotnet build <root>`, the module's `root` folder (from `a2 app config`) — **never the solution**: a solution build also rebuilds the `WebApp` host and fails when the user is running it (its output DLLs and port are locked), while the module build is untouched by the running host. (Whole-solution build belongs only to first-time setup, before the host has ever run → `references/new-project.md`.) Before deployment the command fails **by design** — that means "not deployed yet", not "broken". Calling it is not mandatory after every small change; the deploy may not be in the LLM's hands — then there is simply nothing to verify.

For now there are the commands below. `resolve-report` / `resolve-files` — added as needed.

### `a2 endpoint resolve-action <route>` · `a2 endpoint resolve-dialog <route>` · `a2 endpoint resolve-popup <route>`

Renderable — `actions` (page), `dialogs` (modal), and `popups` (popup). **The output shape is identical**; the only difference is which model.json section to look the name up in (the command = a mirror of the section, not a difference in contract).

```json
{
  "success": true,
  "data": {
    "route": "catalog/agent/edit",
    "model": "Agent",
    "view":     { "dir": "catalog/agent/edit", "file": "view.dialog.xaml" },
    "template": { "dir": "catalog/agent/edit", "file": "edit.template.ts" },
    "sqlProcedures": {
      "load":   "cat.[Agent.Load]",
      "update": "cat.[Agent.Update]"
    },
    "dataModel": {
      "types": {
        "TRoot":  { "props": { "Agent": { "type": "TAgent", "len": null } }, "id": null, "name": null },
        "TAgent": { "props": { "Id":    { "type": "number", "len": null },
                               "Name":  { "type": "string", "len": 100 },
                               "Store": { "type": "TStore", "len": null } }, "id": "Id", "name": "Name" },
        "TStore": { "props": { "Id":   { "type": "number", "len": null },
                               "Name": { "type": "string", "len": 100 } }, "id": "Id", "name": "Name" }
      }
    }
  },
  "error": null
}
```

- **`model`** — the main editable object; other root props (lookup lists for combos) are not the entity.
- **`view`/`template`** — `{ dir, file }`: `dir` with `/` (like `route`), `file` — the real name with extension, ready to open. `template.file` — the **source to edit** (`.ts`; if absent — `.js`), not the compiled `.js`. There is deliberately no existence check: a missing or misnamed file is surfaced by `build`, not by resolve.
- **`sqlProcedures`** — verb (lowercase) → the real SQL procedure name the runtime will call, ready for `CREATE OR ALTER` (schema without brackets, like the `cat.[T]` canon). The set depends on the element: `edit` → `load`+`update`, no `index`. Explicit and derived are not distinguished — the name is what's needed, not the origin.
- **`dataModel.types`** — the type tree the runtime generated from the result-set schema; a 1:1 projection of the platform model description. Each prop has `type` + `len`: `len` = `null`, except for a string with a given length (`"string"`, `len: 100`). Primitives — lowercase (`number`/`string`/…); a named type — `T…`; an array → `{ "item": "T…" }`. `id`/`name` are always present (`null` when absent, as in `TRoot`). This is what you cross-check XAML binds against and what your SQL markers were supposed to return.

### `a2 endpoint resolve-command <route>`

Callable — the `commands` section. Unlike renderable: **`view`/`template` are absent**; `sqlProcedures` = what the command actually calls (derived verb or explicit `procedure`/clr/api); `dataModel` — **only if the command returns a model**, otherwise null.
