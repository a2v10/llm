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
