# Update the platform

The user asked to bring the application to the platform version this skill is written against.

## 1. The CLI first

```
dotnet tool update --global A2v10.CLI
```

`a2 view validate` loads a view through the engine the **CLI** carries — a stale CLI validates
against the wrong engine. Failed (no network, no SDK) → say so and continue; nothing below needs it.

## 2. The scaffold is the reference

The scaffold in this skill pins the versions this skill is written against. It ships with the
skill, so there is no version number to look up anywhere else. Count every `PackageReference`
whose id starts with `A2v10.`; they sit in more than one project (`scaffold/WebApp`,
`scaffold/MainApp`) and do **not** all carry the same version, so go package by package.

Versions are what moves. A package the app references and the scaffold does not → leave it alone.
A package the scaffold pins and the app does not reference → do not add it — **except
`A2v10.CheckUpdates`: add it** at the scaffold's version, where the scaffold has it — the app's
`MainApp` counterpart (the module csproj, never the host's). It is the build warning that tells this
app a newer generation exists; without it the app goes stale without a sign.

## 3. Below → raise. Above → the skill is stale.

- **Below the scaffold** → set the app's version to the scaffold's.
- **Above the scaffold, any single package** → change nothing at all, in any project. The
  application is newer than this skill, so the scaffold is not the current generation and nothing
  here is an upgrade. Say so, tell the user to update the skill, and stop.

## 4. The key type — `dbo.platformid`

The platform script needs `dbo.platformid` — the type of the application's keys — declared before
it; without it the apply of `full.sql` stops at its first statement. The app's main module has no
`_sql/platformid.sql` → copy `scaffold/MainApp/_sql/platformid.sql` there, set the type to the
app's PK type (`bigint` | `int` | `uniqueidentifier`, read with `a2 db`), and put it **first** in
`inputFiles` of the host's `sql.json` — as in `scaffold/WebApp/sql.json`. Declared once for the life
of the database: an existing `platformid.sql` is never edited.

## 5. The user rebuilds

Editing pins restarts nothing. Finish by naming what changed and asking the user to rebuild and
restart the application — the host is never yours to build (SKILL.md §4).
