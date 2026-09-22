# Onboarding — from a request to a running application

Reached from `SKILL.md` §6 when the project has no `CLAUDE.md`. It ends with `CLAUDE.md` written; from then on every session takes step 1 of the workflow instead and never comes back here.

## Which way this goes — one check

**Are any endpoints already declared?** A `<kind>/` subfolder with a `metadata.json` in it, under a module root from `a2 app config`.

- **none** → **a new application.** Everything below applies as written.
- **some** → **an application that exists and was simply never recorded.** Nothing is being created: **do not copy `scaffold/`, do not touch a declaration that is already there.** Missing are `CLAUDE.md` and `DOMAIN.md`, and nothing else.

A missing `CLAUDE.md` says nothing about whether the application exists — it is written by this file and by nobody else, so an application built by hand has never had one.

### When the application already exists

Phase 1 changes its subject: nothing is being designed, so nothing is proposed. Read the declarations and **state back what you understood** — what the application is for, what each entity is, which words the domain uses for them. The gate is the same single one: the user corrects that reading and agrees to it.

What the reading cannot recover is exactly what these two files are for. The declarations give the entities and their kinds; they do not give the purpose, the customer's vocabulary, the boundaries, or why anything was decided that way. Those come from the user, and asking for them is the whole conversation.

Then Phase 2, **steps 5 and 6 only** — `CLAUDE.md` and `DOMAIN.md`. Phase 3 is skipped: the application already runs, and deploying is a task of its own, on request.

## Two phases and one gate

Phase 1 is a conversation and writes **nothing** to disk. Phase 2 writes **everything**. Between them sits a single approval — on the domain structure, not on files. Once it is given, do not ask again: not per folder, not per entity, not per file.

## Phase 1 — agree the domain structure

**One question at the start.** A bare application, or an application *for* something?

- a purpose is named ("a warehouse", "stock tracking with reports") → continue here;
- no purpose ("just an A2v10 metaapplication") → go straight to Phase 2 and write the shell only, no endpoints;
- a purpose is named but too vague to model ("an app for accounting") → settle what it actually does first. A domain you cannot name you cannot classify.

**Propose the structure — do not interrogate.** The request already carries most of the answer. Restate the domain and lay out the entities you infer, each with its kind, and ask only where a choice genuinely changes the outcome. A list of questions here is the wrong move; a proposal the user corrects is the right one.

This step is **classification, not design** — the kind list is closed (`references/kinds.md`). Read the request against it:

- "приход, расход, перемещение" is **one document family with three operations**, not three documents: the family owns the storage, each operation owns its behavior;
- stock levels, balances, debts are a `journal` — never a table someone writes into directly;
- "отчёты" are `report` endpoints over a journal surface;
- everything that is just a list of things — goods, warehouses, units, counterparties — is a `catalog`.

Propose the **application name** here as well: it becomes the folder, the project and the database name.

**Then state the list once more, compactly, and wait.** That agreement is the gate.

## Phase 2 — write it

No further questions. In this order — and `examples/warehouse/` is what the result looks like when it is done: one declaration file per folder, nothing else.

1. **Shell.** Copy `scaffold/` into the project directory (`MainApp/`, `WebApp/`, `AppName.slnx`). Rename the solution file to `<AppName>.slnx`. Replace `{{AppName}}` in every copied file (`WebApp/appsettings.json`) and `{{Year}}` with the current year. The scaffold is already a metaapplication — the host carries the `A2v10.Metadata` package and registers `UseAppMetadata()`; nothing else is needed to make `metadataEnabled` true.

   **Then refresh the A2v10 package versions**, once, here — before anything is built. Six `PackageReference`s carry one: `A2v10.Platform`, `A2v10.Web.Assets`, `A2v10.ReportEngine.Pdf`, `A2v10.Metadata` in `WebApp/WebApp.csproj`; `A2v10.App.Assets2026`, `A2v10.Sql.MSBuild` in `MainApp/MainApp.csproj`. `Microsoft.TypeScript.MSBuild` stays as the scaffold has it.

   For each, `WebFetch` `https://azuresearch-usnc.nuget.org/query?q=packageid:<PackageId>&prerelease=false&take=1&semVerLevel=2.0.0` with the prompt *"Return only the value of data[0].version as a raw string, nothing else."* — the URL already filters prereleases — then `Edit` the `Version` attribute. Every package takes its own latest: **do not align them**, A2v10 versions drift apart and that is normal.

   Never `dotnet add package` or `dotnet restore`: the .NET SDK may be absent on this machine, and only `.csproj` text is being edited. NuGet unreachable → leave the scaffold's versions and say so in one line. Afterwards versions are the user's.

   **Then `MainApp/app.json`** — what is true of the application as a whole and no endpoint can state: `platformid` — the identifier base the database rests on, one of `bigint`, `int`, `uniqueidentifier`; write `bigint` unless the customer said otherwise. The platform has no default: the first deploy creates `dbo.platformid` from this value, afterwards the database is the fact and a different value fails the load. And `useGrants` (→ `references/permissions.md`). Leave `useGrants` off while the application is being written; turning it on demands a `grants` block in every addressable endpoint.
2. **Endpoints.** One folder per entity under its kind, one declaration file in each. Write them in dependency order — enums → catalogs → journals → autonum → documents (storage first, then operations) → reports — so that every `target` written points at something that already exists.
3. **Menu.** `MainApp/menu.json` — until an endpoint is named there, nothing leads the user to it. Its sections and their order come from the words the customer used; what goes in and what never does → `references/menu.md`. `appTitle` is set here too.
4. **Localization.** Generated screens are labeled with keys, not text — a field with `@[<FieldName>]`, an entity with `@[<Model>]` — so every field and entity that reaches a screen gets a line in `MainApp/_localization/_default.uk.txt`.
5. **`CLAUDE.md`** — the record of what was agreed (below).
6. **`DOMAIN.md`** — one entry per entity (below).

### `CLAUDE.md`

```markdown
# CLAUDE.md — <AppName>

## Platform

Metadata-driven **A2v10** application — always use the `a2v10meta` skill.
Per-entity domain knowledge lives in `DOMAIN.md`.

## What this app is for

<one paragraph, in the words the customer used>

## Vocabulary

<only where the customer's word differs from the entity name>

## Boundaries

<what this business does NOT do — "серийники не ведём", "партий нет">

## Decisions

<what was chosen and why, where it is not derivable from the files>

## Project structure

<AppName>/
  MainApp/   — the application (metadata, localization, sql)
  WebApp/    — ASP.NET Core host
```

**No platform nouns in this file.** A table, a column, a schema, a procedure name here means the line is misplaced: either it is the platform's business — and then it is invisible at this level — or it is a fact about one entity, and then it belongs to that entity's declaration.

### `DOMAIN.md`

One entry per entity: heading = entity + kind, second line = the endpoint folder, then the meaning.

```markdown
## Товары — catalog
catalog/item

Что храним и продаём. Партий и серий не ведём — остаток считаем по складу
и номенклатуре, глубже не режем.
```

No fields, no types, no columns: they live in the declaration, and a copy here rots. Write what the code cannot say — the role in the business, the invariants, what deliberately does not exist.

The folder line is what separates the two files: a statement about **one** entity has an address and goes here; a statement about the whole application has none and goes to `CLAUDE.md`.

## Phase 3 — bring it up

1. **Build** — `dotnet build WebApp`. The build generates `MainApp/_sqlscripts/main.sql`, the platform's own schema, from the package scripts `sql.json` names as `@sql/…`.
2. **Validate every endpoint you wrote** — `a2 meta list` gives the addresses, `a2 meta validate <endpoint>` assembles one of them and throws the result away. It writes nothing and reads no database, so it is the one gate that costs nothing and it belongs here, before anything is created: a declaration that does not assemble is found now, not by the user in a browser. One error per run — fix it and run the endpoint again. → `references/validate.md`
3. **Hand the database to the user** — creating it is theirs, not yours. Only after step 1: `main.sql` does not exist before the build. Tell them exactly two things: create an empty database `<AppName>` on the server from `ConnectionStrings.Default` in `WebApp/appsettings.json`; run `MainApp/_sqlscripts/main.sql` against it. Then wait until they say it is done.
4. **Deploy the metadata** — `a2 meta deploy` (→ `references/deploy_and_migrations.md`).
5. **Hand off.** Say it is ready and stop. **Do not run the application**: starting the host is the user's job, in their own environment, where they can see and stop it.

## Done

The shell builds, the database holds the platform schema plus the deployed metadata, every endpoint is reachable from the menu, `CLAUDE.md` and `DOMAIN.md` record what was agreed. Every entity afterwards is an ordinary Dispatch task (`SKILL.md` §7), each one reading `CLAUDE.md` first.
