# System menu — app navigation (menu.json)

`menu.json` declares the app's navigation. It lives at the **root of the main app module** (`prefix: ""` — run `a2 app config` for its root; SKILL.md §3). The runtime reads it **on the fly** — no build, no restart, no migration.

**Edit the file directly.** Adding or changing a menu entry is a file edit — never SQL, never a stored procedure.

## Structure (recognition)

- `appTitle` = the string rendered in the running app's **header** (top bar, beside the logo); it localizes via `@[...]` like any title.
- **Links live at the third level.** The tree is section (L1, carries `icon`) → group (L2) → link (L3, carries `url`). A `url` placed on level 1 or 2 renders but **won't open** — levels 1–2 are containers only.
- A link's `url` addresses **either** an app-endpoint path (`/document/waybillin`) **or** a `$`-prefixed compiled-module route (`/$meta/config`) — the same addressing model as SKILL.md §3.
- Titles use `@[...]` localization (SKILL.md §1).

## Example

```json
{
	"$schema": "@schemas/menu-json-schema.json#",
	"appTitle": "@[AppTitle]",
	"menu": [
		{
			"title": "@[Sales]",
			"icon": "cart",
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

Other fields (`grow`, `underline`, `category`, `id`, …) and the full JSON schema (`@schemas/menu-json-schema.json`) → https://docs-llm.a2v10.com/app/menu.md

## Legacy DB menu

Older projects drive navigation from the `a2ui.Menu` table instead of this file; it still works — to move such a project onto `menu.json`, see `menu-migration.md`.
