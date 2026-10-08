#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  setup-wsl-nix.sh — Prep a fresh WSL Debian guest for this flake ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# NOT Nix-managed. Run this once, inside the Debian WSL distro created
# by windows/bootstrap-windows.ps1, before cloning this flake:
#
#   bash windows/setup-wsl-nix.sh
#
# Idempotent: safe to re-run. Already-installed tools are detected and
# skipped; only missing pieces are installed.
#
# Installs:
#   - Determinate Nix (flakes enabled by default)
#   - Linuxbrew (Homebrew on Linux), with its documented apt prerequisites
#
# After this script succeeds, continue with this repo's own README.md
# (clone to ~/.config/nix, bootstrap-apt.sh, nix run .#hm -- switch).
set -euo pipefail

echo "── Checking for Nix ─────────────────────────────────────────────"
if command -v nix >/dev/null 2>&1 && nix --version >/dev/null 2>&1; then
  echo "  [OK] Nix already installed: $(nix --version)"
else
  echo "  [INSTALL] Nix not found, installing Determinate Nix..."
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm

  # Make nix available in this same shell without re-sourcing a login shell.
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck source=/dev/null
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  if command -v nix >/dev/null 2>&1; then
    echo "  [OK] Nix installed: $(nix --version)"
  else
    echo "Error: nix was not found on PATH after installation. Open a new shell and re-run this script." >&2
    exit 1
  fi
fi

echo ""
echo "── Checking flakes are enabled ──────────────────────────────────"
# Determinate Nix's docs confirm it writes /etc/nix/nix.conf with
# "carefully chosen values" but do not guarantee flakes is among them,
# so this is checked explicitly rather than assumed.
if nix config show 2>/dev/null | grep -q 'experimental-features.*flakes'; then
  echo "  [OK] flakes already enabled."
else
  echo "  [INSTALL] Enabling flakes for the current user..."
  mkdir -p "${HOME}/.config/nix"
  NIX_CONF="${HOME}/.config/nix/nix.conf"
  if [ -f "$NIX_CONF" ] && grep -q 'experimental-features' "$NIX_CONF"; then
    echo "  [OK] $NIX_CONF already sets experimental-features; leaving as-is."
  else
    echo "experimental-features = nix-command flakes" >> "$NIX_CONF"
    echo "  [OK] Added experimental-features to $NIX_CONF"
  fi
fi

echo ""
echo "── Checking for Linuxbrew ───────────────────────────────────────"
LINUXBREW_PREFIX="/home/linuxbrew/.linuxbrew"

if [ -x "${LINUXBREW_PREFIX}/bin/brew" ]; then
  echo "  [OK] Linuxbrew already installed: $("${LINUXBREW_PREFIX}/bin/brew" --version | head -n1)"
else
  echo "  [INSTALL] Installing apt prerequisites for Homebrew on Linux..."
  sudo apt-get update
  sudo apt-get install -y build-essential procps curl file git

  echo "  [INSTALL] Installing Linuxbrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x "${LINUXBREW_PREFIX}/bin/brew" ]; then
    echo "  [OK] Linuxbrew installed: $("${LINUXBREW_PREFIX}/bin/brew" --version | head -n1)"
  else
    echo "Error: brew was not found at ${LINUXBREW_PREFIX}/bin/brew after installation." >&2
    exit 1
  fi
fi

echo ""
echo "── Checking Linuxbrew shellenv in ~/.bashrc ─────────────────────"
BASHRC="${HOME}/.bashrc"
SHELLENV_LINE='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'

if [ -f "$BASHRC" ] && grep -qF "$SHELLENV_LINE" "$BASHRC"; then
  echo "  [OK] ~/.bashrc already loads brew shellenv."
else
  echo "  [INSTALL] Adding brew shellenv to ~/.bashrc..."
  {
    echo ""
    echo "# Linuxbrew (added by setup-wsl-nix.sh)"
    echo "$SHELLENV_LINE"
  } >> "$BASHRC"
  echo "  [OK] Added. Open a new shell (or source ~/.bashrc) to pick it up."
fi

echo ""
echo "Done! Nix and Linuxbrew are ready."
echo "Next: clone this flake to ~/.config/nix and follow its README.md."
