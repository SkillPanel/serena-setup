#!/usr/bin/env bash
# Setup Serena MCP for a git worktree.
# Ensures Serena's active project points to the worktree directory, not the main repo.
set -euo pipefail

CURRENT_DIR="$PWD"
SERENA_INDEX_CMD="uvx --from git+https://github.com/oraios/serena serena project index --timeout 300"
MAIN_WORKTREE="$(git worktree list --porcelain | head -1 | awk '{print $2}')"

# --- Guard: must be in a worktree ---
if [[ "$CURRENT_DIR" == "$MAIN_WORKTREE" ]]; then
    echo "ERROR: Not in a worktree. Run /setup-serena from a git worktree, not from the main repo."
    exit 1
fi

echo "=== Serena Worktree Setup ==="
echo "  Worktree:  $CURRENT_DIR"
echo "  Main repo: $MAIN_WORKTREE"
echo ""

# --- Validate main project readiness ---
if [[ ! -f "$MAIN_WORKTREE/.serena/project.yml" ]]; then
    echo "ERROR: Main project has no .serena/project.yml"
    echo ""
    echo "Serena must be set up in the main repo first. Go to:"
    echo "  cd $MAIN_WORKTREE"
    echo ""
    echo "Then run these steps in order:"
    echo "  1. Pre-index:  $SERENA_INDEX_CMD"
    echo "  2. Onboarding: start Claude Code and ask \"run Serena onboarding\""
    echo "  3. Come back to this worktree and run /setup-serena again"
    exit 1
fi

# --- Check what's available in main ---
has_cache=false
has_memories=false
[[ -d "$MAIN_WORKTREE/.serena/cache" ]] && [[ -n "$(ls -A "$MAIN_WORKTREE/.serena/cache" 2>/dev/null)" ]] && has_cache=true
[[ -d "$MAIN_WORKTREE/.serena/memories" ]] && [[ -n "$(ls -A "$MAIN_WORKTREE/.serena/memories" 2>/dev/null)" ]] && has_memories=true

WARNINGS=""
$has_cache || WARNINGS+="[warn] Main has no pre-indexed cache — worktree will need to index from scratch\n       Fix: cd $MAIN_WORKTREE && $SERENA_INDEX_CMD\n"
$has_memories || WARNINGS+="[warn] Main has no memories — worktree will need onboarding after restart\n       Fix: cd $MAIN_WORKTREE && start Claude Code, ask \"run Serena onboarding\"\n"

if [[ -n "$WARNINGS" ]]; then
    echo -e "$WARNINGS"
    echo "Continuing anyway — these can be fixed later."
    echo ""
fi

# --- Step 1: Copy .serena from main ---
if [[ -f ".serena/project.yml" ]]; then
    echo "[skip] .serena/project.yml already exists"
else
    mkdir -p .serena
    cp "$MAIN_WORKTREE/.serena/project.yml" .serena/project.yml
    echo "[done] Copied .serena/project.yml from main"

    if $has_memories; then
        mkdir -p .serena/memories
        cp -r "$MAIN_WORKTREE/.serena/memories/"* .serena/memories/
        echo "[done] Copied memories from main"
    fi

    # Copy pre-indexed cache to avoid re-indexing per worktree
    # See: https://oraios.github.io/serena/02-usage/999_additional-usage.html
    if $has_cache; then
        cp -r "$MAIN_WORKTREE/.serena/cache" .serena/cache
        echo "[done] Copied cache from main (avoids re-indexing)"
    fi
fi

# --- Step 2: Verify Serena MCP registration ---
SERENA_STATUS="not registered"
if command -v claude &>/dev/null; then
    MCP_LIST="$(claude mcp list 2>/dev/null || true)"
    if [[ "$MCP_LIST" == *serena*project-from-cwd* ]]; then
        SERENA_STATUS="global (--project-from-cwd)"
    elif [[ "$MCP_LIST" == *serena* ]]; then
        echo "ERROR: Serena MCP is registered but WITHOUT --project-from-cwd"
        echo ""
        echo "Without --project-from-cwd, Serena ignores the worktree's project.yml."
        echo "Re-register with:"
        echo ""
        echo "  claude mcp remove serena"
        echo "  claude mcp add-global serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context=claude-code --project-from-cwd"
        echo ""
        echo "Then run /setup-serena again."
        exit 1
    fi

    if [[ "$SERENA_STATUS" == "not registered" ]]; then
        echo "ERROR: Serena MCP is not registered in Claude Code"
        echo ""
        echo "Register globally:"
        echo ""
        echo "  claude mcp add-global serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context=claude-code --project-from-cwd"
        echo ""
        echo "Then run /setup-serena again."
        exit 1
    fi
fi


# --- Summary ---
echo ""
echo "=== Serena configured for worktree ==="
echo "  .serena/project.yml  — copied from main"
echo "  .serena/memories/    — $(ls .serena/memories/ 2>/dev/null | wc -l) files"
echo "  .serena/cache/       — $(if [[ -d .serena/cache ]]; then echo "copied"; else echo "not available"; fi)"
echo "  MCP serena           — $SERENA_STATUS"
echo ""
echo "=== Next steps ==="
echo "  1. RESTART Claude Code session"
echo "  2. Run /setup-serena again to finalize"
echo ""
echo "=== Safe restart procedure ==="
echo "  1. Open a NEW terminal tab"
echo "  2. cd $CURRENT_DIR"
echo "  3. claude --continue"
echo "  4. Close old terminal AFTER new session is running"
