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

## The loud exception — the toolchain, not the engine

Everything else here is about silence. Visual Studio and MSBuild are the
exception: they fail **loudly**, and the user brings you the text. Those are
project-file problems, and the answer is always the same — compare against
`../scaffold/MainApp/MainApp.csproj` in this skill, which is already correct, and
read its comments before changing anything.

| The user reports | What it means |
|---|---|
| `An element with the same key but a different value already exists. Key: 'Microsoft.WebTools.ProjectSystem.WebServer.SelfHostWebServer'` | Two `Microsoft.NET.Sdk.Web` projects in the solution. The application project is not a web app — it takes plain `Microsoft.NET.Sdk`. |
| `TS5112: tsconfig.json is present but will not be loaded if files are specified on commandline` | The TypeScript targets did not find `tsconfig.json`. The `A2v10.App.Assets2026` targets declare it for you — seeing this means the package is older than the version the scaffold pins; update it. |

**Never resolve either by putting the application project back on
`Microsoft.NET.Sdk.Web`.** It buys one silent build at the price of the first
error returning, plus the whole application folder copied into the host's output.

## Checks by layer

> TODO — fill each layer with concrete, model-actionable checks (read-file or
> CLI), not symptom observation. Skeleton:

- **Routing / model.json** — endpoint resolves? `model`/`schema` correct? element declared?
- **View** — run `a2 view validate <view-file>` (the file `view:` names, from the application root → `../cli.md`): it loads the file as the server does and names bad markup, an unknown element/property, a bad enum value or an unresolvable `Components` file. Source-only, so it answers before deploy. It stays silent about binds, attached properties and `<Component Name>`.
- **Template** — `view`/`template` path resolves to an existing file?
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

