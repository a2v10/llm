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
	"appTitle": "@[AppTitle]",
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

- **Links live at the third level.** The tree is section (L1, carries `icon`) → group (L2) → link
  (L3, carries `url`). A `url` placed on level 1 or 2 renders but **won't open** — levels 1–2 are
  containers only.
- **A module endpoint is addressed with that module's `prefix`, which the disk path does not
  contain**: `StoreApp/catalog/store` on disk → url `/$store/catalog/store`, never
  `/catalog/store`. The folder path alone cannot tell you the url — get the prefix from
  `a2 app config`. (A `$`-prefixed route may also be a compiled module with no folder at all.)
- **`icon` is a closed dictionary — never guess.** An unknown name silently fails to render at
  runtime (no error, no fallback; the schema catches it only in an editor that validates). Don't
  infer from Font Awesome / Material / Bootstrap or from the label. Copy a name verbatim from the
  docs list, or omit `icon` — a section without one is valid.
- Titles use `@[...]` localization (SKILL.md §1).

## Legacy DB menu

Older projects drive navigation from the `a2ui.Menu` table instead of this file; it still works — to
move such a project onto `menu.json`, see `menu-migration.md`.
