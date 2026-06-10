# Existing project — discover the semantics

**Guard — confirm there is an app first.** No `model.json` anywhere in the tree → there is no
A2v10 app here yet; this is the *new-project* path (SKILL.md §6 → `new-project.md`), not this one.
Do not proceed — discovery has nothing to read.

The app already embodies its semantics; **discover and record, never invent.** You are not its
author — every reconstructed fact is a belief about someone else's code until an artifact confirms
it. Two outputs: the **skeleton** → `CLAUDE.md`; an **empty `DOMAIN.md`** that grows on touch
(format → `semantic.md`).

**Semantics lives in the DB**, not in the endpoints. The DB names entities by meaning, encodes kind
in the schema (`cat`/`doc`/`jrn`), and states relations as FKs — read meaning from there. Endpoints
are only the *exposed surface* (what is used, and the path); the link endpoint↔table is **indirect**
(heuristic, then a procedure body) and is recovered per entity on touch, never in bulk.

## Cheap vs deep — the 90/10 line

**Front-load only what the skeleton consumes** (a handful of cheap calls). Cheap alone doesn't qualify — `a2 endpoint list` is cheap too, but setup consumes nothing from it; it serves task time:

- `a2 app config` — `multiTenant` + `modules`; scope discovery to modules with `root != null`.
- `a2 db tables` — which schemas are in use; sample a few tables for the conventions.

**Depth is per entity, on touch — never bulk.** Do **not** `resolve` 150–200 endpoints or read their
procedures up front: that is the context bomb, ROI ~199:1 (you'd pre-load 199 entities to use one).
A typical task touches one entity; pull its depth then. Depth = `resolve-* <endpoint> <name>` → procedure names →
read the named procedure (the **authoritative** table + the residue) → `db table-columns` (`ref` = FK).

## 1. Skeleton → `CLAUDE.md` (once, cheap)

- **`app config`** → `multiTenant` (tenancy dimension), `hostRoot` (the host folder's real name),
  `modules` (routing + where source lives).
  Domain lives in the module(s) with `root != null`; `root: null` modules are platform/system — out of scope.
  The `hostRoot` folder is not a module — never write endpoints there.
- **`db tables`** → which schemas are present = the **kinds in use**. Sample a few `table-columns`
  → `idType`, the standard-column set, naming (table/model spelling). Record the **reality, including
  where the app breaks a convention.**
- **XAML extension** — ask the user (`.vxaml` for VS-2026, else `.xaml`; they may be mid-migration).
  Record as `XAML naming convention` — that line governs which extension new files get.
- Write the skeleton from the template below — every `<...>` is a discovered value, not a token to
  leave in place. `## Semantics` holds the discovered reality: the kinds in use and any deviation
  from defaults (per `semantic.md`: record only what departs, don't restate defaults).
  Non-derivable or conflicting dimensions → **propose → approve**, pointwise (only what the CLI can't plainly
  answer; don't ask what it can).

````markdown
# CLAUDE.md — <AppName>

## Platform

Built on **A2v10** — always use the `a2v10` skill when working with this project.
Per-entity domain knowledge lives in `DOMAIN.md`.

XAML naming convention: <.vxaml | .xaml — as the user answered>

## Semantics

<one line on what the app is; the kinds in use and each kind's role; deviations from defaults>

## Project structure

```
<project root>/
  <module root>/  — A2v10 application (model.json, xaml, sql, ts); one line per module
  <hostRoot>/     — ASP.NET Core host
```
````

## 2. `DOMAIN.md` — created empty, grows on touch

Create `DOMAIN.md` with this header and **no entries**:

````markdown
# DOMAIN.md — <AppName> domain registry

One entry per entity (format → `semantic.md`). Empty until an entity is touched.
````
Do not pre-build an entity index: everything a bulk pass could record is either derivable on touch
(`endpoint list`, `db tables`, the procedure body) or a guess — neither is stored (SKILL.md §5).
An empty registry over a built app is the normal state, not a gap.

## 3. Hand back — knowledge comes on touch

Setup is over once the skeleton is written and the empty `DOMAIN.md` exists. Tell the user, in
substance: *"Conventions, tenancy, modules and kinds are recorded; domain knowledge will accrete
in `DOMAIN.md` as we touch entities."* Then return to the normal workflow (SKILL.md §6).

Each entity is afterward a normal **Dispatch** task. The first touch (via `new-endpoint.md` /
`add-field.md` / etc.) reads the procedure — the **authoritative** table binding plus the residue —
fills `depends on` from `table-columns` `ref`, and writes the entry **`confirmed at <path>`**.
That touch-time read is the single act that turns surface into knowledge — there is no separate
discovery or verification pass.

> Navigation: an existing project may drive the menu from the legacy `a2ui.Menu` table — to move it to
> `menu.json`, see `menu-migration.md`.
