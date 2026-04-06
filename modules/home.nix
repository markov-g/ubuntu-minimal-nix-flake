{ config, pkgs, lib, user, host, ... }:

{
  home.username      = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion  = "24.05";       # never auto-bump

  # Let Home-Manager manage itself
  programs.home-manager.enable = true;

  ####################################################################
  # 1 ▸ Packages — organized by category
  ####################################################################
  home.packages = with pkgs; [

    ## ── Core CLI replacements ──────────────────────────────────────
    bat                   # cat replacement with syntax highlighting
    eza                   # ls replacement
    fd                    # find replacement
    ripgrep               # grep replacement
    fzf                   # fuzzy finder
    delta                 # git diff pager
    dust                  # du replacement
    procs                 # ps replacement
    bottom                # top/htop replacement
    zoxide                # cd replacement (z)
    jq                    # JSON processor
    jless                 # JSON viewer
    yq-go                 # YAML processor
    xh                    # HTTP client (curl replacement)
    tealdeer              # tldr pages

    ## ── Git & version control ──────────────────────────────────────
    git
    git-lfs
    lazygit
    gitui
    difftastic            # structural diff
    gh                    # GitHub CLI

    ## ── Editors ────────────────────────────────────────────────────
    neovim                # primary editor (LazyVim)
    helix                 # secondary editor — zero-config, fast SSH edits

    ## ── Shell tools ────────────────────────────────────────────────
    tmux
    atuin                 # shell history
    direnv
    nix-direnv
    starship              # prompt (available, bash uses oh-my-bash by default)
    navi                  # interactive cheatsheet

    ## ── SSH resilience ─────────────────────────────────────────────
    mosh                  # mobile shell — survives disconnects/roaming

    ## ── Terminal browsers ──────────────────────────────────────────
    w3m                   # lightweight terminal browser (supports inline images)
    lynx                  # classic terminal browser
    # carbonyl — Chromium-based terminal browser; not in nixpkgs,
    #   install via: cargo install --git https://github.com/nickel-org/nickel.rs carbonyl

    ## ── Runtime manager ────────────────────────────────────────────
    mise                  # polyglot version manager (node/python/go/java)

    ## ── Languages & runtimes ───────────────────────────────────────
    nodejs_22
    python3
    go
    rustup

    ## ── LSP servers (Nix-managed, not Mason) ───────────────────────
    nil                   # Nix LSP
    statix                # Nix linter
    gopls                 # Go LSP
    clang-tools           # clangd (C/C++ LSP)
    zls                   # Zig LSP
    lua-language-server
    bash-language-server
    typescript-language-server
    yaml-language-server
    vscode-json-languageserver

    ## ── Containers & k8s ───────────────────────────────────────────
    lazydocker            # TUI for Docker
    dive                  # explore Docker image layers
    k9s                   # Kubernetes TUI
    act                   # run GitHub Actions locally

    ## ── Monitoring & system ────────────────────────────────────────
    htop
    ncdu
    tokei                 # code line counter
    hyperfine             # benchmarking
    bandwhich             # per-process bandwidth monitor
    gping                 # ping with graph

    ## ── File management & transfer ─────────────────────────────────
    yazi                  # terminal file manager
    wget
    curl
    unzip
    tree
    croc                  # encrypted file transfer between machines

    ## ── Documentation & rendering ──────────────────────────────────
    glow                  # terminal Markdown renderer
    asciinema             # terminal session recorder

    ## ── Nix tools ──────────────────────────────────────────────────
    nix-tree
    nix-diff
    nixfmt-rfc-style
  ];

  ####################################################################
  # 2 ▸ Shell — Bash with oh-my-bash
  ####################################################################
  programs.bash = {
    enable = true;

    # Source oh-my-bash + Nix tool aliases
    initExtra = builtins.readFile ./dotfiles/.bashrc.extra;

    shellAliases = {
      # Nix CLI replacements
      cat  = "bat --paging=never";
      ls   = "eza --icons --group-directories-first";
      ll   = "eza -la --icons --group-directories-first";
      lt   = "eza --tree --icons --level=2";
      grep = "rg";
      find = "fd";
      ps   = "procs";
      top  = "btm";
      diff = "difft";
      du   = "dust";
      vi   = "nvim";
      vim  = "nvim";
      hx   = "helix";

      # Git shortcuts
      lg   = "lazygit";
      ld   = "lazydocker";
      gs   = "git status";
      gd   = "git diff";
      gl   = "git log --oneline --graph --decorate -20";

      # Containers & k8s
      k    = "kubectl";
      kx   = "k9s";

      # Nix shortcuts
      hms  = "nix run ~/.config/nix#hm -- switch";
      hmu  = "cd ~/.config/nix && nix flake update && nix run .#hm -- switch";
    };
  };

  ####################################################################
  # 3 ▸ Direnv
  ####################################################################
  programs.direnv = {
    enable            = true;
    nix-direnv.enable = true;
  };

  ####################################################################
  # 4 ▸ Git
  ####################################################################
  programs.git = {
    enable    = true;

    settings = {
      user.name  = lib.mkDefault "Dr G";
      user.email = lib.mkDefault "drg@example.com";
      init.defaultBranch = "main";
      pull.rebase        = true;
      push.autoSetupRemote = true;
      core.editor        = "nvim";
      merge.conflictStyle = "diff3";
      diff.colorMoved    = "default";
    };

    lfs.enable = true;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate     = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  ####################################################################
  # 5 ▸ fzf
  ####################################################################
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
  };

  ####################################################################
  # 6 ▸ zoxide (smart cd)
  ####################################################################
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  ####################################################################
  # 7 ▸ atuin (shell history)
  ####################################################################
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      auto_sync   = false;
      update_check = false;
      style       = "compact";
    };
  };

  ####################################################################
  # 8 ▸ tmux — managed via dotfile, TPM bootstrapped by activation
  ####################################################################
  home.file.".tmux.conf".source = ./dotfiles/.tmux.conf;

  ####################################################################
  # 9 ▸ Neovim — LazyVim config tree
  ####################################################################
  xdg.configFile = {
    "nvim/init.lua".source        = ./dotfiles/nvim/init.lua;
    "nvim/lua/config/lazy.lua".source    = ./dotfiles/nvim/lua/config/lazy.lua;
    "nvim/lua/config/options.lua".source = ./dotfiles/nvim/lua/config/options.lua;
    "nvim/lua/config/keymaps.lua".source = ./dotfiles/nvim/lua/config/keymaps.lua;
    "nvim/lua/config/autocmds.lua".source = ./dotfiles/nvim/lua/config/autocmds.lua;
    "nvim/lua/plugins/lsp.lua".source    = ./dotfiles/nvim/lua/plugins/lsp.lua;
    "nvim/lua/plugins/tools.lua".source  = ./dotfiles/nvim/lua/plugins/tools.lua;
    "nvim/lua/plugins/ai.lua".source     = ./dotfiles/nvim/lua/plugins/ai.lua;
  };

  # Redirect lazy-lock.json to a mutable location (Nix store is read-only)
  xdg.configFile."nvim/lazy-lock.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.local/share/nvim/lazy-lock.json";

  ####################################################################
  # 10 ▸ Helix — secondary editor config
  ####################################################################
  xdg.configFile."helix/config.toml".source    = ./dotfiles/helix/config.toml;
  xdg.configFile."helix/languages.toml".source = ./dotfiles/helix/languages.toml;

  ####################################################################
  # 11 ▸ mise — runtime version manager
  ####################################################################
  xdg.configFile."mise/config.toml".source = ./dotfiles/mise/config.toml;

  ####################################################################
  # 12 ▸ k9s — Kubernetes TUI
  ####################################################################
  xdg.configFile."k9s/config.yaml".source = ./dotfiles/k9s/config.yaml;

  ####################################################################
  # 13 ▸ oh-my-bash — pinned fetch
  ####################################################################
  home.file.".oh-my-bash" = {
    source = pkgs.fetchFromGitHub {
      owner = "ohmybash";
      repo  = "oh-my-bash";
      rev   = "c583eb5f52d1954a1d3812918c230da5713dc9d2";   # 2025-05-14
      hash  = "sha256-7Df9U+jJ7bYui3tdzEIUzd1GAHEo7II3E6zAyU3tRD0=";
    };
  };

  ####################################################################
  ####################################################################
  # 15 ▸ inputrc
  ####################################################################
  home.file.".inputrc".source = ./dotfiles/.inputrc;

  ####################################################################
  # 16 ▸ KDE Plasma configuration
  #      NOT managed as symlinks — KDE needs these to be mutable.
  #      Stored in dotfiles/kde/ as reference snapshots.
  #      Seeded on first run via activation script; backed up via
  #      ~/bin/kde-backup.sh and restored via ~/bin/kde-restore.sh.
  ####################################################################

  ####################################################################
  # 17 ▸ Utility scripts → ~/bin/
  ####################################################################
  home.file."bin/bootstrap-apt.sh" = {
    source     = ./dotfiles/bin/bootstrap-apt.sh;
    executable = true;
  };
  home.file."bin/nix-update-all.sh" = {
    source     = ./dotfiles/bin/nix-update-all.sh;
    executable = true;
  };
  home.file."bin/tmux-sessionizer.sh" = {
    source     = ./dotfiles/bin/tmux-sessionizer.sh;
    executable = true;
  };
  home.file."bin/kde-backup.sh" = {
    source     = ./dotfiles/bin/kde-backup.sh;
    executable = true;
  };
  home.file."bin/kde-restore.sh" = {
    source     = ./dotfiles/bin/kde-restore.sh;
    executable = true;
  };

  ####################################################################
  # 18 ▸ Activation scripts
  ####################################################################
  home.activation = {
    # Bootstrap TPM (Tmux Plugin Manager) on first run
    bootstrapTpm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm \
          "$HOME/.tmux/plugins/tpm" 2>/dev/null || true
      fi
    '';

    # Ensure lazy-lock.json location exists
    ensureLazyLock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.local/share/nvim"
      touch "$HOME/.local/share/nvim/lazy-lock.json"
    '';

    # Generate SSH key if none exists
    generateSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "${user}@$(hostname)" 2>/dev/null || true
        echo "✱ SSH key generated at ~/.ssh/id_ed25519"
        echo "  Add the public key to GitHub: cat ~/.ssh/id_ed25519.pub"
      fi
    '';

    # Initialize mise on first run
    initMise = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if command -v mise &>/dev/null; then
        mise trust --all 2>/dev/null || true
      fi
    '';

    # Seed KDE configs on first run (copy, not symlink — KDE needs mutable files)
    seedKdeConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      FLAKE_KDE="$HOME/.config/nix/modules/dotfiles/kde"
      if [ -d "$FLAKE_KDE" ]; then
        for f in kdeglobals kglobalshortcutsrc kwinrc kwinoutputconfig.json \
                 plasma-org.kde.plasma.desktop-appletsrc plasmashellrc \
                 yakuakerc dolphinrc konsolesshconfig; do
          src="$FLAKE_KDE/$f"
          dst="$HOME/.config/$f"
          if [ -f "$src" ] && [ ! -f "$dst" ]; then
            cp "$src" "$dst"
          fi
        done
      fi
    '';
  };
}
