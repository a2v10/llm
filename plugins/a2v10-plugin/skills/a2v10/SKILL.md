---
name: a2v10
description: >
  Work with the A2v10 platform: endpoints (model.json), XAML/HTML views, SQL
  stored procedures, template.ts, localization, DB migrations.
  USE when the request mentions A2v10, model.json, view.vxaml (or view.xaml), template.ts, an
  A2v10 endpoint, or files matching the A2v10 layout. Do NOT use for generic
  SQL, XAML, or TypeScript unrelated to A2v10.
---

# A2v10 Platform Skill

## 1. What A2v10 is

A2v10 is a **generic runtime**, like a web framework: it gives you *syntax*
(routing, file binding, the SQL↔runtime protocol) and **no domain semantics**.
Files are interpreted on the fly — there is **no build or compile step**.
Data access is **ONLY through stored procedures** — the platform never runs ad-hoc SQL.
What a `catalog`, an `Agent`, or an `edit` action *means* — and likewise schemas
(`cat/doc/jrn`), the element set, column sets, naming style — is defined entirely
by the app, never by the engine; they are *how most apps usually look*, not rules.
This file is the **syntax reference**. The app's *meaning* comes from the project,
not from here (see **§5 Workflow**).

**Localization** is a runtime-wide macro: the runtime replaces `@[Key]` with a localized value from the project's dictionaries. Details → `references/localization.md`.

## 2. Tooling

A read-only CLI named **`a2`** inspects a project for you — its config (`a2 app config` — tenancy, modules, …) and database (tables, columns, references), as JSON. It is the standard way to learn an existing project, and the tool that every *use the `a2` CLI to …* in this skill refers to. The command set grows over time.

**Ensure it's available first** — if `a2` is not installed, install it from NuGet ([A2v10.CLI](https://www.nuget.org/packages/A2v10.CLI)) or ask the user how. Commands and output shapes → `cli.md`.

## 3. Model — how the engine works (syntax)

A **model** is a business entity the engine processes as one unit — a single logical whole, backed by one or more related tables.

The engine resolves a URL into work. Names are arbitrary to it.

- **URL = `/[$<module>]/<path>/<action>/<id>`** — e.g. `/catalog/agent/edit/100`, or `/$admin/catalog/agent/edit/100` inside a module. The URL *is* the addressing model.
- **`path`** (`catalog/agent`) locates an **endpoint** — a folder with `model.json`. Path segments (`catalog`/`document`/`journal`) are opaque; the runtime does not interpret them — **except** a leading `$`-prefixed segment, the one thing it does interpret: a **module** it resolves (via config) to a source root. `$` is the marker "interpret this."
- **`module`** (optional, `$`-prefixed) relocates the path's root. Modules and their roots come from `a2 app config`; `root: null` = no local folder — call/link the module, but there is nowhere to write into it.
- **`model.json`** declares `schema`, `model`, and the endpoint's elements. Element names are **free** (`edit`, `myAction1`, …).
- **`id`** selects the record.

**A raw endpoint is a folder with `model.json`. No `model.json` → not yours.** Another skill or a human owns that folder. Do not read it, do not add files to it, do not touch it. You do not need to know why.

### An endpoint exposes renderables and callables

The elements come in two kinds:

| Kind | Sections | What it is |
|---|---|---|
| **Renderable** | `actions` (page), `dialogs` (modal), `popups` | Has UI: binds `view`+`template`, the runtime renders it, the user interacts and posts the model back. |
| **Callable** | `commands`, `reports`, `files` | No UI: invoked, runs once, returns data / a file / an effect. |

*(Full catalog of sections and their options → `references/model-json.md`.)*

**View/template (renderables) — declared.** `view:` / `template:` keys name the file explicitly; the path may be local (`edit.view`) or relative cross-folder (`../another/edit.view`).

**XAML file extension — a project convention.** On disk, XAML files carry `.vxaml` (or legacy `.xaml`) — identical content, the extension only reflects the user's IDE (VS-2026 needs `.vxaml`). One extension per project, recorded in CLAUDE.md as `XAML naming convention`; reading tolerates either, **creating** a file uses the project's. The `view:`/`template:` key is **extension-less** — binding never names it, so this never touches `model.json`.

**Procedure name — convention vs explicit.** Two ways an element binds its stored procedure:

- **`model` given → convention.** The runtime *derives* the name `<schema>.[<model>.<Verb>]` and calls it — you must create a proc with exactly that name. `schema`/`model` are declared at the top, **inherited**, **overridable** per element. The **Verb** is a derived role — *which* fire depends on what the element does (open → `Load`, save → `Update`, list → `Index`, …). Full verb set & proc templates → `references/sql-procedures.md`.
- **`procedure` given → explicit.** You write the full procedure/target name yourself. This is the exception, and it lives **only in `commands`** — e.g. a custom `sql` command, or a `clr`/`callApi` target. The runtime does not derive it.

**Verb ≠ Contract.** The **Verb** (or explicit name) is how the runtime *finds* the procedure. The **Contract** — its parameter shape (TVP) and result-set markers — is what it *returns*. Orthogonal: a proc found by the right verb still binds wrong if its Contract is off, and every procedure (derived or explicit) has a Contract.

**SQL ↔ runtime protocol.** Stored procedures return data via **result-set markers** — a naming grammar that binds proc output to the client model, with names agreeing across layers (TVP column = client property; marker ↔ `d.ts` ↔ XAML). The grammar itself is writing-time detail → `references/sql-rules.md`.

**Some elements follow conventions.** Few, but real: where the engine treats names as free, certain (mostly client-side) elements assume a specific name/structure and **silently fail** without it. Catalog of these exceptions → `references/elem-conventions.md`; honor it.

## 4. Rules

### Must — break it and it does not work (engine contract)

- Access data only through stored procedures; never raw SQL.
- Procedures must exist under the **exact** name — either the one the runtime **derives** from `model` (`<schema>.[<model>.<Verb>]`) or the one a `command` names **explicitly** (`procedure`). A misnamed proc is simply not found.
- Follow the result-set marker grammar; keep cross-layer names in agreement (TVP column = client property; marker ↔ d.ts ↔ XAML).

### Avoid — it works, but it's wrong (LLM traps)

These are things the engine *allows* and the model is *naturally pulled toward*. Resist them.

- **Do not retarget `model` per element.** The engine permits a per-element `model` override; treat it as a severe anti-pattern — one `model.json` = one `model`. Override only when there is genuinely no other way.
- **Do not over-share views.** Default: one `view` + one `template` per model. Sharing them across models — and conditional rendering inside a shared view — is a *rare, deliberate* exception, justified explicitly. **Never** collapse many models into one view via `if`-branches to "save files."

**Broke and the cause isn't obvious?** Don't guess — go to the references for the layer you touched (and `references/troubleshooting.md`); they spell out what to verify and how.

## 5. Workflow

1. **Read CLAUDE.md.**
2. **It exists** → work the task → §6 Dispatch.
3. **It's missing** → set up the project first, then work:
   - new project → `references/new-project.md`
   - existing project → `references/existing-project.md`

Setup establishes the project's semantics and records them in CLAUDE.md — so step 3 runs once.

Unsure → ask; never guess.

## 6. Dispatch — find the task

Each row is an action you take. The kind (catalog / document / journal / …) is **semantics**, not a routing axis — `new-endpoint.md` reads it from CLAUDE.md.

**Create an endpoint** (from an existing table / from scratch) → `references/new-endpoint.md`

**Wire app navigation (system menu)** → `references/menu.md`

**Within an endpoint:**

| Action | Go to |
|---|---|
| add a field | `references/add-field.md` |
| edit the view | `references/xaml.md` |
| edit the template | `references/template.md` |
| edit a procedure | `references/sql-procedures.md` (verb/structure) + `references/sql-rules.md` (result-set markers) |
| add a report / command | `references/model-json.md` |
| add a dialog | `references/model-json.md` + `references/xaml.md` + `references/sql-procedures.md` — Renderable: declare it, then build its view + template + proc |

**No row matches?** Don't force-fit. Route by the layer you touch (SQL → `sql-rules.md` / `sql-procedures.md`, view → `xaml.md`, behavior → `template.md`, config → `model-json.md`). Capabilities none cover → full docs: https://docs-llm.a2v10.com . Still unclear → ask.
