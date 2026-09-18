# System menu — app navigation (menu.json)

**Full docs — [docs-llm.a2v10.com/app/menu.md](https://docs-llm.a2v10.com/app/menu.md)** — the JSON
schema, every node property, and [the complete icon list](https://docs-llm.a2v10.com/app/menu.md#icons)
(a closed set of ~280 names; copy one verbatim). The page also carries presentation keys that a menu
almost never needs — read it for the icon list, not for ideas.

`menu.json` declares the app's navigation. It lives at the **root of the main app module**
(`prefix: ""` — run `a2 app config` for its root; SKILL.md §3). The runtime reads it **on the fly** —
no build, no restart, no migration.

**Edit the file directly.** Adding or changing a menu entry is a file edit — never SQL, never a
stored procedure.

The mainline is the shape below and nothing else: `title`, `icon`, `items`, `url`, `create`.

```json
{
	"$schema": "@schemas/menu-json-schema.json#",
	"appTitle": "Sales App",
	"menu": [
		{
			"title": "@[Sales]", "icon": "cart",
			"items": [
				{
					"title": "@[Catalogs]",
					"items": [
						{ "title": "@[Agents]", "url": "/catalog/agent", "create": true },
						{ "title": "@[Stores]", "url": "/catalog/store" }
					]
				}
			]
		}
	]
}
```

`create: true` adds the quick **+** action beside a catalog link.

## What the docs don't say

- **A `url` targets an endpoint's `index` — never another action.** A leaf with no action segment
  opens `index`. An action such as a screen report is opened from a page (`/reports` lists them),
  not from the menu.
- **A `url` on level 1 or 2 renders but won't open** — only the leaf (third) level acts on it;
  levels 1–2 are containers.
- **A module endpoint is addressed with that module's `prefix`, which the disk path does not
  contain**: `StoreApp/catalog/store` on disk → url `/$store/catalog/store`, never
  `/catalog/store`. The folder path alone cannot tell you the url — get the prefix from
  `a2 app config`. (A `$`-prefixed route may also be a compiled module with no folder at all.)
- **`icon` is a closed dictionary — never guess.** An unknown name silently fails to render at
  runtime (no error, no fallback; the schema catches it only in an editor that validates). Don't
  infer from Font Awesome / Material / Bootstrap or from the label. Copy a name verbatim from the
  full list → [app/menu.md#icons](https://docs-llm.a2v10.com/app/menu.md#icons).
- **`icon` belongs on top-level items only, and there it is required.** Without one the sidebar still
  works, but the section is unrecognizable; on deeper levels an icon is never rendered.
- **Node** titles use `@[...]` localization (SKILL.md §1). **`appTitle` is the application's own
  name — a literal**; it takes `@[...]` too, but only reach for it when the name itself must be
  translated.

## Menu in the database

Older projects drive navigation from the `a2ui.Menu` table and have **no** `menu.json`; it still
works, and everything above then does not apply. **Do not create the file** — nothing would read it,
the entry silently never appears — and do not write SQL against that table, not even a fragment for
the user to apply. Say the menu lives in the database and ask the user how to proceed.
