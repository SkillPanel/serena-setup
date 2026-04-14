#!/usr/bin/env bash
# Setup Serena MCP for a git worktree.
# Copies pre-indexed cache and installs a post-checkout hook for future worktrees.
# project.yml and memories should be committed to git.
set -euo pipefail

SERENA_INDEX_CMD="uvx --from git+https://github.com/oraios/serena serena project index --timeout 300"
MAIN_WORKTREE="$(git worktree list --porcelain | head -1 | awk '{print $2}')"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

install_hook() {
    local hook_dir="$MAIN_WORKTREE/.git/hooks"
    local hook_file="$hook_dir/post-checkout"
    local marker="# --- serena-worktree-hook ---"

    mkdir -p "$hook_dir"
    if [[ ! -f "$hook_file" ]]; then
        echo '#!/usr/bin/env bash' > "$hook_file"
        chmod +x "$hook_file"
    fi

    if grep -q "$marker" "$hook_file" 2>/dev/null; then
        sed -i "/$marker/,/$marker/d" "$hook_file"
        echo "[done] Updated post-checkout hook"
    else
        echo "[done] Installed post-checkout hook"
    fi

    {
        echo ""
        echo "$marker"
        cat "$SCRIPT_DIR/post-checkout-serena.sh"
        echo "$marker"
    } >> "$hook_file"
}

if [[ "$PWD" == "$MAIN_WORKTREE" ]]; then
    echo "=== Serena Hook Setup (main repo) ==="
    echo ""
    install_hook
    echo ""
    echo "Future worktrees will get .serena/cache automatically."
    echo "No other setup needed in main repo — Serena works here by default."
    exit 0
fi

echo "=== Serena Worktree Setup ==="
echo "  Worktree:  $PWD"
echo "  Main repo: $MAIN_WORKTREE"
echo ""

if [[ ! -f ".serena/project.yml" ]]; then
    if [[ -f "$MAIN_WORKTREE/.serena/project.yml" ]]; then
        echo "ERROR: .serena/project.yml is missing from this worktree"
        echo ""
        echo "It should be committed to git. In the main repo:"
        echo "  cd $MAIN_WORKTREE"
        echo "  git add .serena/project.yml .serena/memories/"
        echo "  git commit -m 'chore: track serena config'"
        echo ""
        echo "As a workaround, copying from main:"
        mkdir -p .serena
        cp "$MAIN_WORKTREE/.serena/project.yml" .serena/project.yml
        echo "[done] Copied .serena/project.yml from main"
    else
        echo "ERROR: Main project has no .serena/project.yml"
        echo ""
        echo "Serena must be set up in the main repo first:"
        echo "  cd $MAIN_WORKTREE"
        echo "  1. Pre-index:  $SERENA_INDEX_CMD"
        echo "  2. Onboarding: start Claude Code and ask \"run Serena onboarding\""
        echo "  3. Come back to this worktree and run /setup-serena again"
        exit 1
    fi
else
    echo "[ok]   .serena/project.yml present"
fi

# https://oraios.github.io/serena/02-usage/999_additional-usage.html
if [[ -d ".serena/cache" ]]; then
    echo "[skip] .serena/cache already exists"
elif [[ -d "$MAIN_WORKTREE/.serena/cache" ]] && [[ -n "$(ls -A "$MAIN_WORKTREE/.serena/cache" 2>/dev/null)" ]]; then
    cp -r "$MAIN_WORKTREE/.serena/cache" .serena/cache
    echo "[done] Copied .serena/cache from main (avoids re-indexing)"
else
    echo "[warn] Main has no pre-indexed cache — worktree will need to index from scratch"
    echo "       Fix: cd $MAIN_WORKTREE && $SERENA_INDEX_CMD"
fi

if [[ -d ".serena/memories" ]] && [[ -n "$(ls -A ".serena/memories" 2>/dev/null)" ]]; then
    echo "[skip] .serena/memories already exists"
elif [[ -d "$MAIN_WORKTREE/.serena/memories" ]] && [[ -n "$(ls -A "$MAIN_WORKTREE/.serena/memories" 2>/dev/null)" ]]; then
    cp -r "$MAIN_WORKTREE/.serena/memories" .serena/memories
    echo "[done] Copied .serena/memories from main"
else
    echo "[warn] Main has no Serena memories — run onboarding in main repo first"
fi

if [[ -f "CLAUDE.local.md" ]]; then
    echo "[skip] CLAUDE.local.md already exists"
elif [[ -f "$MAIN_WORKTREE/CLAUDE.local.md" ]]; then
    cp "$MAIN_WORKTREE/CLAUDE.local.md" CLAUDE.local.md
    echo "[done] Copied CLAUDE.local.md from main"
else
    echo "[skip] No CLAUDE.local.md in main repo"
fi

install_hook

echo ""
echo "=== Serena configured for worktree ==="
echo "  .serena/project.yml  — from git"
echo "  .serena/memories/    — $(if [[ -d .serena/memories ]] && [[ -n "$(ls -A .serena/memories 2>/dev/null)" ]]; then echo "copied from main"; else echo "not available"; fi)"
echo "  .serena/cache/       — $(if [[ -d .serena/cache ]]; then echo "copied from main"; else echo "not available"; fi)"
echo "  CLAUDE.local.md      — $(if [[ -f CLAUDE.local.md ]]; then echo "present"; else echo "not found"; fi)"
echo "  post-checkout hook   — installed"
