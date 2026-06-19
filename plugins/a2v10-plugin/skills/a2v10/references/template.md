# Template Conventions

Templates describe page and dialog behavior on the client side.
The file has the `.template` extension and contains TypeScript.

## Relation to SQL result sets

Collection names in the template correspond to array names in SQL result sets.
The collection name is always the **plural form of the model**:

```
SQL:      [Samples!TSample!Array]
Template: persistSelect: ["Samples"]
```

## options.persistSelect

Lists collections whose selected row is preserved when the list is refreshed:

```typescript
const template: Template = {
    options: {
        persistSelect: ["Samples"]
    }
}
```

## validators

Form validators. The key is the path to a field in `'<Model>.<Field>'` format; the value is a reference to a localized error string:

```typescript
const template: Template = {
    validators: {
        'Sample.Name': '@[Error.Required]'
    }
}
```

## events & global events (cross-view sync)

The `events` map binds handlers to both local model events and **global events**
broadcast across *every open tab/view* via `ctrl.$emitGlobal(name, payload?)`:

```typescript
const template: Template = {
    events: {
        'Model.load': onLoad,                  // local
        'app.entity.changed': onEntityChanged  // global (raised from any tab)
    }
}
```

A handler runs with `this` bound to the **root of the view that subscribed**, so each
open view reacts in its own context. `$emitGlobal` also reaches the emitter's own view.

**Pattern — keep other open views fresh.** When an action in one view/tab changes an
entity that may be open in another tab, the other tab will **not** refresh by itself
(the user won't press F5). So:

1. The acting view emits a global event carrying the changed entity (at least its `Id`)
   *before* it closes/navigates: `ctrl.$emitGlobal('app.entity.changed', entity);`
2. Every view that shows that entity subscribes and re-reads when the `Id` matches:

```typescript
function onEntityChanged(entity) {
    if (this.$isSourceView) return;             // skip the view that emitted & closes itself
    if (entity && entity.Id === this.Entity.Id)
        this.$ctrl.$requery();                  // reload: status, computed flags, buttons refresh
}
```

Notes:
- **Guard the source view** so the tab that emitted (and is about to `$close()`) doesn't
  requery itself — e.g. test a flag that's only set when opened in that mode.
- **Match by `Id`** so only views showing the same record react (the event hits all tabs).
- **One event name per change-kind**, reused across that entity's list/edit/show templates,
  rather than a new name per view. Lists typically `$merge`/`$requery`; cards `$requery`.

## Template inheritance (mergeTemplate)

A base template can be extended in a child file via `utils.mergeTemplate`.
Use it when several endpoints or operations share common logic but require partial differences.

```typescript
const base = require('<path>/base.template');
const utils: Utils = require('std:utils');

const template: Template = {
    // only what differs from the base
    validators: {
        'Sample.ExtraField': '@[Error.Required]'
    }
}
export default utils.mergeTemplate(base, template);
```

`utils.mergeTemplate` merges `validators`, `properties`, and `defaults` of the two templates.
Values from the child template take precedence on key conflicts.

If the endpoint needs no changes — a separate template is not required.
`model.json` references the base directly: `"template": "../base.template"`.

---
> Full documentation: *(the `template/` section is in progress — https://docs-llm.a2v10.com)*
