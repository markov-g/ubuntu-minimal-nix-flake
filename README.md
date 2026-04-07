# Dr G's Home-Manager Flake (aarch64-linux)

Reproducible Home-Manager setup for Debian/Ubuntu on ARM64. Manages ~80 CLI tools, editors (Neovim + Helix), shell config, and dotfiles through a single Nix flake. Lives at `~/.config/nix/`.

## Prerequisites

- Debian or Ubuntu on ARM64 (aarch64-linux)
- [Nix package manager](https://nixos.org/download/) with flakes enabled
- Git

Enable flakes if you haven't already:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

## Initial Setup

### 1. Clone the flake

```bash
git clone <repo-url> ~/.config/nix
```

### 2. Install system-level packages (once)

Packages that Nix can't replace (build toolchain, .NET SDK, KDE desktop, JetBrains IDEs, etc.) are handled by apt and snap:

```bash
sudo ~/bin/bootstrap-apt.sh
```

Log out and back in after this for group memberships to take effect.

### 3. Apply the Home-Manager configuration

```bash
nix run ~/.config/nix#hm -- switch
```

This will:

- Install all Nix-managed packages (~80 CLI tools, editors, etc.)
- Symlink dotfiles (nvim, helix, tmux, mise, k9s, inputrc, bashrc)
- Place utility scripts in `~/bin/`
- Bootstrap tmux plugin manager (TPM)
- Generate an SSH key if none exists
- Seed KDE config on first run (copied, not symlinked)

Open a new shell -- you should see an oh-my-bash prompt with everything on your PATH.

### 4. Restore KDE settings (optional)

If migrating from another machine with saved KDE snapshots:

```bash
~/bin/kde-restore.sh
```

Then log out and back in to apply panel/widget changes.

## Day-to-Day Usage

### Apply config changes

After editing any file in this repo:

```bash
nix run ~/.config/nix#hm -- switch
```

### Full update (inputs + rebuild + garbage collection)

Updates nixpkgs and home-manager to latest, rebuilds, and cleans old generations:

```bash
~/bin/nix-update-all.sh
```

### Check flake validity

```bash
nix flake check
```

## KDE Config Management

KDE configs are mutable -- they're copied on first run, not symlinked. Use the backup/restore scripts to version-control them:

```bash
# Save current KDE customizations into the flake
~/bin/kde-backup.sh

# Restore KDE config on a fresh system
~/bin/kde-restore.sh
```

## Adding a New User or Host

Edit `flake.nix` and add an entry to `homeConfigurations`:

```nix
homeConfigurations = {
  "ubuntu" = mkHomeUser { user = "ubuntu"; host = "default"; };
  "devel" = mkHomeUser { user = "devel"; host = "devbox"; };
};
```

## Project Structure

```
flake.nix                    # Inputs, mkHomeUser helper, outputs
modules/
  home.nix                   # Main HM module (packages, shell, programs, dotfiles, activation)
  dotfiles/
    .bashrc.extra            # oh-my-bash + tmux auto-start
    .tmux.conf               # Catppuccin + TPM + vim-tmux-navigator
    .inputrc                 # Vi-mode readline
    nvim/                    # Full LazyVim configuration
    helix/                   # Helix editor (secondary, quick SSH edits)
    mise/config.toml         # Polyglot runtime manager
    k9s/config.yaml          # Kubernetes TUI
    kde/                     # KDE Plasma config snapshots (mutable)
    bin/                     # Utility scripts deployed to ~/bin/
```

## What Goes Where

| Layer | Managed by | Examples |
|---|---|---|
| CLI tools, editors, dotfiles | Nix (this flake) | bat, eza, ripgrep, neovim, helix, tmux config |
| Build toolchain, .NET SDK, KDE desktop, JetBrains IDEs | apt + snap (`bootstrap-apt.sh`) | build-essential, dotnet-sdk, VS Code, IntelliJ |
| KDE Plasma appearance | Copied on first run, then mutable | kdeglobals, kwinrc, plasmashellrc |
| SSH config | Self-managed | `~/.ssh/config` |

## Troubleshooting

| Symptom | Fix |
|---|---|
| HM refuses to overwrite existing dotfiles | The `#hm` wrapper already passes `-b backup`; check for `*.backup` files |
| `command not found: home-manager` | Ensure `programs.home-manager.enable = true;` in `home.nix` and re-switch |
| Wrong arch error | Change `system = "aarch64-linux"` in `flake.nix` to your correct tuple |

## Rollback / Uninstall

```bash
home-manager switch --rollback      # roll back to previous generation
home-manager generations            # list all generations
home-manager uninstall              # remove all HM symlinks
```

## License

MIT
