#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  kde-backup.sh — Snapshot current KDE config into the flake     ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Run this after making KDE customizations you want to keep:
#   ~/bin/kde-backup.sh
#
set -euo pipefail

FLAKE_KDE="${HOME}/.config/nix/modules/dotfiles/kde"
mkdir -p "$FLAKE_KDE"

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

echo "── Backing up KDE configs to flake ─────────────────────────────"
for f in "${KDE_FILES[@]}"; do
  src="$HOME/.config/$f"
  if [ -f "$src" ]; then
    cp "$src" "$FLAKE_KDE/$f"
    echo "  ✓ $f"
  else
    echo "  ⊘ $f (not found, skipping)"
  fi
done

echo ""
echo "Done! KDE configs saved to: $FLAKE_KDE"
echo "Commit the changes to preserve them in version control."
