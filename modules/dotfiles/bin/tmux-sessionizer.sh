#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  tmux-sessionizer — fuzzy-pick a project and open in tmux       ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Bind to a key in tmux:
#   bind C-f run-shell "~/bin/tmux-sessionizer.sh"
#
set -euo pipefail

SEARCH_DIRS=(
  "$HOME/projects"
  "$HOME/git-repos"
  "$HOME/.config/nix"
)

# Collect existing dirs
dirs=()
for d in "${SEARCH_DIRS[@]}"; do
  [ -d "$d" ] && dirs+=("$d")
done

if [ ${#dirs[@]} -eq 0 ]; then
  echo "No project directories found" >&2
  exit 1
fi

selected=$(find "${dirs[@]}" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | fzf)

if [ -z "$selected" ]; then
  exit 0
fi

session_name=$(basename "$selected" | tr . _)

if ! tmux has-session -t="$session_name" 2>/dev/null; then
  tmux new-session -ds "$session_name" -c "$selected"
fi

tmux switch-client -t "$session_name"
