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

## Releasing a New Version

When bumping the plugin version, update **all** version declarations:

1. `.claude-plugin/plugin.json` — `version` field
2. `.claude-plugin/marketplace.json` — `version` in the plugin entry under `plugins[]`
3. `skills/<plugin-name>/pyproject.toml` — `version` in `[project]` (if exists)

All versions MUST match. The root `metadata.version` in `marketplace.json` should also be updated if present.

## Current Skills

- **serena-setup** (`/serena-setup:serena-setup`) — Copies `.serena/` from main repo to worktree and installs a `post-checkout` hook for automatic setup of future worktrees
