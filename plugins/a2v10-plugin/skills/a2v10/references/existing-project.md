# Existing project — discover the semantics

The app already embodies its semantics. Your job is to **discover and record**
them, never invent. Output: the project's CLAUDE.md, filled per `semantic.md`.

## Steps

1. Read `semantic.md` — know which dimensions to look for.
2. Discover each from the app:
   - config (tenancy, …) and DB (tables, columns, references) via the `a2` CLI (SKILL.md §2);
   - read code where the CLI doesn't reach;
   - infer the **kinds** in use and each kind's conventions from what exists.
3. Record the **reality**, including where the app breaks a convention.
4. **XAML extension** — ask the user which they use (`.vxaml` for VS-2026, else `.xaml`; they may be mid-migration to `.vxaml`). Record it as `XAML naming convention` in CLAUDE.md — that line governs which extension new files get.
5. Write it all to CLAUDE.md. Ambiguous → ask the user.

> Navigation: existing projects may drive the menu from the legacy `a2ui.Menu` table — to move it to `menu.json`, see `menu-migration.md`.

> TODO — concrete discovery recipes per dimension (which CLI calls, what to read).
