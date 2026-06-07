# Troubleshooting — what to verify when it doesn't work

A2v10 fails **silently**: no build, no compiler, no error — the runtime simply
does not pick up data, or an element does nothing. So you cannot debug by
*watching* the app. Instead, **verify the artifacts** against the engine
contract, layer by layer — every check below is something you can do by reading
the files or asking the `a2` CLI.

## How to use this file

Identify the layer that changed, run its checks. When a check needs the live DB
or config (does the proc exist? what columns does the table have?), use the `a2`
CLI (see `../cli.md`), not guesswork.

**Post-deploy, one shot:** once procs are created and `build` is done, `a2
endpoint resolve-*` (see `../cli.md`) checks several layers at once — that the
route resolves, which procs/files the runtime actually binds, and the model
shape it assembles (to compare against your XAML binds and SQL markers). It
fails by design before deploy, so it confirms a deployed result, it does not
guide authoring.

## Checks by layer

> TODO — fill each layer with concrete, model-actionable checks (read-file or
> CLI), not symptom observation. Skeleton:

- **Routing / model.json** — endpoint resolves? `model`/`schema` correct? element declared?
- **View / template** — `view`/`template` path resolves to an existing file?
- **Stored procedure (found)** — proc exists under the exact derived name `<schema>.[<model>.<Verb>]`? (verify via CLI)
- **Stored procedure (contract)** — result-set markers present and well-formed? cross-layer names agree (TVP column = client property; marker ↔ `d.ts` ↔ XAML)?
- **Client conventions** — element honors its fixed-name convention → `elem-conventions.md`?
- **Localization** — `@[Key]` present in a dictionary for the active locale → `localization.md`?

## When it all fails — the principle

The engine is almost never at fault. A2v10 fails silently because a **name does
not agree across layers**, or a **proc/file the runtime cannot find** — not
because of engine magic. So don't guess or thrash: walk the layers above against
the contract, and use the `a2` CLI to read *real* state (does the proc exist?
what columns does the table have?) instead of assuming.

