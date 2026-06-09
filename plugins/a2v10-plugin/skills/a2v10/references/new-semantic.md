# New project — determine the semantics

Reached from `new-project.md` §4 once the shell is scaffolded and the request names a domain —
or later, when a bare app acquires a purpose. Here you decide what the app *is* and what it is
made of — a design act — record it, and hand back. **You do not build endpoints here.**

`semantic.md` defines *what* semantics consists of; this file is the procedure to *decide*
it for a new app.

## 1. Understand the application

The user brought an *app*, not a table — a warehouse, a CRM, a todo-list. The archetype is
usually already in the request: restate it and the entity landscape you infer, and ask only
where it is genuinely unclear. Don't interrogate from scratch.

## 2. Derive the kind-system

Classify the core entities by what each *does* — a flat reference list → **catalog**, a
header+rows event that posts → **document**, an accumulating balance → **journal**. Those
roles are exactly how `semantic.md` describes the kinds; use its per-kind patterns as the
**classifier**, not a template to stamp. Derive the **minimal** kind-system the purpose needs
— don't summon journals/posting a simple tracker never uses (an over-built kind-system is a
symptom, not thoroughness). cat/doc/jrn is a starting vocabulary to adapt, never a rule.

## 3. Determine the entities

List the **core entities** the purpose obviously needs, each tagged with its kind — for
warehouse tracking: goods (catalog), receipt/issue (documents), stock (journal). Core only;
the long tail accretes later. This list is the semantics made concrete: **one entity → one
future endpoint.** Restate it and confirm it with the user before recording — don't pad it
with tables nobody asked for.

Note each entity's `depends on` — the entities it actually references. Gives the build order
and the contracts to read (not invent). A real cycle is permitted — FK in `keys.sql` resolves
it; record it, don't break it. Only real references, not a free-for-all.

## 4. Record it

- **`CLAUDE.md`** — fill `## Semantics` with one line on what the app is, plus the kinds in use
  and each kind's role (the skeleton; use the `new-project.md` §3 template).
- **`DOMAIN.md`** — one entry per entity from §3 (name + kind + `depends on` + one-line role),
  each marked `To implement`. Format → `semantic.md`. These are the plan; creating an entity's
  endpoint flips its line to `Implemented at <path>` and fills its full meaning.

## 5. Hand back — do not build

**Do not start building endpoints.** Setup is over. Tell the user, in substance:

> *"I understand the app and its semantics are recorded — I'm ready to write. I suggest we
> fill the endpoints one at a time."*

Then return to the normal workflow (SKILL.md §6): each `To implement` entity is a separate
**Create an endpoint** task (§7 Dispatch), done one by one, each reading `CLAUDE.md` and
flipping its `DOMAIN.md` line to `Implemented at <path>`. Suggest an order that follows
`depends on` — entities that depend on nothing (the catalogs) first, their dependents after;
entities in a cycle in any order.

Building them in an unattended loop is the wrong move — one at a time keeps the user in control
and gives each entity proper attention.
