[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/SkillPanel/claude-plugins/releases)
[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-purple.svg)](https://docs.anthropic.com/en/docs/claude-code)

# serena-setup

Claude Code plugin that makes [Serena MCP](https://github.com/oraios/serena) work in git worktrees.

## The Problem

You use git worktrees to work on multiple branches in parallel. You use Serena for semantic code navigation in Claude Code. But when you open a worktree, Serena keeps reading and editing files in your main repo — not the worktree you're actually working in.

## What This Plugin Does

One slash command — `/serena-setup:serena-setup` — and Serena works in your worktree. The plugin:

- Copies pre-indexed cache and memories from the main repo (avoids re-indexing and onboarding)
- Installs a `post-checkout` git hook so future worktrees get cache automatically
- Activates the project in Serena for the current session

No restart required. No manual file copying.

## Quick Start

```bash
# Install once
claude plugin marketplace add gh:SkillPanel/claude-plugins
claude plugin install serena-setup

# In any git worktree, start Claude Code and run:
/serena-setup:serena-setup
```

Run it once in the main repo to install the hook — future worktrees created with `claude -w` will have cache ready automatically.

## Setting Up a New Repo

**1. Register Serena MCP globally (once):**

```bash
claude mcp add --scope user serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context=claude-code --project-from-cwd
```

**2. In your repo, pre-index the project:**

```bash
uvx --from git+https://github.com/oraios/serena serena project index --timeout 300
```

**3. Run Serena onboarding** — start Claude Code and ask "run Serena onboarding".

**4. Commit Serena config to git:**

```bash
git add .serena/project.yml .serena/memories/
git commit -m 'chore: track serena config'
```

**5. Install the post-checkout hook** — run `/serena-setup:serena-setup` in the main repo.

Now `claude -w` will create worktrees with cache ready. Run `/serena-setup:serena-setup` in the worktree to activate the project.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with plugin support
- [Serena MCP](https://github.com/oraios/serena) registered with `--project-from-cwd` flag
- Git 2.5+ (worktree support)

## Installation

```bash
# Add marketplace and install plugin
claude plugin marketplace add gh:SkillPanel/claude-plugins
claude plugin install serena-setup
```

**Local development:**

```bash
git clone https://github.com/SkillPanel/claude-plugins.git
claude --plugin-dir ./claude-plugins
```

## License

MIT — see [LICENSE](LICENSE) for details.
