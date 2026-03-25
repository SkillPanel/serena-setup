---
name: setup-serena
description: "Use when: (1) starting work in a new git worktree, (2) Serena edits/reads files in wrong directory, (3) Serena's active project path doesn't match current worktree, (4) user reports 'Serena points to main repo'"
allowed-tools: Bash(*/setup-serena.sh), mcp__serena__check_onboarding_performed, mcp__serena__onboarding, mcp__serena__write_memory, mcp__serena__list_memories, mcp__serena__list_dir
---

## Overview

Configures Serena MCP to work in a git worktree. Serena caches the project path at session start, so a restart is required after copying `.serena/project.yml` to the worktree — otherwise Serena continues reading/editing files in the main repo.

**Do NOT use in the main repository** — Serena works there correctly by default.

## Phase detection

Check if `.serena/project.yml` exists in the current directory.

### If `.serena/project.yml` EXISTS → Phase 2: Verify & finalize

The setup script already ran (before restart). Now verify and finalize:

**Step 1 — Validate Serena's active path:**

Parse the system reminder for the line:
```
The project with name '...' at <path> is activated.
```

Compare `<path>` with the current working directory (`$PWD`):
- **Match** → continue to Step 2
- **Mismatch** → tell user: "Serena points to `<path>` instead of `$PWD`. Restart Claude Code and run /setup-serena again." Then STOP.
- **Not found** → tell user: "Cannot read Serena's active project path from system reminder. Check Serena MCP status." Then STOP.

**Step 2 — Smart onboarding check:**

1. Call `list_memories` — if it returns memories, onboarding was already copied from main. Skip to Step 3.
2. If no memories: call `check_onboarding_performed` to confirm, then run `onboarding` via Serena MCP and create memories via `write_memory`.

**Step 3 — Done:**

Tell user: "Serena setup complete for this worktree."

### If `.serena/project.yml` DOES NOT exist → Phase 1: Setup

Run the setup script located in this skill's base directory:

```bash
<base-directory>/setup-serena.sh
```

Replace `<base-directory>` with the actual base directory shown at the top of this skill's context (e.g. `Base directory for this skill: /path/to/...`).

If it fails, show the error and stop.

If it succeeds, **carefully check the output for `[warn]` lines** about missing cache or memories in the main project. If warnings are present, tell the user PROMINENTLY what's missing and how to fix it BEFORE creating more worktrees:

```
⚠ Main project is not fully set up:
  - No cache: run `uvx --from git+https://github.com/oraios/serena serena project index --timeout 300` in main repo
  - No memories: run Serena onboarding in main repo (ask Claude "run Serena onboarding")

Fix these in the main repo, then future worktrees will get cache+memories automatically.
```

Then tell the user the restart procedure:

```
Now restart Claude Code and run /setup-serena again to finalize.

  1. Open a NEW terminal tab
  2. cd <worktree-path>
  3. claude --continue
  4. Run /setup-serena
```

## Common Mistakes

| Mistake | Consequence |
|---------|-------------|
| Skipping restart between phase 1 and 2 | Serena still points to main project path |
| Running in main repo instead of worktree | Script rejects — only needed in worktrees |
| Serena MCP without `--project-from-cwd` | Setup is pointless — Serena ignores worktree's project.yml |
