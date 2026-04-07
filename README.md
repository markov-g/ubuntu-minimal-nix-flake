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

## Neovim Setup

The Neovim configuration lives in `modules/dotfiles/nvim/` and is symlinked into the Nix store (read-only). It's built on [LazyVim](https://www.lazyvim.org/) with extensive customizations.

### Architecture

```
nvim/
  init.lua                          # Entry point: require("config.lazy")
  lua/
    config/
      lazy.lua                      # lazy.nvim bootstrap + LazyVim spec (language extras, editor extras, DAP, etc.)
      options.lua                   # Editor options (relative numbers, 2-space tabs, treesitter folding, etc.)
      keymaps.lua                   # Custom keybindings (jk escape, line moves, centered scroll, lazygit, etc.)
      autocmds.lua                  # Auto-commands (yank highlight, prose wrapping, nix indent, close-with-q)
    plugins/
      lsp.lua                       # LSP server config + Mason/Nix dual management + Treesitter parsers
      tools.lua                     # Editor plugins (catppuccin, oil, harpoon, neotest, lazygit, dadbod, etc.)
      ai.lua                        # AI plugins (Copilot inline + Avante/Claude chat panel)
```

Because the config is in the Nix store, `lazy-lock.json` is redirected to `~/.local/share/nvim/lazy-lock.json`.

### LSP: Dual Nix/Mason Management

LSP servers are managed through two paths:

- **Nix-managed** (`mason = false`): Installed via `home.packages` in `home.nix`, already on PATH. Mason is told not to touch these.
- **Mason-managed**: Everything else. Mason auto-installs these on first open.

Nix-managed servers (defined in `lsp.lua`):

| Server | Language |
|--------|----------|
| `nil_ls` | Nix |
| `gopls` | Go |
| `rust_analyzer` | Rust |
| `clangd` | C/C++ |
| `zls` | Zig |
| `bashls` | Bash |
| `lua_ls` | Lua |
| `ts_ls` | TypeScript/JavaScript |
| `jsonls` | JSON |
| `yamlls` | YAML (with GitHub Actions + Docker Compose schemas) |

Mason-managed servers (auto-installed):

| Server | Language | Notes |
|--------|----------|-------|
| `omnisharp` | C#/.NET | .NET SDK must be installed via apt (`bootstrap-apt.sh`) |
| `jdtls` | Java | Via LazyVim java extra |
| `pyright` | Python | Via LazyVim python extra |

To add a new Nix-managed server: add it to the `nix_managed` list and the `servers` table in `lsp.lua`, then add the corresponding package to `home.packages` in `home.nix`.

### LazyVim Extras

Enabled in `lazy.lua`:

**Language extras:**
`python`, `go`, `rust`, `typescript`, `java`, `kotlin`, `scala`, `clangd`, `zig`, `json`, `yaml`, `toml`, `markdown`, `sql`, `nix`, `docker`, `terraform`, `helm`, `omnisharp`

**Editor extras:**
`harpoon2` (fast file switching), `aerial` (code outline), `telescope` (fuzzy finder)

**Coding extras:**
`yanky` (yank history), `mini-surround` (surround text objects), `luasnip` (snippets)

**Other extras:**
`dap.core` + `dap.nlua` (debugging), `test.core` (testing framework), `ui.mini-animate` (smooth animations)

### Treesitter Parsers

Explicitly installed parsers (in `lsp.lua`):

```
bash, c, c_sharp, css, diff, dockerfile, go, gomod, gosum, html, javascript,
json, lua, luadoc, markdown, markdown_inline, nix, python, query, regex, rust,
scala, sql, terraform, toml, tsx, typescript, vim, vimdoc, xml, yaml, zig
```

### Plugin List

Configured in `tools.lua`:

| Plugin | Purpose | Key binding |
|--------|---------|-------------|
| **catppuccin/nvim** | Mocha colorscheme (shared with tmux) | — |
| **vim-tmux-navigator** | Seamless `C-h/j/k/l` navigation between nvim and tmux panes | `C-h/j/k/l` |
| **lazygit.nvim** | Full Git UI in a floating terminal | `<leader>gg` |
| **undotree** | Visual undo history tree | `<leader>U` |
| **oil.nvim** | Filesystem as an editable buffer | `-` |
| **neotest** | Test runner framework (Go, Rust, Python, .NET adapters) | `<leader>t*` |
| **vim-dadbod-ui** | Interactive database client | `<leader>D` |
| **marks.nvim** | Visual mark indicators in sign column | — |

### AI Plugins

Configured in `ai.lua`:

**GitHub Copilot** — inline completions as you type:

| Key | Action |
|-----|--------|
| `<Tab>` | Accept full suggestion |
| `<C-l>` | Accept next word |
| `<C-j>` | Accept next line |
| `<M-]>` / `<M-[>` | Cycle through suggestions |
| `<C-]>` | Dismiss suggestion |

**Avante (Claude)** — chat panel using `claude-sonnet-4-6`:

| Key | Action |
|-----|--------|
| `<leader>aa` | Open chat (or ask about visual selection) |
| `co` / `ct` / `cb` | Accept ours / theirs / both (diff resolution) |
| `]]` / `[[` | Jump between diff hunks |

Requires `ANTHROPIC_API_KEY` environment variable.

### Custom Keybindings

Defined in `keymaps.lua`:

| Key | Mode | Action |
|-----|------|--------|
| `jk` / `kj` | Insert | Escape to normal mode |
| `J` / `K` | Visual | Move selected lines down/up |
| `<A-j>` / `<A-k>` | Normal | Move current line down/up |
| `<C-d>` / `<C-u>` | Normal | Half-page scroll (cursor stays centered) |
| `n` / `N` | Normal | Next/prev search result (centered) |
| `<leader>p` | Visual | Paste without overwriting register |
| `<leader>d` | Normal/Visual | Delete without yanking |
| `<leader>w` | Normal | Save file |
| `<leader>gg` | Normal | Open LazyGit (project root) |
| `<leader>U` | Normal | Toggle undotree |
| `<leader>D` | Normal | Toggle database UI |

### Auto-commands

Defined in `autocmds.lua`:

- **Yank highlight**: briefly highlights yanked text (200ms)
- **Resize splits**: auto-equalizes splits when terminal is resized
- **Close with q**: help, quickfix, man, notify, lspinfo, checkhealth buffers close with `q`
- **Prose mode**: markdown, gitcommit, and text files get word wrap + spell check
- **Nix indent**: 2-space indent for `.nix` files

### Editor Options

Defined in `options.lua`:

- Relative line numbers with absolute current line
- 2-space tabs (expandtab)
- Smart indent, no word wrap, color column at 120
- 8-line scroll margin (scrolloff)
- System clipboard integration (`unnamedplus`)
- Persistent undo (undofile), no swapfile
- Case-insensitive search (smart case)
- New splits open below/right
- Treesitter-based code folding (all folds open by default)

### Replicating to Another System

To replicate this Neovim setup on a different machine (e.g., macOS via nix-darwin):

1. Copy the entire `modules/dotfiles/nvim/` directory
2. Ensure the Nix-managed LSP servers are available on PATH (install the corresponding packages)
3. For Mason-managed servers (omnisharp, jdtls, pyright), Mason will auto-install them on first use — just ensure their runtimes are present (.NET SDK for omnisharp, JDK for jdtls)
4. For Copilot, run `:Copilot auth` on first use
5. For Avante, set `ANTHROPIC_API_KEY` in your environment
6. lazy.nvim will auto-bootstrap on first launch and install all plugins

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
