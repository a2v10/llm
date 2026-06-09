# New project — scaffold, then fill the domain if the request names one

A new A2v10 project starts as a bare runnable shell with no meaning. **Decide first**
which of two cases you are in:

- **Bare app** — the request asks only for an A2v10 application, no purpose ("create an
  A2v10 app"). Scaffold it and **stop**.
- **App for a domain** — the request names what the app is *for* ("an app for warehouse
  tracking"). Scaffold it, **then** determine its semantics and hand back to build endpoints
  one at a time.

Order is fixed: **classify → scaffold → bare? stop → otherwise determine the semantics, then
hand back.** Setup never builds endpoints.

## 1. Classify the request

Does the request name a purpose/domain?

- "An A2v10 app", "a blank A2v10 project" → **bare** (§3, stop).
- "An app **for** <warehouse / CRM / todo>" → **for a domain** (§4–§5 after scaffold).
- Purpose named but too vague to build ("an app for accounting") → ask what it is for; a
  domain you can't name you can't model. Resolve it, then treat as *for a domain*.

This single call decides whether you stop at the shell or go on to fill it. Both cases
scaffold first.

## 2. Build the infrastructure (scaffold)

**Target must be greenfield.** If the directory already holds an A2v10 app (`model.json`,
`MainApp/`), stop — that is the *existing-project* path (SKILL.md §6 → `existing-project.md`),
not this one. Otherwise scaffold into an empty directory: the current one if empty, else a new
`<AppName>/`. Never scaffold over existing files.

The scaffold (`scaffold/` in this skill) is a bare, runnable A2v10 app — no demo entities,
no `.md` files:

- `WebApp/` — ASP.NET Core host
- `MainApp/` — application source root (`model.json`, xaml, sql, ts)
- `setup-db.ps1` — database bootstrap
- `AppName.slnx` — Visual Studio solution (both projects)

Copy the whole `scaffold/` tree into the new project's directory, then replace every
placeholder across the copied files:

- `^AppName^` — application name (ask the user)
- `^Year^` — current year

They appear in `WebApp/appsettings.json`, `setup-db.ps1`, and elsewhere — replace **all**
occurrences.

> Notation in this file: `^Name^` is a literal token in the scaffold files — replace it.
> `<Name>` stands for the resolved value (e.g. the chosen app name), not a token to leave
> in place.

**Solution file `AppName.slnx`.** The `.slnx` format is a plain XML list of the two
projects — no GUIDs, no per-config sections, nothing to fill in. Ships as plain
`AppName.slnx` (no carets — the skill loader forbids `^` in filenames); just **rename the
file** `AppName.slnx` → `<AppName>.slnx`.

Bring the shell up:

1. `dotnet build <AppName>.slnx` — compiles and generates `MainApp/_sqlscripts/main.sql`.
2. `./setup-db.ps1` — creates the database and applies that script. Tell the user first: this
   **creates a database** on their SQL Server.

If step 2 prints `Failed. Check SQL Server connection`, `setup-db.ps1` could not reach SQL
Server at `localhost` — the instance it hardcodes. **Stop and hand this back to the user.**
Do not probe for instances, do not switch to a named instance or LocalDB, and never install
SQL Server. The scaffold ships `localhost`; only the user knows their actual instance. Tell
them to replace the server name in **two places** and rerun:

- `$server` in `setup-db.ps1` (line 5)
- `Server=...` in `WebApp/appsettings.json` (the `Default` connection string)

Both must match — `setup-db.ps1` creates the database, `appsettings.json` is how the running
app reaches it. Tell the user too: if a user-secrets file (`secrets.json`) defines the
`Default` connection string, the running app picks it up and it **overrides**
`appsettings.json` — so the server name has to be fixed there as well, or the app keeps
hitting the old instance no matter what `appsettings.json` says.

Any **other** `dotnet build` or `setup-db` failure (compile error, missing SDK, a different DB
error): stop and report it — don't improvise fixes, downgrade the framework, or hand-edit the
generated SQL.

**The user may opt out of DB access entirely.** They can say *"don't touch the DB, I'll run
everything myself — just tell me what."* This is a normal setup, e.g. the database lives on a
remote machine reachable only through a connection string kept in `secrets.json` (which you
never see) — every direct DB operation would just fail anyway. When the user says this: record
it in `CLAUDE.md` (a `Database` note under Platform — *"DB is user-managed; never run
setup-db.ps1, sqlcmd, migrations, or any direct DB command — output the SQL/commands for the
user to run"*) and from then on **never** attempt a direct DB operation. Build, generate the
SQL, hand the user the exact script or command to run, and stop.

The solution builds and the database is ready — the shell is runnable, but **you don't run
it**. Starting the host is the user's job, in their own environment (Visual Studio, or however
they run the app), where they can see and stop it.

Do not run it yourself. `dotnet run` is a long-lived process: in the foreground it hangs your
turn; backgrounded it becomes an orphan the user can't see — it holds the port and locks the
build DLLs, and you'll end up hunting it down by PID just to unblock the next build. Build, set
up the DB, tell the user it's ready, and hand off.

## 3. Bare app → minimal docs, then stop

No purpose was named, so there is **no domain to record and none to invent**. Create a minimal
`CLAUDE.md` and an empty `DOMAIN.md`, tell the user the shell is ready and ask what they want to
build, and **stop here**. When it later gets a purpose, run `new-semantic.md` to determine its
semantics — even though `CLAUDE.md` now exists.

````markdown
# CLAUDE.md — <AppName>

## Platform

Built on **A2v10** — always use the `a2v10` skill when working with this project.
Per-entity domain knowledge lives in `DOMAIN.md`.

XAML naming convention: `.vxaml`

<!-- If the user opted out of DB access (§2), add a Database line here:
     "DB is user-managed; never run setup-db.ps1/sqlcmd/migrations — output SQL for the user." -->

## Semantics

<!-- No domain yet — bare A2v10 shell. Identity + kind-system get filled when the app
     gets a purpose. -->

## Project structure

```
<AppName>/
  MainApp/   — A2v10 application (model.json, xaml, sql, ts)
  WebApp/    — ASP.NET Core host
```
````

````markdown
# DOMAIN.md — <AppName> domain registry

One entry per entity (format → `semantic.md`). Empty until the first endpoint.
````

**App for a domain → do not stop.** Skip to §4.

## 4. App for a domain → determine the semantics

Do **not** design entities or build endpoints here. Hand off to `references/new-semantic.md` —
it determines what the app is (kind-system + the core entity list), records the skeleton in
`CLAUDE.md` and the entities (each `To implement`) in `DOMAIN.md`, and returns you to the
normal workflow.
Endpoints are built afterward, one at a time, never in a setup loop.

## Conventions   *(both cases)*

idType, naming (table/model spelling, constraint patterns) and the per-kind standard columns are
**not semantic decisions** — they are conventions applied silently from their defaults, no
dialogue. (Multi-tenancy is rare enough in new projects to ignore until one actually needs it;
the scaffold ships single-tenant.) Defaults live in `sql-discipline.md` (naming, constraints) and
`semantic.md` (standard columns).

**XAML extension** — `.vxaml`, applied silently (the scaffold ships it; the `XAML naming
convention` line above records it). Change only if the user explicitly asks for `.xaml` (then
rename the scaffold's XAML files to match).

## Done

A **bare app** ends at §3 — a runnable shell, handed to the user, who says what to build next. An
**app for a domain** continues in `new-semantic.md` and ends there: semantics recorded, the user
invited to fill endpoints one by one. Either way **setup builds no domain endpoints** — every
endpoint is a normal SKILL.md §7 Dispatch task afterward, each reading `CLAUDE.md`.
