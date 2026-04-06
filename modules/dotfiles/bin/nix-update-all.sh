#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  nix-update-all.sh — Full Nix + Home-Manager update             ║
# ╚══════════════════════════════════════════════════════════════════╝
set -euo pipefail

FLAKE_DIR="${HOME}/.config/nix"

echo "── Updating flake inputs ───────────────────────────────────────"
cd "$FLAKE_DIR"
nix flake update

echo "── Rebuilding Home-Manager ─────────────────────────────────────"
nix run .#hm -- switch

echo "── Garbage collection (older than 7 days) ──────────────────────"
nix-collect-garbage --delete-older-than 7d

echo "── Store optimisation ──────────────────────────────────────────"
nix store optimise

echo ""
echo "Done! All packages updated."
