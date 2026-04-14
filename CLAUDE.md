# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Claude Code plugin marketplace hosting multiple plugins under `plugins/`.

## Repo Structure

```
.claude-plugin/marketplace.json              — marketplace manifest (lists all plugins)
plugins/<plugin>/.claude-plugin/plugin.json  — per-plugin manifest
plugins/<plugin>/skills/<skill>/SKILL.md     — skill definition (YAML frontmatter + instructions)
plugins/<plugin>/skills/<skill>/*.{sh,py}    — companion scripts referenced by the skill
```

Skills are invoked as `/<plugin>:<skill>`. Testing locally: `claude --plugin-dir plugins/<plugin>`

## Releasing a New Version

When bumping a plugin's version, update **both** declarations:

1. `plugins/<plugin>/.claude-plugin/plugin.json` — `version` field
2. `.claude-plugin/marketplace.json` — `version` in the plugin entry under `plugins[]`

Versions for the same plugin MUST match across both files.

## Current Plugins

- **serena-setup** (`/serena-setup:serena-setup`) — Copies `.serena/` from main repo to worktree and installs a `post-checkout` hook for automatic setup of future worktrees
- **jdtls-lombok-fix** — Auto-triggered skill that patches the `jdtls-lsp` plugin's `marketplace.json` to pass `-javaagent:lombok.jar` to JDTLS, removing the flood of false-positive Lombok errors (`log cannot be resolved`, `builder() undefined`, etc.). Background: anthropics/claude-plugins-official#1000
