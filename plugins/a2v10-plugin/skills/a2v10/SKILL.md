---
name: a2v10
description: >
  Work with the A2v10 platform: endpoints (model.json), XAML/HTML views, SQL
  stored procedures, template.ts, localization.
  USE when the request mentions A2v10, model.json, view.vxaml (or view.xaml), template.ts, an
  A2v10 endpoint, or files matching the A2v10 layout — including when it merely asks what A2v10
  is, what can be built with it, or how to start. Do NOT use for generic
  SQL, XAML, or TypeScript unrelated to A2v10.
---

# A2v10 Platform Skill

## 1. What A2v10 is

A2v10 is a **generic runtime**, like a web framework: it gives you *syntax*
(routing, file binding, the SQL↔runtime protocol) and **no domain semantics**.
Data access is **ONLY through stored procedures** — the platform never runs ad-hoc SQL.
What a `catalog`, an `Agent`, or an `edit` action *means* — and likewise schemas
(`cat/doc/jrn`), the element set, column sets, naming style — is defined entirely
by the app, never by the engine; they are *how most apps usually look*, not rules.
This file is the **syntax reference**. The app's *meaning* comes from the project,
not from here (see **§6 Workflow**).

**Localization** is a runtime-wide macro: the runtime replaces `@[Key]` with a localized value from the project's dictionaries. Details → `references/localization.md`.

## 2. Tooling

A read-only CLI named **`a2`** inspects a project for you — its config (`a2 app config` — tenancy, modules, …) and database (tables, columns, references), and it loads a view through the engine's own loader (`a2 view validate`), as JSON. It is the standard way to learn an existing project, and the tool that every *use the `a2` CLI to …* in this skill refers to. The command set grows over time.

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

**The same at the slot level: `$meta` → not yours.** `model: "$meta"` in `model.json` means the model — its shape and procedures — is built by another component, and any slot `a2 endpoint resolve-*` reports as `$meta` (a procedure, a view, a template) is built too, with no file behind it. Who builds it does not matter. Never replace `$meta` with a model name, never write a procedure, view or template for a `$meta` slot. Files declared in that `model.json` (`view:`, `template:`) are yours as always; the shape you bind them to comes from `resolve-*` (`cli.md`).

### An endpoint exposes renderables and callables

The elements come in two kinds:

| Kind | Sections | What it is |
|---|---|---|
| **Renderable** | `actions` (page), `dialogs` (modal), `popups` | Has UI: binds `view`+`template`, the runtime renders it, the user interacts and posts the model back. |
| **Callable** | `commands`, `reports` (printed forms & exports — see below), `files` | No UI: invoked, runs once, returns data / a file / an effect. |

*(Sections, their options and the bans that go with them → `references/model-json.md`.)*

**"Report" defaults to on-screen.** Bare *report* (звіт) means an **on-screen report** — an `action` that renders a `Sheet`: an interactive, filterable page (the common case). The `reports` *section* holds the other kind: a **fixed document the server builds** — a printed form (PDF) or an xml/json export. The axis is **what the thing is, not where it appears**: a printed form previewed on a form (`PdfReportViewer`) is still a `reports` element. Decision rule: the task names a printed form (друкована форма, print, PDF) → `references/print-form.md`; an export file (xml/json, download) → `reports` section (→ `references/model-json.md`); data the user filters and reads → on-screen report (→ `references/screen-report.md`).

**View/template (renderables) — declared.** `view:` / `template:` keys name the file explicitly; the path may be local (`edit.view`) or relative cross-folder (`../another/edit.view`).

**XAML file extension.** `.vxaml` and `.xaml` are identical content, but which one a project uses is fixed by its host — follow `XAML naming convention` (CLAUDE.md) for new files, and **never rename existing ones**: an older host may not understand `.vxaml`. The `view:`/`template:` key is **extension-less**.

**Procedure name — convention vs explicit.** Two ways an element binds its stored procedure — and a third, `model: "$meta"`, where nothing is derived and nothing is written: the procedure is built by another component (see *`$meta` → not yours* above).

- **`model` given → convention.** The runtime *derives* the name `<schema>.[<model>.<Verb>]` and calls it — you must create a proc with exactly that name. `schema`/`model` are declared at the top, **inherited**, **overridable** per element. The **Verb** is a derived role — *which* fire depends on what the element does (open → `Load`, save → `Update`, list → `Index`, …). Full verb set & proc templates → `references/sql-procedures.md`.
- **Named explicitly → nothing is derived.** You write the target yourself, and this lives **only in `commands`**: a `sql` command names its procedure in `procedure`; a `clr` command names a C# class in `clrType` and calls no procedure at all (→ `references/clr.md`).

**Verb ≠ Contract.** The **Verb** (or explicit name) is how the runtime *finds* the procedure. The **Contract** — its parameter shape (TVP) and result-set markers — is what it *returns*. Orthogonal: a proc found by the right verb still binds wrong if its Contract is off, and every procedure (derived or explicit) has a Contract.

**SQL ↔ runtime protocol.** Stored procedures return data via **result-set markers** — a naming grammar that binds proc output to the client model, with names agreeing across layers (TVP column = client property; marker ↔ `d.ts` ↔ XAML). Besides the sets that form the model, a procedure may return **system** sets (`$`-prefixed type token) that steer the processing rather than the shape. The grammar itself is writing-time detail → `references/sql-rules.md`.

**Some elements follow conventions.** Few, but real: where the engine treats names as free, certain (mostly client-side) elements assume a specific name/structure and **silently fail** without it. Catalog of these exceptions → `references/elem-conventions.md`; honor it.

## 4. Rules

### Must — break it and it does not work (engine contract)

- **The database is not yours — never connect to it yourself.** No DDL, no DML, not even `select`; with any tool, from any language, under any credentials you find — found credentials are not permission. The single door, by design: the read-only `a2` CLI (`a2 db …`). Applying SQL to a database is always the **user's** action — regenerate the bundle yourself (next bullet), then say *"apply `<outputFile>` to database `<database>` on `<server>`, and tell me when done"* — **all three resolved**, the path from `sql.json`, the other two from one `a2 db info` — and continue only after they confirm.
- **What you write is never what runs.** `.sql` fragments and `.template.ts` never reach their consumer as written: `sql.json` collects the fragments into `outputFile` (that file, not your `.sql`, is what gets applied to the database), and TypeScript compiles each `.ts` into the `.js` beside it (that file, not your `.ts`, is what the runtime loads). Add C# for a `clr` command and its assembly is a third output — loaded by the host from its own output at startup (→ `references/clr.md`). Everything else — xaml, `model.json`, `menu.json`, localization — is read live and takes effect on save. Touched a fragment or a `.ts` → build the csproj sitting beside `sql.json` (`dotnet build <that>.csproj`). **That project only** — you build the host once, at setup, and never again. The build is **yours**; applying the SQL stays the user's. Touched a `.cs` → the host must be rebuilt and restarted, and that is the **user's** step: ask them to rebuild and restart the app (Run in Visual Studio stops, rebuilds and starts it; `dotnet build` fails while it runs).
- Access data only through stored procedures; never raw SQL.
- Procedures must exist under the **exact** name — either the one the runtime **derives** from `model` (`<schema>.[<model>.<Verb>]`) or the one a `command` names **explicitly** (`procedure`). A misnamed proc is simply not found.
- Follow the result-set marker grammar; keep cross-layer names in agreement (TVP column = client property; marker ↔ d.ts ↔ XAML).

### Avoid — it works, but it's wrong (LLM traps)

These are things the engine *allows* and the model is *naturally pulled toward*. Resist them.

- **Do not retarget `model` per element.** The engine permits a per-element `model` override; treat it as a severe anti-pattern — one `model.json` = one `model`. Override only when there is genuinely no other way. **This governs *entity* endpoints** (catalog/document), where the elements are facets — `edit`/`index`/`copy` — of one entity. It does **not** apply to a `reports`/`commands` folder, which is a **collection of independent callables**: each report (or command) is its own thing, so a per-element `model` there is normal, not the anti-pattern. The grouping is the author's choice — many reports in one `model.json`, or one each.
- **Do not over-share views.** Default: one `view` + one `template` per model. Sharing them across models — and conditional rendering inside a shared view — is a *rare, deliberate* exception, justified explicitly. **Never** collapse many models into one view via `if`-branches to "save files."

**Broke and the cause isn't obvious?** Don't guess — go to the references for the layer you touched (and `references/troubleshooting.md`); they spell out what to verify and how.

## 5. Discipline — operator error, orthogonal to the engine

§4 is the engine's contract; this is *your* contract — the priors and copy-habits you bring. **Nothing checks your names** — the build only bundles SQL and compiles TypeScript (§4), it never looks at a binding — so none of these fail loudly. Code just silently doesn't bind, or quietly diverges.

- **Clone-and-mutate: copied is guilty until verified.** The workflow is example → clone → mutate, and the trap is carrying the donor's names into the new entity. After cloning, sweep **every** inherited name — markers, TVP columns, d.ts properties, XAML bindings, proc body, comments — against the new entity. Cross-layer names must agree (§4); a clone is exactly where they silently stop.
- **Mojibake instead of Cyrillic means the file is not UTF-8 — its content never reached you.** `Ð¿Ñ€Ð¸`, `?????`, `���` where words belong: the bytes were decoded wrong, and the text is unrecoverable from what you hold. **Do not edit that file and do not write it back** — saving makes the corruption permanent. Tell the user to re-save `<path>` as UTF-8, wait, **re-read it**, then continue. Never convert it yourself.
- **Every platform file you write from scratch starts with `U+FEFF` — that character is the BOM.** `.sql`, `.vxaml`, `.ts`, `.json`, `.cs`, localization `.txt`. **`.md` files carry no BOM** (`CLAUDE.md`, `DOMAIN.md`, READMEs) — parsers that expect a leading marker, YAML frontmatter first of all, break on it. The split is by file kind, so there is never a per-file question.
- **Comments are load-bearing — true-or-delete.** A stale comment is cloned with the code and propagates, so fix or cut it, never leave a wrong one. Site-local invariants and "don't do X here" → a comment at the site; cross-cutting meaning → the project docs — `CLAUDE.md` (skeleton) or `DOMAIN.md` (per-entity), per `semantic.md`. A comment on a seam is part of the contract, not optional prose.
- **Don't invent platform surface.** Not in the references or an existing example → it does not exist. The surface is small and names are free — which tempts confabulated keys, markers, attributes. Go to the docs or ask; never invent. **Recalling what a doc page says is inventing too — open the page, or don't cite it.** Open it with `curl` and read the text — never WebFetch: it hands back a summary of the page, not the page. **In a view you can settle it: `a2 view validate <view-file>`** (the file `view:` names — `catalog/agent/index.view`, not the element name) instantiates the file the way the server will and names an invented element, property or enum value instead of dropping it silently. Run it on every view you write or edit — no database needed. It does **not** check binds against the model (`cli.md`), so the rule still holds everywhere else.
- **Don't carry framework priors.** A2v10 is not MVC/ORM. Resist the pull toward ad-hoc SQL, an ORM, migrations — data is **only** through procedures, files interpreted live. What you "know" from Rails/Django/EF is wrong here.
- **The platform honors some behavioral priors for you — don't hand-roll them, don't invent them.** The runtime handles certain robustness defaults itself (→ `references/platform-behavior.md`); against those, defensive scaffolding is duplication, not safety. But **whether** it handles a given case is a platform fact — read the catalogue or ask; never infer "I must defend against X" from a generic prior. Reaching for defensive wrapping by default is the tell you're reasoning from priors, not the platform.
- **Reuse before create.** Before adding a localization key, a base proc, a shared template — check it doesn't already exist. A second way to do one thing is the defect, not a feature.
- **Don't build knowledge ahead of need.** No nameable consumer → don't create it; derivable on touch → don't store it.

## 6. Workflow

**First — is there work in the turn?** *What is A2v10 / what can I build / where do I start* is a
question, not a task → **orientation**, `references/intro.md`: answer, write nothing, start no
setup. An action named (create / add / fix / build …) is a task → continue. Ambiguous → question.

1. **CLAUDE.md carries A2v10 state** — a `## Platform` section naming A2v10 → read it (and glance at `DOMAIN.md`): it carries the project's state and routing — a bare app's `## Semantics` stub routes its first domain task itself (→ `references/new-semantic.md`). Work the task → §7 Dispatch.
2. **It does not** — no `CLAUDE.md`, or one that is not ours (a generic file, another agent's) → **onboarding, exactly once.** The fork is exclusive, on one check: **is there a `model.json` anywhere in the tree?** (the platform's defining marker — §3):
   - **absent** → new project → `references/new-project.md`
   - **present** → existing project → `references/existing-project.md`

   Both end with the A2v10 sections in `CLAUDE.md` and `DOMAIN.md` written — **append to an existing file, never overwrite it** — after that, only path 1 ever runs.

Unsure → ask; never guess.

## 7. Dispatch — find the task

Each row is an action you take. The kind (catalog / document / journal / …) is **semantics**, not a routing axis — it is read in two parts: *which* kind an entity is, from its `DOMAIN.md` entry; what that kind *means* (schema, columns, verbs, views), from `CLAUDE.md` `## Semantics` where the project differs, otherwise from this skill's defaults.

**Create an endpoint** (from an existing table / from scratch) → `references/semantic.md` (per-kind patterns → the donor example)

**Wire app navigation (system menu)** → `references/menu.md`

**Update the platform** (CLI + package pins to the current generation) → `references/update-platform.md`

**Within an endpoint:**

| Action | Go to |
|---|---|
| add a field | `references/add-field.md` |
| edit the view | `references/xaml.md` |
| edit the template | `references/template.md` |
| edit a procedure | `references/sql-procedures.md` (verb/structure) + `references/sql-rules.md` (result-set markers) |
| add an on-screen report (Sheet page) | `references/screen-report.md` |
| add a printed form (PDF) | `references/print-form.md` |
| add an xml/json export / a command | `references/model-json.md` |
| call an external API / integration from a command (C#) | `references/clr.md` |
| add a dialog | `references/model-json.md` + `references/xaml.md` + `references/sql-procedures.md` — Renderable: declare it, then build its view + template + proc |

**No row matches?** Don't force-fit. Route by the layer you touch (SQL → `sql-rules.md` / `sql-procedures.md`, view → `xaml.md`, behavior → `template.md`, config → `model-json.md`). Capabilities none cover → full docs: https://docs-llm.a2v10.com . Still unclear → ask.
