# System menu — app navigation (menu.json)

`menu.json` declares the app's navigation. It lives at the **root of the main app module** (`prefix: ""` — run `a2 app config` for its root; SKILL.md §3). The runtime reads it **on the fly** — no build, no restart, no migration.

**Edit the file directly.** Adding or changing a menu entry is a file edit — never SQL, never a stored procedure.

## Structure (recognition)

- `appTitle` = the string rendered in the running app's **header** (top bar, beside the logo); it localizes via `@[...]` like any title.
- **Links live at the third level.** The tree is section (L1, carries `icon`) → group (L2) → link (L3, carries `url`). A `url` placed on level 1 or 2 renders but **won't open** — levels 1–2 are containers only.
- A link's `url` addresses **either** an app-endpoint path (`/document/waybillin`) **or** a `$`-prefixed compiled-module route (`/$meta/config`) — the same addressing model as SKILL.md §3.
- An endpoint that lives in a module folder is addressed **with that module's `prefix`** — the disk path does not contain it (`StoreApp/catalog/store` on disk → url `/$store/catalog/store`, never `/catalog/store`). The folder path alone cannot tell you the url; get the prefix from `a2 app config`.
- Titles use `@[...]` localization (SKILL.md §1).
- **`icon` is a closed dictionary — never guess.** An unknown name silently fails to render (no error, no fallback). Don't infer from Font Awesome / Material / Bootstrap or from the label. Use one of the names below verbatim, or omit `icon` (a section without it is valid).

`icon` = one of: access, account, account-folder, add, address-book, address-card, alert, apply, approve, arrow-down, arrow-down-red, arrow-export, arrow-left, arrow-left-right, arrow-left-right-full, arrow-open, arrow-right, arrow-sort, arrow-up, arrow-up-green, assets, attach, ban, bank, bank-account, bank-uah, barcode, bell, board, bookmark, brand-excel, calc, calendar, calendar-today, calendar-week, call, camera, cart, chart-area, chart-bar, chart-column, chart-pie, chart-pivot, chart-stacked-area, chart-stacked-bar, chart-stacked-line, check, check-bold, checkbox, checkbox-checked, chevron-double-left, chevron-double-right, chevron-down, chevron-left, chevron-left-end, chevron-right, chevron-right-end, chevron-up, circle, circle-small, clear, close, cloud, cloud-outline, code, code-check, comment, comment-add, comment-discussion, comment-lines, comment-next, comment-outline, comment-previous, comment-urgent, company, confirm, copy, currency-euro, currency-other, currency-uah, currency-usd, cut, dashboard, dashboard-outline, database, delete, delete-box, delete-red, devices, disapprove, dot, dot-blue, dot-green, dot-red, download, edit, edit-redo, edit-undo, ellipsis, ellipsis-bottom, ellipsis-vertical, error, error-outline, exit, export, export-excel, external, eye, eye-disabled, eye-disabled-red, factory, failure, failure-outline, failure-red, file, file-content, file-download-pdf, file-error, file-failure, file-image, file-import, file-link, file-preview, file-signature, file-success, file-user, file-warning, filter, filter-outline, flag, flag-blue, flag-green, flag-red, flag-yellow, flag2, flame, folder, folder-ban, folder-move-to, folder-outline, folder-query, folders-outline, gear, gear-outline, grid, help, help-blue, help-outline, history, home, image, import, info, info-blue, info-outline, items, link, list, list-bullet, lock, lock-outline, log, logout, menu, message, message-outline, minus, minus-box, minus-circle, mode-dark, mode-light, package, package-outline, pane-close, pane-left, pane-left-blue, pane-open, pane-right, pane-right-blue, paste, pencil, pencil-outline, personnel, pin, pin-outline, pinned, pinned-outline, play, play-outline, plus, plus-box, plus-circle, policy, power, print, process, qrcode, query, queue, refresh, reload, rename, report, requery, save, save-as, save-close, save-close-outline, save-outline, search, security, send, send-outline, server, share, smile, smile-sad, square, star, star-outline, star-yellow, step, steps, storyboard, success, success-green, success-outline, switch, table, tag, tag-blue, tag-green, tag-outline, tag-red, tag-yellow, task-complete, trash, triangle-left, triangle-right, truck, unapply, unlock, unlock-outline, unpin, unpin-outline, upgrade, upload, upload2, user, user-image, user-minus, user-plus, users, variable, waiting, waiting-outline, warehouse, warning, warning-outline, warning-yellow, workflow1, wrench.

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
