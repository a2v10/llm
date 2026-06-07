# Localization

A runtime-wide macro: wherever the runtime meets `@[Key]`, it substitutes the
value for `Key` from the project's dictionary files. Plain text without `@[…]`
is rendered as-is.

## Dictionaries

- Files live in `_localization/`, named `<name>.<locale>.txt`; the locale comes
  from the user's profile.
- Lines are `@Key=Value`. `;` starts a comment. Keys are **case-sensitive** and
  contain **no spaces**.
- File names and count are insignificant to the runtime — split or merge freely.

## Key organization is a project convention

How keys are grouped (single file vs many, naming style) is **not** a runtime
rule — decided per project, recorded in CLAUDE.md. Common default: one
`_default.<locale>.txt` in `_localization/`; append a `; <Entity>` block per
entity; dedupe (never re-add shared keys); keys = entity singular/plural, field =
column name.
