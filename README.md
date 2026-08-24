# A2v10 Skill for Claude

A skill for developing on the **A2v10 Platform** — a generic runtime for building
business applications. Once installed, Claude loads it automatically when your request
matches (A2v10, `model.json`, `view.vxaml`, SQL stored procedures, and so on).

The skill ships as a Claude Code **plugin**, distributed from this repository, which is
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

Under **Skills** you'll see the single skill the plugin ships, **`/a2v10`**. It comes
with the plugin; there is nothing to install separately. Use it either way:

* **Automatically** — describe an A2v10 task, and Claude loads the skill itself.
* **Explicitly** — type `/a2v10`.

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

## Fallback: upload the skill as a zip

If plugins are unavailable to you — for example your plan or your organization's
settings don't allow custom marketplaces — you can upload the bare skill instead.
Custom Skills require Pro, Max, Team, or Enterprise with code execution enabled.

1. Download the latest **`a2v10-*.zip`** from the
   [Releases page](https://github.com/a2v10/llm/releases/latest).
2. In Claude, open **Customize → Skills**.
3. Click **➕ → Create skill → Upload a skill**.
4. Select the downloaded zip.

The skill appears under **Personal skills** and is used automatically when relevant.

Uploaded skills do not auto-update. To move to a newer version, download the latest
zip, then open the skill's **⋮** menu and choose **Replace** — pick the new zip.
(Claude accepts the versioned file name as-is; no need to rename it.) Alternatively,
use **Uninstall** from the same menu and upload the new zip from scratch.

## License

[MIT](LICENSE.txt) © Oleksandr Kukhtin
