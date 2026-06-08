# A2v10 Skill for Claude

A skill for developing on the **A2v10 Platform** — a generic runtime for building
business applications. Once active, Claude loads it automatically when your request
matches (A2v10, `model.json`, `view.vxaml`, SQL stored procedures, and so on).

It can be added to Claude in **two ways**, depending on how you use Claude:

| How you use Claude | Method |
|---|---|
| **Claude Code** — the CLI you run in a terminal | [Method 1 — plugin marketplace](#method-1--install-as-a-claude-code-plugin) |
| **Claude app** (desktop or web) — *Customize → Skills* | [Method 2 — upload the skill](#method-2--upload-the-skill-in-the-claude-app) |

> ℹ️ "Claude Code" is the **command-line tool** you run from a terminal — *not* the
> "Code" tab in the Claude desktop app. If you work in the desktop or web app, use
> **Method 2**.

## Method 1 — Install as a Claude Code plugin

This repository is a Claude Code plugin marketplace shipping the `a2v10` plugin.

### Prerequisite: the Claude Code CLI

If you don't already have Claude Code:

1. Install [Node.js](https://nodejs.org/) (LTS version).
2. Install Claude Code:

   ```
   npm install -g @anthropic-ai/claude-code
   ```

3. Start it in your project folder:

   ```
   claude
   ```

4. Log in when prompted. Type `/help` to confirm you're at the Claude Code prompt —
   the `/plugin` commands below only work there.

> Other platforms and full instructions: <https://docs.claude.com/en/docs/claude-code/overview>

### Install

At the Claude Code prompt:

```
/plugin marketplace add a2v10/llm
/plugin install a2v10@a2v10-dev
```

### Update

The marketplace catalog and the installed plugin update independently:

```
/plugin marketplace update a2v10-dev   # refresh the catalog (versions, metadata)
/plugin update a2v10@a2v10-dev         # update the installed plugin
```

Run `/plugin` → **Manage plugins** to check the installed version. Restart Claude Code
(or reload the window) if an update doesn't take effect immediately.

## Method 2 — Upload the skill in the Claude app

Use this if you work in the Claude **desktop or web app**. No CLI required.
Custom Skills are available on Pro, Max, Team, and Enterprise plans with code
execution enabled.

1. Download the latest **`a2v10-*.zip`** from the
   [Releases page](https://github.com/a2v10/llm/releases/latest).
2. In Claude, open **Customize → Skills**.
3. Click **➕ → Create skill → Upload a skill**.
4. Select the downloaded zip.

The skill appears under **Personal skills** and is used automatically when relevant.

### Update

Uploaded skills do not auto-update. To move to a newer version, download the latest
`a2v10-*.zip` from the [Releases page](https://github.com/a2v10/llm/releases/latest),
then open the skill's **⋮** menu and choose **Replace** — pick the new zip. (Claude
accepts the versioned file name as-is; no need to rename it.)

Alternatively, use **Uninstall** from the same menu and upload the new zip from scratch.

## License

[MIT](LICENSE.txt) © Oleksandr Kukhtin
