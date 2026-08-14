# Orientation — the turn has no task yet

Reached from SKILL.md §6 when the user asks *what this is / what can I do / where do I start*
instead of naming work. **Write nothing here** — no scaffold, no `CLAUDE.md`, no endpoint — until
the user names what to build or accepts an offer. This branch is repeatable and consumes nothing:
onboarding (§6) still runs once, later, when the first real task arrives.

## 1. Look — never ask what a command answers

- `model.json` anywhere in the tree → an app is already here (the platform's defining marker).
- `a2 --version` → the CLI; missing → install it (`cli.md`) before the checks below.
- `dotnet --version` → the SDK; needed to build. Report its absence, don't install it.

The database is checked where it matters, not here: an existing app — `a2 db tables` (an error =
not deployed / not reachable); a new one — at the scaffold step, which is the user's action anyway.

## 2. Say what A2v10 is

The user has no priors and neither do you outside this skill — **state only what follows, and what
§1–§3 already say; invent no capabilities, promise no features.** In substance:

> A2v10 is a runtime for back-office applications over SQL Server — довідники (catalogs), documents,
> journals, reports, with the usual list/edit/dialog surface. You declare an application:
> endpoints in `model.json`, views in XAML, behavior in TypeScript, data in stored procedures.
> The runtime routes URLs, renders the UI and moves the data; it has no opinion about what your
> entities mean — kinds, columns and names are the app's. There is no ORM, no migrations, no
> ad-hoc SQL: every read and write goes through a procedure. Files are read live — no build step
> for views or templates.

Anything the skill doesn't cover → the full docs: https://docs-llm.a2v10.com

Do not recite §7 Dispatch at the user — it is your routing table, not a feature list.

## 3. Two states, two answers

- **App present** → say what it *is*: `CLAUDE.md` / `DOMAIN.md` if they exist, `a2 endpoint list`
  for the exposed surface. Read-only. Do **not** run existing-project onboarding here — it belongs
  to the first real task (§6).
- **No app** → empty ground. Say what standing one up takes, in one breath: a scaffold, one
  `dotnet build`, and a database *the user* creates and applies. Then §4.

## 4. Close with one question and one offer — together

**One** question, and it differs by state; naming, id type, tenancy, XAML extension and the rest are
conventions applied silently, so an interview here is a defect, not thoroughness.

- **No app** → *what should the application do?* — that answer routes setup.
- **App present** → *what do you want to do with it?* — *what is it for* is the question they just
  asked **you**; don't hand it back.

The offer goes **with** the question, in the same breath — one endpoint end to end shows what the
platform is faster than any prose, so it is not an optional flourish. Match it to the state: no app —
*"I can stand up the shell and build one working довідник — table, procedures, list, edit form"*;
app present — *"I can add one, so you see the whole stack."* Donor: `examples/catalog/simple`. On a
yes it is a normal §6 task (setup first when there's no app), never a special path.

## 5. Hand back

The moment the user names work, return to SKILL.md §6 and take the normal fork. Unsure whether a
turn is a question or a task → treat it as a question: answering costs a paragraph, scaffolding
into someone's directory costs them a cleanup.
