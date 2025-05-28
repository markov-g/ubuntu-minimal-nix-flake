# Dr G’s Home‑Manager Flake (24.05 • aarch64‑linux)

A reproducible shell setup for any 64‑bit ARM Linux box that already has **Determinate Nix** (or plain Nix with flakes enabled). It gives you:

* **oh‑my‑bash** (pinned commit)
* **bash** profile owned by Home‑Manager
* **home‑manager** CLI on your `$PATH`
* **direnv + nix‑direnv**
* A small bundle of CLI tools (`bat`, `ripgrep`, `fd`, `wget`)
* A convenience wrapper so you only ever type one command:

```
nix run ~/.config/nix#hm -- switch
```

---

## 1 Directory layout

```
~/.config/
└── nix/           # ← this repo (contains flake.nix & flake.lock)
```

Everything lives in that one folder, so you can version‑control it or copy it to other hosts.

---

## 2 Prerequisites

* Nix 2.18+ installed via **Determinate Nix Installer** (flakes enabled by default)
* Running on aarch64 Linux (Raspberry Pi 4/5, AWS Graviton, Ampere, ThinkPad X13s …)
* Git (only for updating the repo)

---

## 3 First‑time setup

```
# clone or move this folder to ~/.config/nix if it isn’t there already
cd ~/.config/nix

# pin inputs (creates flake.lock)
nix flake lock --update-input nixpkgs --update-input home-manager

# build + activate (backs up old dot‑files to *.backup)
nix run .#hm -- switch
```

Open a new shell – you should see an oh‑my‑bash prompt. `home-manager`, `direnv`, `htop`, etc. are now on your PATH.

---

## 4 Every‑day workflow

### Update your env after editing *flake.nix*

```
nix run ~/.config/nix#hm -- switch
```

### Update nixpkgs / Home‑Manager

```
cd ~/.config/nix
nix flake lock --update-input nixpkgs --update-input home-manager
nix run .#hm -- switch
```

### Use the CLI bundle anywhere

```
nix run ~/.config/nix#cli -- <tool> [args]
# example\ n
nix run ~/.config/nix#cli -- bat README
```

---

## 5 Customising

### 5.1 Add always‑installed packages

Edit the `home.packages` list inside the Home‑Manager module:

```
home.packages = with pkgs; [
  htop
  git
  starship
];
```

Run the switch command again.

### 5.2 Enable more program modules

```
programs.starship.enable = true;
programs.fzf.enable      = true;
```

### 5.3 Add occasional CLI tools to the bundle

```
packages.${system}.cli.paths = with pkgs; [
  bat ripgrep fd wget
  jq
];
```

### 5.4 Change the oh‑my‑bash theme

Add to `programs.bash.initExtra` after the `OSH` line:

```
export OSH_THEME="fontancy"
```

### 5.5 Different username / multiple hosts

* Duplicate the `homeConfigurations` entry with the new user/host key **or**
* Replace the hard‑coded strings with:

```
home.username      = builtins.getEnv "USER";
home.homeDirectory = builtins.getEnv "HOME";
```

  and run the wrapper with `--impure`.

---

## 6 Troubleshooting

SymptomFix*“inefficient double copy of path …”*Benign warning; ignore or replace `programs.home-manager.enable` with a direct package reference.HM refuses to overwrite existing dot‑filesRe‑run switch with `-b backup` (wrapper already does this).Command not found: `home-manager`Ensure `programs.home-manager.enable = true;` and re‑switch.Wrong arch errorChange `system = "aarch64-linux"` to your correct tuple (`x86_64-linux`, `armv7l-linux`, etc.).

---

## 7 Uninstall / rollback

```
home-manager switch --rollback      # roll back to previous gen
home-manager generations            # list generations
home-manager uninstall              # remove all HM symlinks
```

---

### License

MIT, same as the upstream examples.