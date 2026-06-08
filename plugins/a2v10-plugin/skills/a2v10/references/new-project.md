# New project — scaffold first, then semantics

A new A2v10 project has **no semantics yet** — only a runnable shell. You create
that shell by copying the scaffold, **then** build the semantics on top of it.
Order matters: scaffold → semantics → endpoints.

## 1. Copy the scaffold

The scaffold (`scaffold/` in this skill) is a bare, runnable A2v10 app — no demo
entities, no `.md` files:

- `WebApp/` — ASP.NET Core host
- `MainApp/` — application source root (`model.json`, xaml, sql, ts)
- `setup-db.ps1` — database bootstrap
- `AppName.slnx` — Visual Studio solution (both projects)

Copy the whole `scaffold/` tree into the new project's directory, then replace
every placeholder across the copied files:

- `^AppName^` — application name (ask the user)
- `^Year^` — current year

They appear in `WebApp/appsettings.json`, `setup-db.ps1`, and elsewhere — replace
**all** occurrences.

> Notation in this file: `^Name^` is a literal token in the scaffold files —
> replace it. `<Name>` stands for the resolved value (e.g. the chosen app name),
> not a token to leave in place.

**Solution file `AppName.slnx`.** The `.slnx` format is a plain XML list of the two
projects — no GUIDs, no per-config sections, nothing to fill in. Ships as plain
`AppName.slnx` (no carets — the skill loader forbids `^` in filenames); just
**rename the file** `AppName.slnx` → `<AppName>.slnx`.

The scaffold ships **no `CLAUDE.md`** — it comes later (§3), once there is meaning
to record. Bring the shell up:

1. `dotnet build <AppName>.slnx` — compiles and generates `MainApp/_sqlscripts/main.sql`.
2. `./setup-db.ps1` — creates the database and applies that script.

If step 2 prints `Failed. Check SQL Server connection`, `setup-db.ps1` could not
reach SQL Server at `localhost` — the instance it hardcodes. **Stop and hand this
back to the user.** Do not probe for instances, do not switch to a named instance
or LocalDB, and never install SQL Server. The scaffold ships `localhost`; only the
user knows their actual instance. Tell them to replace the server name in **two
places** and rerun:

- `$server` in `setup-db.ps1` (line 5)
- `Server=...` in `WebApp/appsettings.json` (the `Default` connection string)

Both must match — `setup-db.ps1` creates the database, `appsettings.json` is how
the running app reaches it. Tell the user too: if a user-secrets file
(`secrets.json`) defines the `Default` connection string, the running app picks it
up and it **overrides** `appsettings.json` — so the server name has to be fixed
there as well, or the app keeps hitting the old instance no matter what
`appsettings.json` says.

**The user may opt out of DB access entirely.** They can say *"don't touch the DB,
I'll run everything myself — just tell me what."* This is a normal setup, e.g. the
database lives on a remote machine reachable only through a connection string kept
in `secrets.json` (which you never see) — every direct DB operation would just fail
anyway. When the user says this: record it in `CLAUDE.md` (a `Database` note under
Platform — *"DB is user-managed; never run setup-db.ps1, sqlcmd, migrations, or any
direct DB command — output the SQL/commands for the user to run"*) and from then on
**never** attempt a direct DB operation. Build, generate the SQL, hand the user the
exact script or command to run, and stop.

Setup ends here. The solution builds and the database is ready — the shell is runnable, 
but you don't run it. Starting the host is the user's job, in their own environment 
(Visual Studio, or however they run the app), where they can see and stop it.

Do not run it yourself. dotnet run is a long-lived process: 
in the foreground it hangs your turn; backgrounded it becomes an orphan the user can't see — it holds the port and locks the build DLLs, and you'll end up hunting it down by PID just to unblock the next build. 
Build, set up the DB, tell the user it's ready, and hand off.

## 2. Build the semantics

The shell runs but means nothing. **Semantics — what this app *is*** — is the one
thing the engine never supplies (SKILL.md §1); you build it now, before any
endpoint. This is a design act, not a default to pick. Two moves:

1. **Understand the application.** The user brought an *app*, not a table — a
   warehouse, a CRM, a todo-list. The archetype is usually already in their
   request: restate it and the entity landscape you infer, and ask only where it
   is genuinely unclear. Don't interrogate from scratch.

2. **Derive the kind-system.** Take the app's core entities and classify each by
   what it *does* — a flat reference list → **catalog**, a header+rows event that
   posts → **document**, an accumulating balance → **journal**. Those roles are
   exactly how `semantic.md` describes the kinds; use its per-kind patterns as the
   **classifier**, not a template to stamp. Derive the **minimal** kind-system the
   app's purpose needs — don't summon journals/posting a simple tracker never uses
   (an over-built kind-system is a symptom, not thoroughness). cat/doc/jrn is a
   starting vocabulary to adapt, never a rule.

These two — the app's identity and its kind-system — are the decisions §3 records.
Individual entities **within** each kind are not decided here; they accrete later,
as you add endpoints.

## 3. Create CLAUDE.md

Semantics is decided — now create the project's source-of-truth doc at the root,
Semantics already filled from §2. It is what every later task reads (SKILL.md §5):

````markdown
# CLAUDE.md — <AppName>

## Platform

Built on **A2v10** — always use the `a2v10` skill when working with this project.

XAML naming convention: `.vxaml`

<!-- If the user opted out of DB access (§1), add a Database line here:
     "DB is user-managed; never run setup-db.ps1/sqlcmd/migrations — output SQL for the user." -->


## Semantics

<!-- Identity + kind-system, decided in §2. Conventions (idType, naming, standard
     columns) take their defaults — record here only a departure from them. -->
<one line on what the app is; the kinds in use and each kind's role>

## Project structure

```
<AppName>/
  MainApp/   — A2v10 application (model.json, xaml, sql, ts)
  WebApp/    — ASP.NET Core host
```

## Implemented

- [ ] (none yet)
````

## 4. Conventions

idType, naming (table/model spelling, constraint patterns) and the per-kind
standard columns are **not semantic decisions** — they are conventions applied
silently from their defaults, no dialogue. (Multi-tenancy is rare enough in new
projects to ignore until one actually needs it; the scaffold ships single-tenant.)
Defaults live in `sql-discipline.md` (naming, constraints) and `semantic.md`
(standard columns).

**XAML extension** is the one convention recorded explicitly (the `XAML naming
convention` line above): new projects default to `.vxaml` and the scaffold already
ships `.vxaml`. If the user is on an IDE older than VS-2026, change the line to
`.xaml` and rename the scaffold's XAML files to match.

## Done — back to the workflow, start creating endpoints

The shell runs and the semantics are recorded in `CLAUDE.md`. Setup is complete and
runs only once: the project is now a normal A2v10 app. Hand back to the workflow
(SKILL.md §5) — every task from here, the first endpoint included, goes through §6
Dispatch like any other. Building that first endpoint is the obvious next move.
