# How to add a new endpoint to an existing entity

Step-by-step checklist for a focused create  a single endpoint.

## Where the folder lives

An endpoint is a folder with `model.json`. Its location depends on the module — run `a2 app config` first to get each module's `prefix` and `root` (see `cli.md`):

- **Main app** (`prefix: ""`) → `<root>/<path>/`, e.g. `MainApp/catalog/agent/`.
- **A module** (`prefix: "$x"`) → `<root>/<path>/` under that module's `root`; the endpoint's URL then carries the prefix: `/$x/<path>/<action>/<id>`.
- **`root: null`** → no local folder exists; you cannot add an endpoint there.

## Make it reachable

The endpoint works by its URL the moment it exists. To surface it in the app's navigation, add an entry to `menu.json` — a separate task, see `references/menu.md`.

## Record it in DOMAIN.md

**Before building** — read the entity's `DOMAIN.md` entry and those of its `depends on`; for any already `Implemented`, read its built schema (`a2` CLI) and build against real columns/keys, not invented. Order is free (FK → `keys.sql` after all tables): a not-yet-built or cyclic dependency never blocks — reference its `Id`.

**After building** — flip the entry's state line to `Implemented at <path>`, fill role, relationships, invariants, "don't do X" — **residue only**. Confirm with the user. Format → `semantic.md`.



