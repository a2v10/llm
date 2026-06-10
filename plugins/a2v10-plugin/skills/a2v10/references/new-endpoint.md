# How to add a new endpoint to an existing entity

Step-by-step checklist for a focused create  a single endpoint.

## Where the folder lives

An endpoint is a folder with `model.json`. Its location depends on the module — run `a2 app config` first to get each module's `prefix` and `root` (see `cli.md`):

- **Main app** (`prefix: ""`) → `<root>/<path>/`, e.g. `MainApp/catalog/agent/`.
- **A module** (`prefix: "$x"`) → `<root>/<path>/` under that module's `root`; the endpoint's URL then carries the prefix: `/$x/<path>/<action>/<id>`.
- **`root: null`** → no local folder exists; you cannot add an endpoint there.

`prefix` and `root` are unrelated names mapped **only by `app config`** — never guess the folder from the prefix (or a prefix from a folder name), and never create a `$`-named folder on disk.

## Make it reachable

The endpoint works by its URL the moment it exists. To surface it in the app's navigation, add an entry to `menu.json` — a separate task, see `references/menu.md`.

## Record it in DOMAIN.md

**Before building** — read the entity's `DOMAIN.md` entry and those of its `depends on` (in an existing project an untouched entity has no entry yet — its built schema is still readable via the `a2` CLI); for anything already built, build against real columns/keys, not invented. Order is free (FK → `keys.sql` after all tables): a not-yet-built or cyclic dependency never blocks — reference its `Id`.

**After building** — write the entry `confirmed at <path>` (flip `planned`, or create it on first touch), fill role, relationships, invariants, "don't do X" — **residue only**. Confirm with the user. Format → `semantic.md`.



