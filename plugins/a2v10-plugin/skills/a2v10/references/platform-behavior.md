# Platform behavior — priors the runtime handles for you

The runtime honors some **behavioral** priors automatically. Against those, hand-rolled
defensive scaffolding is duplication, not safety. And **whether** the platform handles a
given case is a *platform fact* — it lives here or in the docs, **never** inferred from a
generic prior (the classic mistake: "a promise/proc with no explicit handling must fail
silently, so I'll defend everywhere" — usually the platform already has it).

One line per convention: *what the platform does → what you therefore don't do → when you
override*. Full mechanics live in the linked docs; this file is recognition-height only —
grow it only from grounded facts, never seed speculative entries.

Sibling axis: name-sensitive elements that **silently fail** without an exact name →
[elem-conventions.md](elem-conventions.md). That one is naming; this one is behavior.

## Server errors from `$invoke` — the platform shows them

- **Default (no `catchError`):** the platform surfaces the server error itself. A `throw`
  message prefixed `UI:` (a **business** error — «немає товару») is shown to the user
  **formatted**; without the prefix (a **developer** error — proc not found) it falls back
  to a bare `alert`. The user is never left without a message — but the promise's
  `.then`/`.finally` continuation **does not run**.
- **Don't:** wrap invokes in defensive error handling by default. The platform already
  shows the error and already distinguishes business vs developer — blanket `catchError`
  only replaces that with hand-rolled display and concentrates risk.
- **Override with `catchError: true` only when** a failure must *also* act on the client
  (refresh UI, clear a custom «надсилання…» flag): the promise then **rejects** → wrap the
  call in `try/catch`, and showing the error is now yours. `$alert(msg)` gives the same
  formatted view — reproduce the platform's rule if you re-show it:
  `msg.startsWith('UI:') ? $alert(msg.substring(3)) : alert(msg)`.
- **Server side:** raise a user-facing business error as `throw 60000, N'UI:текст', 0`;
  omit the prefix for internal asserts meant for the developer.
- Mechanics → [controller](https://docs-llm.a2v10.com/client/controller.md).

---
> Full documentation: https://docs-llm.a2v10.com
