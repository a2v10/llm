# model.json

**Full docs — [docs-llm.a2v10.com/model.md](https://docs-llm.a2v10.com/model.md).** A page per
section (overview, actions, dialogs, popups, commands, reports, files), every property with its type
and default. Look a key up there; never guess one.

**Read that hub as a catalogue of what the platform *can* do, not as a menu of what to use.** It is
exhaustive by design — it carries legacy keys and features written for one application in a
thousand. Presence on the page is not a recommendation, and a key you have never needed is not a key
you were missing.

## The keys you actually write

This is the whole mainline — the examples in this skill use nothing beyond it:

| Level | Keys |
|---|---|
| endpoint (top) | `$schema`, `description`, `schema`, `model` |
| `actions` / `dialogs` element | `view`, `template`, `index: true` (calls `.Index` instead of `.Load`), `parameters` |
| `commands` element | `type: "sql"`, `procedure` |

Anything else you meet on those pages — additional element keys, the other command types, the older
spellings — is long tail. Don't reach for one because you saw it listed. A task that genuinely needs
one describes the need in its own words first; *then* open the page.

Which section makes an element Renderable or Callable, and why one `model.json` keeps **one** `model`
→ SKILL.md §3 and §4. What the runtime derives from `model` (the `<schema>.[<model>.<Verb>]` proc
name) → `sql-procedures.md`.

## reports — file export ONLY

> ⚠️ The `reports` section is **only** for reports rendered **to a file** by the server.
> An **on-screen report is NOT here** — an interactive `Sheet` page is an `action`
> (→ `screen-report.md`). Shown on screen instead of downloaded → wrong section.

The decision rule (does the task name a file or a format?) lives in SKILL.md §3; this is the ban at
the point where the section is about to be written.

## permissions

Absent from the docs entirely, so it is written here. Accepted at the top level and on any element of
any section; an object with **arbitrary key names**, each value one of:

`view` | `edit` | `delete` | `apply` | `create` | `unapply` | `flag64` | `flag128` | `flag256`

```json
"permissions": {
  "Alice": "edit",
  "Bob": "view"
}
```

The same bits are what a procedure returns per row as the `!Permissions` bitmask
(→ [sql-rules.md](sql-rules.md)): `CanView` 1 + `CanEdit` 2 + `CanDelete` 4 + `CanApply` 8.

## description — this skill's convention, not a platform key

Top-level `"description"` names the endpoint's **archetype** — `catalog.simple`, `catalog.rich`,
`document.operation`. The runtime ignores it; it tells the next reader (human or model) which example
this endpoint was cloned from, so the clone can be swept against that donor. Every example here
carries one.
