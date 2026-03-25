# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Claude Code plugin (`serena-setup`) that configures Serena MCP for git worktrees.

## Plugin Structure

```
.claude-plugin/plugin.json   — plugin manifest
skills/<skill-name>/SKILL.md — skill definition (YAML frontmatter + instructions)
skills/<skill-name>/*.sh     — companion scripts referenced by the skill
```

Skills are invoked as `/serena-setup:<skill-name>`. Testing locally: `claude --plugin-dir .`

## Current Skills

- **serena-setup** (`/serena-setup:serena-setup`) — Two-phase worktree setup: copies `.serena/` from main repo, then verifies after restart
