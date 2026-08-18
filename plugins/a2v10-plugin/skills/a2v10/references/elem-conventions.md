# Element conventions — the exceptions to "names are free"

The engine treats element and property names as **free**: it derives nothing from
them (see SKILL.md §3). This file catalogs the **few exceptions** — mostly
client-side elements that assume a **specific name or structure** and **silently
fail** (no error, just nothing happens) when it is absent.

Honor every convention listed here verbatim.

## How to read an entry

Each entry states:

- **Element / where** — which element or section the convention applies to.
- **Required name/structure** — the exact name or shape the runtime expects.
- **Failure mode** — what silently breaks when it's missing (so you can recognize the symptom).

## Conventions

### Tag chips — `<TagsControl>` (editor) and `<TagsList>` (read-only)

- **Element / where** — the tag controls, bound to an array of tag elements
  (`<TagsControl Value=… ItemsSource=…>` in a form, `<TagsList ItemsSource=…>` in a grid cell).
- **Required name/structure** — each bound element must expose **`Name`** (chip caption) and
  **`Color`** (chip color). Neither is declared on the control — both are read **by convention**
  from the element, so the SQL projection (and the tags dictionary) must supply `Name` and `Color`.
- **Failure mode** — silent: chips render with a blank caption (missing `Name`) and/or with no
  color (missing `Color`); no error.

> TODO — more entries to enumerate (each as Element / Required name/structure / Failure mode).
> Do not invent: derive each from the platform docs or observed runtime behavior.
