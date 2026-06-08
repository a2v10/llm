# A2v10 Claude Code Skill

A Claude Code skill for developing on the **A2v10 Platform** — a generic runtime for 
building business applications. 

This repository is a Claude Code plugin marketplace shipping the `a2v10` plugin.

## ⚠️ What is "Claude Code"?

**Claude Code is a command-line tool (CLI) — it is _not_ the "Code" tab inside the Claude Desktop app.**

This is the most common point of confusion. The "Code" tab in Claude Desktop is a different feature and has **no** `/plugin` command — none of the commands below will work there.

Everything in this README runs in the **Claude Code CLI**: a separate program you install and run from a terminal (PowerShell, Windows Terminal, macOS Terminal, bash, etc.).

### Install the Claude Code CLI

1. Install [Node.js](https://nodejs.org/) (LTS version) if you don't have it.
2. Install Claude Code globally:

   ```
   npm install -g @anthropic-ai/claude-code
   ```

3. Open a terminal **in your project folder** and start it:

   ```
   claude
   ```

4. Log in when prompted (with your Claude account or API key).

You'll know you're in the right place when you see the Claude Code prompt in your terminal and can type `/help` to list available commands. The `/plugin` commands below only work **inside this prompt**.

> Full install instructions and other platforms: <https://docs.claude.com/en/docs/claude-code/overview>

## Installation

Inside the **Claude Code CLI prompt** (not Claude Desktop), run:

```
/plugin marketplace add a2v10/llm
/plugin install a2v10@a2v10-dev
```

The skill is model-invoked: once installed, Claude loads it automatically when your request matches.

## Updating

The plugin is split into two parts that update independently:

1. **Refresh the marketplace metadata** — pulls the latest catalog (new plugins, version bumps, descriptions):

   ```
   /plugin marketplace update a2v10-dev
   ```

2. **Update the installed plugin** — fetches the new version of the `a2v10` plugin itself:

   ```
   /plugin update a2v10@a2v10-dev
   ```

You can verify the installed version at any time:

```
/plugin
```

Then open **Manage plugins** and check the version shown for `a2v10` against the latest published version. Restart Claude Code (or reload the window) if an updated skill doesn't take effect immediately.

## License

[MIT](LICENSE.txt) © Oleksandr Kukhtin