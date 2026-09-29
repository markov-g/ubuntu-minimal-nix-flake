{ config, lib, pkgs, user, ... }:

let
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" "llvm-tools" ];
    targets = [
      "aarch64-unknown-linux-gnu"
      "aarch64-unknown-linux-musl"
      "wasm32-unknown-unknown"
    ];
  };

  pythonEnv = pkgs.python313.withPackages (ps: with ps; [
    pip
    virtualenv
    ipython
    requests
    rich
  ]);

  dotnet = pkgs.dotnetCorePackages.sdk_9_0;
  defaultJdk = pkgs.temurin-bin-21;

  swiftAvailable =
    let t = builtins.tryEval (pkgs.swift.outPath or null);
    in t.success && t.value != null;

  swiftPackages = lib.optionals swiftAvailable (with pkgs; [
    swift
    swiftpm
    swift-format
    sourcekit-lsp
  ]);

  toolbox =
    let t = builtins.tryEval (pkgs.jetbrains-toolbox.outPath or null);
    in lib.optional (t.success && t.value != null) pkgs.jetbrains-toolbox;
in
{
  # Only user-space packages from ../nixos/modules/dev are ported here.
  # Host services, kernel settings, FUSE policy, and container sockets remain
  # owned by Omarchy.
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  xdg.configFile = {
    "nvim/init.lua".source = ./dotfiles/nvim/init.lua;
    "nvim/lua/config/lazy.lua".source = ./dotfiles/nvim/lua/config/lazy.lua;
    "nvim/lua/config/options.lua".source = ./dotfiles/nvim/lua/config/options.lua;
    "nvim/lua/config/keymaps.lua".source = ./dotfiles/nvim/lua/config/keymaps.lua;
    "nvim/lua/config/autocmds.lua".source = ./dotfiles/nvim/lua/config/autocmds.lua;
    "nvim/lua/plugins/lsp.lua".source = ./dotfiles/nvim/lua/plugins/lsp.lua;
    "nvim/lua/plugins/tools.lua".source = ./dotfiles/nvim/lua/plugins/tools.lua;
    "nvim/lua/plugins/ai.lua".source = ./dotfiles/nvim/lua/plugins/ai.lua;
  };

  xdg.configFile."nvim/lazy-lock.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.local/share/nvim/lazy-lock.json";

  home.activation.ensureLazyLock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/share/nvim"
    touch "$HOME/.local/share/nvim/lazy-lock.json"
  '';

  home.packages = with pkgs; [
    # C and C++
    gcc
    clang
    lld
    mold
    gnumake
    cmake
    cmake-language-server
    ninja
    meson
    autoconf
    automake
    libtool
    pkg-config
    bear
    ccache
    conan
    vcpkg
    vcpkg-tool
    clang-tools
    cppcheck
    include-what-you-use
    gdb
    lldb
    valgrind
    perf
    heaptrack
    doxygen
    graphviz
    stdenv.cc

    # Rust
    rustToolchain
    cargo-edit
    cargo-watch
    cargo-nextest
    cargo-audit
    cargo-deny
    cargo-expand
    cargo-outdated
    cargo-bloat
    cargo-flamegraph
    cargo-generate
    cargo-udeps
    bacon
    sccache
    rustPlatform.bindgenHook
    cargo-cross

    # Python
    pythonEnv
    uv
    poetry
    (python313Packages.pipx.overridePythonAttrs (_: { doCheck = false; }))
    pdm
    hatch
    ruff
    black
    isort
    mypy
    pyright
    basedpyright
    python313Packages.pytest
    python313Packages.pytest-cov
    python313Packages.debugpy
    jupyter
    zlib
    openssl
    libffi

    # Swift and its Linux runtime libraries
    libxml2
    libuuid
    icu
    curl
    sqlite

    # .NET
    dotnet
    mono
    msbuild
    omnisharp-roslyn
    netcoredbg
    powershell

    # JVM and Kotlin
    defaultJdk
    temurin-bin-17
    gradle
    maven
    ant
    kotlin
    kotlin-language-server
    ktlint
    ktfmt
    jdt-language-server
    google-java-format
    checkstyle
    visualvm
    jmeter

    # Go and Zig
    go
    gopls
    delve
    zig
    zls

    # Cloud-native, infrastructure, and security tooling
    kubectl
    kubernetes-helm
    kustomize
    k9s
    kubectx
    stern
    kubecolor
    krew
    kind
    minikube
    k3d
    kubectl-tree
    kubectl-node-shell
    argocd
    fluxcd
    skaffold
    tilt
    helmfile
    kubeseal
    kube-score
    kubeconform
    popeye
    trivy
    cosign
    syft
    grype
    opentofu
    terragrunt
    ansible
    awscli2
    azure-cli
    google-cloud-sdk
    cilium-cli
    istioctl
    skopeo
    crane
    dive
    regclient

    # AI agents and secrets tools
    claude-code
    codex
    opencode
    nodejs_22
    sops
    age
    ssh-to-age

    # Editors and IDEs
    jetbrains.idea
    jetbrains.clion
    jetbrains.pycharm
    jetbrains.rider
    fuse3
    libsecret
    jetbrains.jdk
    vscode
    neovim
    helix

    # Runtime dependencies referenced by this repository's Neovim config
    git
    direnv
    nix-direnv
    fd
    ripgrep
    fzf
    lazygit
    tmux
    nil
    bash-language-server
    lua-language-server
    typescript-language-server
    yaml-language-server
    vscode-json-languageserver
  ] ++ swiftPackages ++ toolbox;

  # Container-provider variables are omitted because this profile does not
  # configure Omarchy's Podman or Docker service.
  home.sessionVariables = {
    CMAKE_GENERATOR = "Ninja";
    RUSTFLAGS = "-C link-arg=-fuse-ld=mold";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    CARGO_INCREMENTAL = "0";
    UV_PYTHON_PREFERENCE = "managed";
    PYTHONDONTWRITEBYTECODE = "1";
    DOTNET_ROOT = "${dotnet}/share/dotnet";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    DOTNET_NOLOGO = "1";
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "1";
    JAVA_HOME = "${defaultJdk}";
    GRADLE_USER_HOME = "$HOME/.gradle";
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
    KUBE_EDITOR = "nvim";
  };

  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.dotnet/tools"
  ];
}
