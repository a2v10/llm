---
name: a2v10meta
description: >
  A2v10 endpoints declared in metadata.json (catalog, document, journal,
  report) and deployed with the a2 CLI.
  USE if the project contains metadata.json files, or the request mentions
  metadata.json, metaendpoint, metadata-driven, or a2 meta.
  ALSO USE, ahead of the a2v10 skill (it matches the same request on the
  word A2v10), when asked to create or start a new A2v10 application and
  the folder has no model.json and no metadata.json yet, unless the request
  already says classic: this skill asks whether metadata-driven or classic;
  classic then hands off to the a2v10 skill.
  Endpoint folder without metadata.json: a2v10 skill.
---

# A2v10 Metadata-Driven Skill

## 1. What a metaendpoint is

Every A2v10 application is metadata-driven. A **metaendpoint** is an endpoint declared by its `metadata.json`: the platform generates schema, behavior and forms from that file.

**The marker is `metadata.json` in the endpoint folder.** Present → this skill; it is the only entity here. Absent → not a metaendpoint, not ours. No flag inside any file.

Absence decides because it has exactly one meaning: an endpoint folder is never without one (§4). Nothing is inferred from the other files in the folder — whatever else lies there is a materialization question, not an ownership one → `references/materialize.md`.

The engine does not distinguish endpoint types: the distinction is ours, and it exists to route between the two skills without asking.

## 2. Tooling

One CLI, **`a2`**, in the form `a2 <object> <action>`: it reads the project and applies metadata to the database. Whether an application is metadata-driven at all is its answer too, not a file in the repository. → `references/cli.md`

## 3. Mechanics

An endpoint is **one model** — one business entity the engine processes as a single unit, backed by one or more related tables. A document with its rows is one endpoint, not two; that is why addressing stops at the endpoint and never reaches inside.

- **URL = `/[$<module>]/<kind>/<endpoint>/<action>/<id>`** — the platform's addressing model: `/document/waybillin/edit/2222`, or `/$admin/document/waybillin/edit/2222` inside a module.
- **`$<module>`** (optional) relocates the path's root — a `$`-prefixed segment is the one thing the runtime interprets. Modules and their roots come from `a2 app config`.
- **`<kind>/<endpoint>`** locates the folder. For a raw endpoint both segments are opaque — free names the runtime does not read. **For us the first one is neither free nor opaque**: `kind` is the parent folder name (`catalog/agent/` → `catalog`), it comes from a fixed set, and it is **interpreted** — it decides what gets generated. → `references/kinds.md`. Other first segments are possible in an application; they are not ours — pay them no attention.
- **Endpoint** = a `<kind>/` subfolder. → `references/metadata.md`
- **`<action>` and `<id>` are never authored.** For a raw endpoint an action is an element name, freely declared. For a metaendpoint the set is **fixed and interpreted** by the runtime (`index`, `edit`, …) and declared nowhere — you will not find it in `metadata.json`, and there is nothing to add there. The names surface in exactly one place: `model.json`, and only for an artifact that has been materialized → `references/materialize.md`. **What you ever write is `/<kind>/<endpoint>`** — in the menu, in a link, everywhere.

## 4. Must — break it and it does not work

- **The schema is converged, never edited.** It comes from `metadata.json` through `a2 meta deploy` — the same sequence the runtime runs. Do not write DDL to fix it: a change made by hand is invisible to the deploy hash, so the drift is silent and stays. What deploy will not do by itself — drops, narrowing, renames, changes to data — is proposed in `diff.sql` or written as a data migration, and **the author applies it**. → `references/deploy_and_migrations.md`
- **Generated files are products, not sources.** `deploydatabase.sql` is regenerated from the metadata byte for byte; an edit inside it is gone on the next deploy. `diff.sql` is a proposal — never execute it as part of a task.
- **A `<kind>/` subfolder without `metadata.json`, or with `{}`, is an error.** Legacy endpoints live in the classic layout, never under a `<kind>/`.
- **Every `metadata.json` says where its shape comes from, explicitly.** One axis, three keys: `table` — its own table; `storage` — a table declared elsewhere that it writes into; `surface` — a shape it only reads. **The folder decides which of them is legal** (`document` — one of `table`/`storage`; `report` — `surface`; everything else — `table`), **the file decides which one is used**. No defaults, never two, never none. → `references/metadata.md`, checks → `references/validate.md`
- **An operation owns no table, therefore declares no structure** — only behavior. It is not a rule to remember: an operation is the file that wrote `storage` instead of `table`.

## 5. Discipline — orthogonal to the engine

§4 is the engine's contract; this one is yours. Nothing here fails loudly — a metaendpoint that renders proves only that it rendered.

- **Do not invent surface.** An unknown key is not rejected: the loader drops it silently, so a misspelled or invented key gives no error and no effect — the endpoint works, your rule is simply not there. Not in `references/`, not in an existing `metadata.json` → it does not exist. What is caught before deploy, and what is not → `references/validate.md`.
- **Two markers in `references/`, and they say different things.** 🟡 — the decision is provisional; the form may still change. 🚧 — the form is settled and **the platform does not execute it yet**. A 🚧 surface is written down so the decision is not taken twice, not so it can be used: never put it in a `metadata.json`. Say which construct is missing and stop there — the norm names no substitute, and one improvised in its place is invented surface (above).
- **An endpoint with no files of its own is finished, not unfinished.** Every scaffolder you have ever seen generates once and lets go, so a folder holding only a `metadata.json` reads as a draft and invites XAML or SQL "so that something is there". A file exists **only** because that artifact was ejected on purpose; a file with nothing behind it is an error, not a spare. → `references/materialize.md`
- **Declared is not reachable.** The rule above is about the files inside the folder; this one is about the application around it. An endpoint no `menu.json` item names loses its **own entrance**, not its existence — a catalog still opens in a Ref lookup, and records are still created there — but nothing leads the user to its register, and nothing says so: deploy succeeds, validation passes, the URL works when typed by hand. Every endpoint you declare, you also place → `references/menu.md`.
- **An operation file does not describe its entity completely, and must not try.** Every file you have seen elsewhere is self-contained, so repeating `fields` from the storage will feel like completeness. Those keys are read by nobody and reported by nothing: the endpoint works, and the copy quietly rots next to the original.
- **Do not carry priors from 1C, Frappe or an ORM.** This format splits what they merge, and the merged reading drifts back under pressure.

## 6. Workflow

1. **The project has a `CLAUDE.md`** → read it first, before any action. What it fixes, do not ask again.
2. **No `CLAUDE.md`** → onboarding, exactly once → `references/onboarding.md`. It forks there on one check — **are any endpoints already declared?** — because an application that exists must never have the shell written over it.

   **Open the project with `a2 app config`, never with the file tree** — it is what says where the files go (`hostRoot`, `modules`). Reading that off the tree is guessing.

Unsure → ask; never guess.

## 7. Dispatch — find the task

| Action | Go to |
|---|---|
| create an application — the user has not said metadata-driven or classic → ask; classic → the `a2v10` skill | `references/onboarding.md` |
| create an endpoint — which kind is it | `references/kinds.md` → `references/metadata.md` |
| add or change a field | `references/metadata.md` |
| set initial values, or how a reference is picked | `references/metadata.md` |
| turn on a trait | `references/metadata.md` |
| make a field required, conditional, computed, inherited | `references/rules.md` |
| add an operation to a document family | `references/metadata.md` |
| make an operation post into a journal | `references/metadata.md` → `references/journal.md` |
| declare what a journal stores | `references/journal.md` |
| number documents with a series | `references/kinds.md` → `references/metadata.md` |
| declare a chart of accounts | `references/accplan.md` |
| declare a ledger, make a document post double-entry | `references/ledger.md` |
| declare a report over a journal | `references/report.md` |
| attach a print blank to an endpoint | `references/print.md` |
| lay out a form | `references/forms.md` |
| eject / materialize | `references/materialize.md` |
| apply metadata to the database, plan a migration | `references/deploy_and_migrations.md` |
| wire app navigation | `references/menu.md` |
| restrict access — declare roles, grant verbs, hide a menu item | `references/permissions.md` — 🚧 the whole subsystem; read it before promising anything |
| add or change localization keys | `references/localization.md` |
| check metadata before deploying | `references/validate.md` — 🚧 the command does not exist yet |
| build the application and bring up its database | `references/onboarding.md` → Phase 3 |
| call the CLI, read its output | `references/cli.md` |

**No row matches?** Do not force-fit. Route by what you are declaring: the shape of a record → `references/metadata.md`; a rule tying its fields together → `references/rules.md`; what it looks like on screen → `references/forms.md`. Still unclear → ask.

**Materialized artifacts** — XAML, SQL, `template.ts` — are written in the **`a2v10`** skill's formats; their syntax is that skill's job, not this one's. Which artifact is materialized at all is stated in `model.json` → `references/materialize.md`.

