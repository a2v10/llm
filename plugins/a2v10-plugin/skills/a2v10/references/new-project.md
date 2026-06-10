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
- "An app **for** <warehouse / CRM / todo>" → **for a domain** (§4 → `new-semantic.md`, after scaffold).
- Purpose named but too vague to build ("an app for accounting") → ask what it is for; a
  domain you can't name you can't model. Resolve it, then treat as *for a domain*.

This single call decides whether you stop at the shell or go on to fill it. Both cases
scaffold first.

## 2. Build the infrastructure (scaffold)

**Target must be greenfield.** If a `model.json` already exists anywhere in the tree — the
platform's defining marker — stop: an A2v10 app is already here, so this is the *existing-project*
path (SKILL.md §6 → `existing-project.md`), not this one. Otherwise scaffold into an empty
directory: the current one if empty, else a new `<AppName>/`. Never scaffold over existing files.

The scaffold (`scaffold/` in this skill) is a bare, runnable A2v10 app — no demo entities,
no `.md` files:

- `WebApp/` — ASP.NET Core host
- `MainApp/` — application source root (`model.json`, xaml, sql, ts)
- `AppName.slnx` — Visual Studio solution (both projects)

Copy the whole `scaffold/` tree into the new project's directory, then replace every
placeholder across the copied files:

- `^AppName^` — application name (ask the user)
- `^Year^` — current year

They appear in `WebApp/appsettings.json` — sweep the copied tree and replace **all** occurrences.

> Notation in this file: `^Name^` is a literal token in the scaffold files — replace it.
> `<Name>` stands for the resolved value (e.g. the chosen app name), not a token to leave
> in place.

**Solution file `AppName.slnx`.** The `.slnx` format is a plain XML list of the two
projects — no GUIDs, no per-config sections, nothing to fill in. Ships as plain
`AppName.slnx` (no carets — the skill loader forbids `^` in filenames); just **rename the
file** `AppName.slnx` → `<AppName>.slnx`.

Bring the shell up:

1. `dotnet build <AppName>.slnx` — compiles and generates `MainApp/_sqlscripts/main.sql`.
2. Hand the database to the user: *"create the database `<AppName>`, apply
   `MainApp/_sqlscripts/main.sql`, and tell me when it's done."* The database name and server
   live in the `Default` connection string in `WebApp/appsettings.json` — point the user there
   to adjust `Server=` if theirs isn't `localhost`. How they create and apply it is their
   business — the database is never yours to touch (SKILL.md §4: the only door is `a2 db`).

Any `dotnet build` failure (compile error, missing SDK): stop and report it — don't improvise
fixes, downgrade the framework, or hand-edit the generated SQL.

The solution builds and the user has confirmed the database — the shell is runnable, but **you
don't run it**. Starting the host is the user's job, in their own environment (Visual Studio, or
however they run the app), where they can see and stop it.

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

## Semantics

<!-- No domain yet. The first task that names one: determine the semantics first —
     a2v10 skill, references/new-semantic.md — then work the task. -->

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
`CLAUDE.md` and the entities (each `planned`) in `DOMAIN.md`, and returns you to the
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
