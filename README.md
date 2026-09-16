# A2v10 Skills for Claude

Skills for developing on the **A2v10 Platform** — a generic runtime for building
business applications. Once installed, Claude loads the right skill automatically when
your request matches.

| Skill | For | Needs locally |
|---|---|---|
| `/a2v10` | endpoints (`model.json`), XAML views, SQL stored procedures, `template.ts`, localization | .NET SDK |
| `/a2v10meta` | metadata-driven endpoints (`metadata.json`), deployed with the `a2` CLI; builds on `/a2v10` | .NET SDK |
| `/a2v10from1c` | migrating a 1C configuration: parsing its dump, writing a spec, generating the app with `/a2v10meta` | .NET SDK, 1C Designer to dump the configuration |

The skills install their own command-line tools (`A2v10.CLI`, `A2v10.Confdump`) when
missing.

The skills ship as one Claude Code **plugin**, distributed from this repository, which is
a plugin marketplace named `a2v10-dev`.

| | |
|---|---|
| Marketplace | `a2v10/llm` (this repository) |
| Plugin | `a2v10` |

## Install

No terminal required — everything happens in the Claude app's settings.

**Add the marketplace** (once):

1. Open Claude's settings and pick **Plugins** under **Customize** in the sidebar.
2. Click **Add** in the top-right corner and choose **Add marketplace**.
3. Choose **Add from repository**.
4. Enter the repository:

   ```
   a2v10/llm
   ```

   It shows up on the **Plugins** page as a card labelled `a2v10/llm`.

**Install the plugin:**

5. Click **Browse** (top right) to open the **Directory** dialog, and select
   **Plugins** in its left sidebar.
6. Switch to the **Code** tab (next to *Anthropic* and *Partners*) and click the
   **a2v10-dev** chip — this is the marketplace you just added.
7. Click the **A2v10** card to open the plugin's page.
8. Click **Install**. The **▾** next to it picks where the plugin lands:

   | Option | Installs to | Use when |
   |---|---|---|
   | **Install for me** | `~/.claude/` | you work on A2v10 in more than one project — the usual choice |
   | **Install for project (shared)** | `.claude/` | you want the whole team to get it from the repository |
   | **Install for project (personal)** | `.claude.local/` | just this repository, just you — gitignored |

Afterwards the plugin shows up under **Customize → Plugins**. Open it and check that
**Source** reads `Marketplace (a2v10-dev)` and that the toggle in the top-right is
**on** — the toggle is what makes the plugin active.

Under **Skills** you'll see the three skills the plugin ships: **`/a2v10`**,
**`/a2v10meta`**, **`/a2v10from1c`**. They come with the plugin; there is nothing to
install separately. Use them either way:

* **Automatically** — describe the task, and Claude loads the matching skill itself.
* **Explicitly** — type the skill's name, e.g. `/a2v10meta`.

Those three destinations are the ordinary Claude Code plugin scopes, so the install
covers every way you reach Claude Code within its scope — sessions in the app's **Code**
tab and `claude` sessions you start in a terminal alike.

> ℹ️ The **Code** tab has a second door to the same list: click **➕** next to the
> prompt box and choose **Plugins**, then **Add plugin** or **Manage plugins**.

## Update, disable, remove

Open **Customize → Plugins** in settings and click **A2v10** to open its page:

* **Update** — the button next to the toggle. It's active only when a newer version
  is published; compare the **Version** field with the
  [latest release](https://github.com/a2v10/llm/releases/latest).
* **Disable** — flip the toggle off. The plugin stays installed but Claude ignores it.
* **Remove** — the **⋮** menu next to the toggle. The same menu has **Show in folder**,
  which opens the plugin's files on disk, and entries for **VS Code** and **Cursor**.

## The same from the CLI

If you live in a terminal, the `/plugin` commands do exactly what the settings UI does —
same marketplace, same files under `~/.claude`. You only need Claude Code installed:

```
npm install -g @anthropic-ai/claude-code
```

Start it in your project folder with `claude`, log in, then at the Claude Code prompt:

```
/plugin marketplace add a2v10/llm
/plugin install a2v10@a2v10-dev
```

Run `/reload-plugins` if the install summary asks for it.

To update, refresh the catalog and the plugin — they move independently:

```
/plugin marketplace update a2v10-dev   # refresh the catalog (versions, metadata)
/plugin update a2v10@a2v10-dev         # update the installed plugin
```

> Installing Claude Code on other platforms:
> <https://docs.claude.com/en/docs/claude-code/overview>

## Fallback: upload the skills as zips

If plugins are unavailable to you — for example your plan or your organization's
settings don't allow custom marketplaces — you can upload the bare skills instead.
Custom Skills require Pro, Max, Team, or Enterprise with code execution enabled.

Each release has one zip per skill: **`a2v10-*.zip`**, **`a2v10meta-*.zip`**,
**`a2v10from1c-*.zip`**. `/a2v10meta` builds on `/a2v10`, and `/a2v10from1c` generates
the app with `/a2v10meta` — upload the ones you need together with what they build on.

1. Download the zips from the
   [Releases page](https://github.com/a2v10/llm/releases/latest).
2. In Claude, open **Customize → Skills**.
3. Click **➕ → Create skill → Upload a skill**.
4. Select a downloaded zip. Repeat for each zip.

The skills appear under **Personal skills** and are used automatically when relevant.

Uploaded skills do not auto-update. To move to a newer version, download the latest
zips, then for each skill open its **⋮** menu and choose **Replace** — pick its new zip.
(Claude accepts the versioned file name as-is; no need to rename it.) Alternatively,
use **Uninstall** from the same menu and upload the new zip from scratch.

## Codex

The same skills work in Codex — there is no separate build. They are not yet tested
there; please report what breaks in [Issues](https://github.com/a2v10/llm/issues).

1. Download the zips from the
   [Releases page](https://github.com/a2v10/llm/releases/latest).
2. Unzip each into its own folder named after the skill: `a2v10-*.zip` →
   `~/.agents/skills/a2v10/`, `a2v10meta-*.zip` → `~/.agents/skills/a2v10meta/`, and so
   on. The zips have no top-level folder, so extracting straight into
   `~/.agents/skills/` scatters their files.

To update, replace each folder's contents with its newer zip.

The skills keep project state in `CLAUDE.md`, under Codex too — keep that file.

## License

[MIT](LICENSE.txt) © Oleksandr Kukhtin
