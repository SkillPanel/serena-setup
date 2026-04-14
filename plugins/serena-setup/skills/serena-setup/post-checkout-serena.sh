#!/usr/bin/env bash
# Serena worktree hook — copies .serena/cache from main repo to new worktrees.
# project.yml and memories should be committed to git.
# Installed by /serena-setup skill. Appended to .git/hooks/post-checkout.

# Only run on new worktree/clone (null-ref in $1)
# return||exit: works both when sourced (appended into hook) and run standalone
[ "$1" = "0000000000000000000000000000000000000000" ] || return 0 2>/dev/null || exit 0

MAIN_REPO="$(git worktree list --porcelain | head -1 | awk '{print $2}')"

# Skip if we're in the main repo (clone, not worktree)
[ "$PWD" != "$MAIN_REPO" ] || return 0 2>/dev/null || exit 0

# Skip if main repo has no Serena config
[ -f "$MAIN_REPO/.serena/project.yml" ] || return 0 2>/dev/null || exit 0

# Copy project.yml if missing (not committed to git)
if [ ! -f ".serena/project.yml" ] && [ -f "$MAIN_REPO/.serena/project.yml" ]; then
    mkdir -p .serena
    cp "$MAIN_REPO/.serena/project.yml" .serena/project.yml
    echo "[serena-hook] Copied .serena/project.yml from main repo" >&2
fi

# Copy cache if missing (gitignored, never comes from checkout)
if [ ! -d ".serena/cache" ] && [ -d "$MAIN_REPO/.serena/cache" ] && [ -n "$(ls -A "$MAIN_REPO/.serena/cache" 2>/dev/null)" ]; then
    mkdir -p .serena
    cp -r "$MAIN_REPO/.serena/cache" .serena/cache
    echo "[serena-hook] Copied .serena/cache from main repo" >&2
fi

# Copy CLAUDE.local.md if missing (gitignored, never comes from checkout)
if [ ! -f "CLAUDE.local.md" ] && [ -f "$MAIN_REPO/CLAUDE.local.md" ]; then
    cp "$MAIN_REPO/CLAUDE.local.md" CLAUDE.local.md
    echo "[serena-hook] Copied CLAUDE.local.md from main repo" >&2
fi
