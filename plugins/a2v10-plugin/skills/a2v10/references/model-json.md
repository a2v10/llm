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

`model` may also be `"$meta"`: the model is built by another component (SKILL.md §3, *`$meta` → not
yours*). Under it a missing `view`/`template` key, or a missing element, does not mean "none" — it
means "built"; what exists is read from `a2 endpoint resolve-*`, not from this file.

Anything else you meet on those pages — additional element keys, the other command types, the older
spellings — is long tail. Don't reach for one because you saw it listed. A task that genuinely needs
one describes the need in its own words first; *then* open the page.

One command type beyond that table has its own file: a command that reaches **outside the database**
— an external API, an integration — runs C# instead of a procedure (`type: "clr"`, `clrType`) → [clr.md](clr.md). The doc page is wrong
about it; read that file, not the page.

Which section makes an element Renderable or Callable, and why one `model.json` keeps **one** `model`
→ SKILL.md §3 and §4. What the runtime derives from `model` (the `<schema>.[<model>.<Verb>]` proc
name) → `sql-procedures.md`.

## reports — documents the server builds, not pages

> ⚠️ The `reports` section is for a **fixed document built by the server**: a printed form (PDF)
> or an xml/json export. An **on-screen report is NOT here** — an interactive, filterable `Sheet`
> page is an `action` (→ `screen-report.md`). A printed form previewed on a form
> (`PdfReportViewer`) is still a `reports` element: the axis is what the thing is, not where it
> appears.

A printed form has its own file — wiring, the template language, and the bans that go with it
→ [print-form.md](print-form.md). Here: `xml`/`json` exports, which need no template.

The decision rule lives in SKILL.md §3; this is the ban at the point where the section is about to
be written.

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
