#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  bootstrap-apt.sh — Restore apt + snap packages on fresh system ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Captured from the current system's manually-installed packages.
# Run once on a fresh Debian/Ubuntu ARM system:
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
  libreadline8t64 \
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
  openssl-provider-legacy \
  iproute2 \
  nftables \
  traceroute \
  lsof \
  network-manager \
  network-manager-openvpn-gnome \
  openvpn \
  openvpn3-client \
  cloudflared \
  dhcpcd-base

####################################################################
# 3 ▸ Virtualization & containers
####################################################################
echo "── Virtualization & containers ─────────────────────────────────"
apt-get install -y \
  podman \
  podman-compose \
  qemu-system-arm \
  libvirt-daemon \
  libvirt-daemon-system \
  fuse3 \
  spice-vdagent

####################################################################
# 4 ▸ Desktop & KDE
####################################################################
echo "── Desktop environment ─────────────────────────────────────────"
apt-get install -y \
  task-kde-desktop \
  plasma-discover-backend-flatpak \
  plasma-discover-backend-snap \
  yakuake

####################################################################
# 5 ▸ Applications
####################################################################
echo "── Applications ────────────────────────────────────────────────"
apt-get install -y \
  chromium \
  thunderbird \
  mc \
  gitg \
  kdiff3 \
  tigervnc-standalone-server \
  usbmuxd \
  libimobiledevice-utils

####################################################################
# 6 ▸ Dev runtimes & tools (apt-managed, not in Nix)
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
# 7 ▸ Third-party apt packages (require external repos)
####################################################################
echo "── Third-party packages ────────────────────────────────────────"

# VS Code
if ! command -v code &>/dev/null; then
  echo "  Installing VS Code..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/microsoft.gpg
  echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list
  apt-get update
  apt-get install -y code
fi

# Cursor
if ! command -v cursor &>/dev/null; then
  echo "  Cursor: install manually from https://cursor.com (no arm64 apt repo)"
fi

# Pastemax
if ! command -v pastemax &>/dev/null; then
  apt-get install -y pastemax 2>/dev/null || echo "  Pastemax: install manually if needed"
fi

####################################################################
# 8 ▸ Snap packages
####################################################################
echo "── Snap packages ───────────────────────────────────────────────"
if command -v snap &>/dev/null; then

  # Classic snaps (need --classic)
  CLASSIC_SNAPS=(
    aws-cli
    dataspell
    dotnet
    helm
    intellij-idea-ultimate
    kubectl
    pycharm-professional
    rider
    rustrover
  )
  for pkg in "${CLASSIC_SNAPS[@]}"; do
    if ! snap list "$pkg" &>/dev/null; then
      echo "  Installing snap: $pkg (classic)..."
      snap install "$pkg" --classic 2>/dev/null || echo "  Failed: $pkg"
    fi
  done

  # Confined snaps
  CONFINED_SNAPS=(
    freelens
    freetube
    glab
    kubewall
    simple-openvpn-client
    simple-openvpn-client-gui
    teams-for-linux
    telegram-desktop
  )
  for pkg in "${CONFINED_SNAPS[@]}"; do
    if ! snap list "$pkg" &>/dev/null; then
      echo "  Installing snap: $pkg..."
      snap install "$pkg" 2>/dev/null || echo "  Failed: $pkg"
    fi
  done

else
  echo "  snapd not installed, skipping snap packages"
fi

####################################################################
# 9 ▸ Cleanup
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
