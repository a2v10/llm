# Template Conventions

**Full docs — [template.md](https://docs-llm.a2v10.com/template.md) (per-key authoring) and
[client.md](https://docs-llm.a2v10.com/client.md) (the `$`-members, the controller, `std:utils`).**
This file is the key index and the choices the docs don't make for you.

Templates describe page and dialog behavior on the client side.
The file has the `.template` extension and contains TypeScript.

`.template.ts` is the file you write; a same-named `.js` beside it is a generated build artifact — never hand-write or edit it. Building the module's csproj (SKILL.md §4) compiles it — TypeScript is a step of that build. To compile the templates alone, run `npx -p typescript@<version> tsc` from the module root, `<version>` = the `Microsoft.TypeScript.MSBuild` version in that csproj (it picks up the project `tsconfig`).

The shape is the `Template` interface declared in `platform.d.ts`. You assign `const template: Template = { … }` and `export default` it.

## Relation to SQL result sets

Collection names in the template correspond to array names in SQL result sets.
The collection name is the one the marker declares — by convention the plural of the model: `[Samples!TSample!Array]` → `"Samples"`.

## Template keys

Every member is optional. Values are typed — pull exact sub-shapes from `platform.d.ts`, don't reinvent them. **The map key means a different thing in each map** — easy to lose; see *Key by map*. Per-key authoring lives in the linked doc pages.

```typescript
interface Template {
    options?:    TemplateOptions;                          // page-level flags (no own page) — see below
    properties?: { [type: string]: templateProperty };     // computed props, keyed by element/array TYPE
    defaults?:   { [path: string]: templateDefault };      // default value for new elements, keyed by model path
    validators?: { [path: string]: templateValidator | templateValidator[] };  // field validation, keyed by model path
    events?:     { [key: string]: templateEvent };         // model / object / array + global; key differs per tier (see below)
    commands?:   { [name: string]: templateCommand };      // named commands invoked from views; this = IRoot
    delegates?:  { [name: string]: (this: IRoot, ...a: any[]) => any };  // named fns bound from XAML
    loaded?:     (data: object) => void;                   // fires once after the model is loaded
    utils?:      any;                                       // escape hatch for shared helpers
}
```

Doc pages (authoring): [overview](https://docs-llm.a2v10.com/template/overview.md) · [properties](https://docs-llm.a2v10.com/template/properties.md) · [defaults](https://docs-llm.a2v10.com/template/defaults.md) · [validators](https://docs-llm.a2v10.com/template/validators.md) · [events](https://docs-llm.a2v10.com/template/events.md) · [commands](https://docs-llm.a2v10.com/template/commands.md) · [delegates](https://docs-llm.a2v10.com/template/delegates.md). The `$ctrl` controller surface and `std:utils` live under `client/` (below).

### Key by map

The qualifier differs by map — by tree **location** for validators/defaults/events, by **type** for properties:

- **validators**, **defaults** — model **path**: `Document.Rows[].Qty`
- **events** — depends on tier: `Model.<evt>`, `{Type}.construct`, property path `Document.Rows[].Qty.change`, array path `Document.Rows[].add`
- **properties** — element/array **TYPE**: `TRow`, `TRowArray` — every instance of that type, not one path
- **commands / delegates** — an arbitrary **name**

### options (no dedicated page)

- `persistSelect: string[]` — collections whose selected row survives a refresh (plural model name).
- also: `noDirty`, `skipDirty: string[]`, `bindOnce: string[]`, `globalSaveEvent: string`.

### validators

Value forms — localized `'@[Error.Key]'` (→ localization reference), a `StdValidator` name, a function, or an object (async / conditional). Forms → [validators](https://docs-llm.a2v10.com/template/validators.md).

### events — taxonomy

`Model` is a **reserved keyword** for the whole model (literal — not your model's name). Three tiers, `this: IRoot` in all:

- **Model-level**: `Model.load`, `Model.unload`, `Model.saved`, `Model.beforeSave`.
- **Object**: `{Type}.construct` (type-keyed), `{prop}.change` / `{prop}.changing` (property-keyed; `changing` returns `boolean` to veto, fires *before* the change, `change` *after*).
- **Array**: `{array}.adding`, `.add`, `.change`, `.remove`, `.select`.
- **Global / custom**: subscribed in the same map by the plain name you `$emit`.

Signatures and binding → [events](https://docs-llm.a2v10.com/template/events.md).

### commands

A function (`(this: IRoot, arg?) => …`; returning `'save'` triggers a save) or an object with guards/confirmation. Forms → [commands](https://docs-llm.a2v10.com/template/commands.md).

## Inside a handler — `this.$ctrl`

Every `IElement` (and `IRoot`) exposes `$ctrl: IController` — the runtime surface you call from any command/event body. Common reaches: `$invoke`, `$showDialog`, `$navigate`, `$save`, `$requery`, `$reload`, `$close`, `$toast`, `$report`, `$upload`. Full surface → [controller](https://docs-llm.a2v10.com/client/controller.md).

Server errors from `$invoke` are shown by the platform by default (business `UI:` message vs bare developer alert); reach for `catchError` **only** for a client-side follow-up on failure → [platform-behavior.md](platform-behavior.md).

### Cross-view refresh (stale-tab problem)

An action that changes an entity also open in another tab/view leaves that view stale until told to refresh. The acting view emits on change (carrying at least the `Id`); the other view, subscribed by the same event name, calls `$requery()`. Mechanics → [controller](https://docs-llm.a2v10.com/client/controller.md).

- Subscribe **via the `events` map by name** — **never `EventBus` (`std:eventBus`)**: it has no auto-`$off` on page close, so the handler outlives the view and leaks.
- `$emitGlobal(name, data?)` broadcasts to **all** views, the emitter included → **guard by `Id`** so the source view doesn't requery itself.
- `$emitCaller` targets the **caller** (the code/dialog that opened the current view).

## Template inheritance (mergeTemplate)

A base template is extended in a child via `utils.mergeTemplate` — a plain function on `std:utils` (→ [utils](https://docs-llm.a2v10.com/client/utils.md)).

```typescript
const base = require('<path>/base.template');
const utils: Utils = require('std:utils');

const template: Template = {
    validators: { 'Sample.ExtraField': '@[Error.Required]' }   // only what differs from base
}
export default utils.mergeTemplate(base, template);
```

`utils.mergeTemplate(base, child)` deep-merges **all** keys; child values win on conflict.
If the endpoint needs no changes, skip the template — `model.json` references the base directly: `"template": "../base.template"`.

