[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/SkillPanel/serena-setup/releases)
[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-purple.svg)](https://docs.anthropic.com/en/docs/claude-code)

# serena-setup

Claude Code plugin that configures [Serena MCP](https://github.com/oraios/serena) to work correctly in git worktrees.

## Why

Serena caches the project path at session start. When you create a git worktree and open Claude Code there, Serena still reads and edits files in the main repo — not your worktree. This plugin copies the necessary config, cache, and memories from the main repo to the worktree and verifies the setup after restart.

## Highlights

- **Copies** `.serena/` config, cache, and memories from main repo to worktree in one command
- **Verifies** Serena's active project path matches the worktree after restart
- **Detects** missing `--project-from-cwd` flag and guides you to fix MCP registration
- **Warns** about missing cache or memories in main repo before they become worktree problems

## Quick Start

```bash
# 1. Install the plugin
claude plugin add --global gh:SkillPanel/serena-setup

# 2. Navigate to your git worktree
cd /path/to/your/worktree

# 3. Run the setup skill
# (in Claude Code session)
/serena-setup:serena-setup
```

## Installation

### From GitHub (recommended)

```bash
claude plugin add --global gh:SkillPanel/serena-setup
```

### Manual (local development)

```bash
git clone https://github.com/SkillPanel/serena-setup.git
cd serena-setup
claude --plugin-dir .
```

## Usage

### Scenario 1: Setting up a new worktree

```bash
# Create a worktree
git worktree add ../my-feature feature-branch
cd ../my-feature

# Start Claude Code and run the skill
claude
# Then type: /serena-setup:serena-setup
```

The plugin runs in two phases:

**Phase 1** — copies `.serena/project.yml`, memories, and cache from the main repo. Then asks you to restart Claude Code.

**Phase 2** — after restart, verifies Serena's active path matches the worktree and runs onboarding if needed.

### Scenario 2: Serena edits files in the wrong directory

If you notice Serena reading or writing files in the main repo instead of your worktree:

```
/serena-setup:serena-setup
```

The plugin will detect the path mismatch and guide you through the fix.

## Configuration

No configuration files required. The plugin reads its context from:

| Source | Purpose |
|--------|---------|
| `git worktree list` | Identifies main repo path |
| `.serena/project.yml` | Serena project config (copied from main) |
| `.serena/cache/` | Pre-indexed symbols (copied from main if available) |
| `.serena/memories/` | Serena onboarding memories (copied from main if available) |
| `claude mcp list` | Validates Serena MCP registration and `--project-from-cwd` flag |

## How It Works

```
Phase 1 (first run)              Phase 2 (after restart)
┌─────────────────────┐          ┌─────────────────────────┐
│ Detect main repo    │          │ Parse Serena's active   │
│ via git worktree    │          │ project path from       │
│         │           │          │ system reminder         │
│         ▼           │          │         │               │
│ Copy .serena/ dir   │          │         ▼               │
│ (config, cache,     │ restart  │ Path matches worktree?  │
│  memories)          │────────▶ │   yes → check onboarding│
│         │           │          │   no  → show fix steps  │
│         ▼           │          │         │               │
│ Verify MCP has      │          │         ▼               │
│ --project-from-cwd  │          │ Done                    │
└─────────────────────┘          └─────────────────────────┘
```

The restart between phases is required because Serena caches the project path at MCP initialization. Copying `.serena/project.yml` alone is not enough — Serena must re-read it on startup.

## Requirements

- **Claude Code** CLI with plugin support
- **Serena MCP** registered globally with `--project-from-cwd` flag:
  ```bash
  claude mcp add-global serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context=claude-code --project-from-cwd
  ```
- **Git** with worktree support (Git 2.5+)
- **Python** (for `uvx` / Serena)

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `ERROR: Not in a worktree` | Run this plugin only from a git worktree, not the main repo |
| `ERROR: Main project has no .serena/project.yml` | Set up Serena in the main repo first — run `uvx --from git+https://github.com/oraios/serena serena project index --timeout 300` then onboarding |
| `ERROR: Serena MCP is registered but WITHOUT --project-from-cwd` | Re-register: `claude mcp remove serena` then add with `--project-from-cwd` flag |
| Serena still points to main repo after Phase 1 | You must restart Claude Code between Phase 1 and Phase 2 |

## Contributing

Issues and pull requests are welcome at [github.com/SkillPanel/serena-setup](https://github.com/SkillPanel/serena-setup).

## License

MIT — see [LICENSE](LICENSE) for details.
