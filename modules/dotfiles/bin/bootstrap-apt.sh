#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  bootstrap-apt.sh — Restore apt packages on fresh WSL/Debian    ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Run once on a fresh Debian/Ubuntu x86_64 system (including WSL):
#   sudo ~/bin/bootstrap-apt.sh
#
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: run with sudo" >&2
  exit 1
fi

REAL_USER="${SUDO_USER:-$(logname)}"

echo "── Updating package lists ──────────────────────────────────────"
apt-get update

####################################################################
# 1 ▸ Build toolchain & dev libraries
####################################################################
echo "── Build toolchain & dev libraries ─────────────────────────────"
apt-get install -y \
  build-essential \
  automake \
  cmake \
  make \
  gdb \
  pkg-config \
  libcurl4-openssl-dev \
  libffi-dev \
  libicu-dev \
  libncurses-dev \
  libpython3-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libstdc++-12-dev \
  libxml2-dev \
  uuid-dev \
  zlib1g-dev

####################################################################
# 2 ▸ Core system & networking
####################################################################
echo "── Core system & networking ────────────────────────────────────"
apt-get install -y \
  ca-certificates \
  curl \
  wget \
  gnupg \
  openssh-client \
  iproute2 \
  lsof

####################################################################
# 3 ▸ Containers
####################################################################
echo "── Containers ──────────────────────────────────────────────────"
apt-get install -y \
  podman \
  podman-compose \
  fuse3

####################################################################
# 4 ▸ Dev runtimes & tools (apt-managed, not in Nix)
####################################################################
echo "── Dev runtimes (apt-managed) ──────────────────────────────────"
apt-get install -y \
  git \
  tmux \
  ripgrep

# .NET SDK (Microsoft repo)
if ! dpkg -s dotnet-sdk-10.0 &>/dev/null; then
  echo "  Installing .NET SDK 10.0..."
  apt-get install -y packages-microsoft-prod 2>/dev/null || true
  apt-get update
  apt-get install -y \
    dotnet-sdk-10.0 \
    dotnet-runtime-10.0 \
    aspnetcore-runtime-10.0 \
    aspnetcore-targeting-pack-10.0
fi

# Azure CLI
if ! command -v az &>/dev/null; then
  echo "  Installing Azure CLI..."
  apt-get install -y azure-cli
fi

# Zulu JDK 21
if ! dpkg -s zulu21-jdk &>/dev/null; then
  echo "  Installing Zulu JDK 21..."
  apt-get install -y zulu21-jdk 2>/dev/null || echo "  (add Azul repo first if this fails)"
fi

####################################################################
# 5 ▸ Third-party apt packages (require external repos)
####################################################################
echo "── Third-party packages ────────────────────────────────────────"

# VS Code (accessible from WSL via 'code' if Windows VS Code is installed,
# but install native too for headless use)
if ! command -v code &>/dev/null; then
  echo "  Installing VS Code..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/microsoft.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list
  apt-get update
  apt-get install -y code
fi

####################################################################
# 6 ▸ Cleanup
####################################################################
echo "── Cleanup ─────────────────────────────────────────────────────"
apt-get autoremove -y
apt-get clean

echo ""
echo "══════════════════════════════════════════════════════════════════"
echo "  Done! System-level packages restored."
echo ""
echo "  Next steps:"
echo "    1. Log out and back in (for group memberships)"
echo "    2. nix run ~/.config/nix#hm -- switch"
echo "══════════════════════════════════════════════════════════════════"
