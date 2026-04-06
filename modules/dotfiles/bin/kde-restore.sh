#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  kde-restore.sh — Restore KDE config from flake snapshots       ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Run on a fresh system to restore your KDE setup:
#   ~/bin/kde-restore.sh
#
# Backs up existing configs to *.bak before overwriting.
#
set -euo pipefail

FLAKE_KDE="${HOME}/.config/nix/modules/dotfiles/kde"

if [ ! -d "$FLAKE_KDE" ]; then
  echo "Error: KDE snapshot directory not found: $FLAKE_KDE" >&2
  exit 1
fi

KDE_FILES=(
  kdeglobals
  kglobalshortcutsrc
  kwinrc
  kwinoutputconfig.json
  plasma-org.kde.plasma.desktop-appletsrc
  plasmashellrc
  yakuakerc
  dolphinrc
  konsolesshconfig
)

echo "── Restoring KDE configs from flake ────────────────────────────"
for f in "${KDE_FILES[@]}"; do
  src="$FLAKE_KDE/$f"
  dst="$HOME/.config/$f"
  if [ -f "$src" ]; then
    # Backup existing config
    [ -f "$dst" ] && cp "$dst" "${dst}.bak"
    cp "$src" "$dst"
    echo "  ✓ $f"
  else
    echo "  ⊘ $f (not in snapshot, skipping)"
  fi
done

echo ""
echo "Done! KDE configs restored."
echo "Log out and back in (or run 'kquitapp6 plasmashell && kstart6 plasmashell')"
echo "to apply panel/widget changes."
