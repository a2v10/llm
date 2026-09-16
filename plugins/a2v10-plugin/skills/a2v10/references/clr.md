# clr — calling C# code

**For reaching outside the database** — an outbound HTTP call, an external API, an integration.
Anything expressible in T-SQL stays a `sql` command.

Working example → [examples/clr/rates](../examples/clr/rates/README.md).

## Declaring it

A `commands` element with `type: "clr"` and `clrType`, and no `procedure` key — a `clr` command
names a class, not a procedure. `clrType` is a literal format, **not** a .NET assembly-qualified
name:

```
clr-type:<full type name>;assembly=<assembly name>
```

One regex parses it: the two words are lowercase, and both names take only letters, digits, `_` and
dots. Called from the client as `$invoke(<command>, <args object>, <endpoint path>)`.

## Where the class lives

**An application decision, not a platform one.** The runtime resolves the class by the assembly name
in `clrType`, so any assembly the host loads will do.

By default that is **`MainApp`**, with the handler next to the `model.json` of the endpoint it
serves — nothing to wire, nothing to name, `assembly=MainApp`. The first handler adds
`A2v10.Infrastructure`, `A2v10.Data.Interfaces` and `Microsoft.Extensions.Http` (for
`IHttpClientFactory`) to `MainApp.csproj`.

Move CLR types out into a separate library — or more than one — when the application's own logic
warrants it: heavy third-party dependencies you would rather keep out of the app project, or a body
of C# large enough to have its own structure. Such a library is referenced by the host, and
`assembly=` names it.

Either way the host loads the assembly from its own output at startup: a changed `.cs` needs the
host **rebuilt and restarted**, and that is the user's step, not yours (SKILL.md §4). Nothing on this
floor is read live. `.cs` counts as a platform file for the BOM rule (SKILL.md §5).

## The class

`public`, implements `IClrInvokeTarget` (`Task<Object> InvokeAsync(ExpandoObject args)`), one class
per command, and a **constructor taking a single `IServiceProvider`** — the platform looks up
exactly that signature, so anything else fails at invoke. The namespace is whatever the file
declares; the folder does not shape it.

- **Services**, via `GetRequiredService<T>()` from that provider: `IDbContext` (the database),
  `ICurrentUser` (`Identity.Id` is the `UserId` procedures expect), `IHttpClientFactory` (outbound
  HTTP — `CreateClient()`, never `new HttpClient()`), `ILogger<T>`. The container holds more, but a
  service you have not seen used is a guess — check or ask (SKILL.md §5).
- **`args`** is what the client passed; read it with `args.Get<T>("Name")`. The **return value** is
  serialized to JSON, and `null` sends `{}` — nothing to construct when there is nothing to report.
- **Throw on failure; never return a status object.** The exception reaches the caller with its
  message intact — that is the platform's error path, and a hand-rolled `{ success: false }` hides
  it. Prefix the message `UI:` for a business error the user should read (→ `platform-behavior.md`).

## The database — the §4 law holds here too

Only stored procedures; being in ordinary C# does not make this ordinary .NET data access.
`IDbContext` takes the data source first (`null` = the application's default), then the procedure,
then parameters as an `ExpandoObject` or a plain object of your own. Four calls cover a handler:

| | |
|---|---|
| `ExecuteExpandoAsync(null, "sch.[Proc.Name]", prms)` | run a procedure |
| `ReadExpandoAsync(null, "sch.[Proc.Name]", prms)` | read one object back |
| `LoadListAsync<T>(null, "sch.[Proc.Name]", prms)` | read a list of your own type |
| `SaveListAsync<T>(null, "sch.[Proc.Name]", prms, list)` | write a whole collection in **one** call |

`SaveListAsync` is what you reach for after pulling records from an API: a loop of single calls
works, so nothing will tell you it was wrong.

**The interface offers a way out — don't take it.** `LoadModelSqlAsync` and `GetDbConnection` sit
right there in autocomplete; they belong to the platform, not to your handler.

---

The doc page — [model/commands.md](https://docs-llm.a2v10.com/model/commands.md) — is **wrong** about
`clr` twice over: the interface is not `IInvokeTarget`, and `clrType` is not `"Ns.Type, Assembly"`.
Read it for anything else; for these, this file wins (SKILL.md §5).
