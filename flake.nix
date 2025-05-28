{
  ####################################################################
  # About
  ####################################################################
  description = "Dr G’s reproducible Home-Manager setup (24.05 • aarch64-linux)";

  ####################################################################
  # Inputs – both on the stable 24.05 line
  ####################################################################
  inputs = {
    nixpkgs.url       = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url  = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  ####################################################################
  # Outputs
  ####################################################################
  outputs = { self, nixpkgs, home-manager }:
  let
    system = "aarch64-linux";
    pkgs   = import nixpkgs { inherit system; config.allowUnfree = true; };
  in
  {
    ##################################################################
    # 1 ▸ Grab-bag CLI bundle   →   nix run ~/.config/nix#cli
    ##################################################################
    packages.${system}.cli = pkgs.buildEnv {
      name  = "cli-tools";
      paths = with pkgs; [ bat ripgrep fd wget ];
    };

    ##################################################################
    # 2 ▸ Home-Manager configuration for user “ubuntu”
    ##################################################################
    homeConfigurations."ubuntu" =
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [

          # 2a ▸ Fetch and install oh-my-bash reproducibly
          {
            home.file.".oh-my-bash" = {
              source = pkgs.fetchFromGitHub {
                owner = "ohmybash";
                repo  = "oh-my-bash";
                rev   = "c583eb5f52d1954a1d3812918c230da5713dc9d2";   # 2025-05-14
                hash  = "sha256-7Df9U+jJ7bYui3tdzEIUzd1GAHEo7II3E6zAyU3tRD0=";
              };
            };
          }

          # 2b ▸ Core HM settings & packages
          {
            home.username      = "ubuntu";
            home.homeDirectory = "/home/ubuntu";
            home.stateVersion  = "24.05";     # never auto-bump

            #### Shell ################################################
            programs.bash.enable = true;
            programs.bash.initExtra = ''
              export OSH="$HOME/.oh-my-bash"
              [ -f "$OSH/oh-my-bash.sh" ] && source "$OSH/oh-my-bash.sh"
            '';

            #### Direnv ###############################################
            programs.direnv.enable            = true;
            programs.direnv.nix-direnv.enable = true;

            #### Home-Manager CLI #####################################
            # programs.home-manager.enable = true;   # ← puts `home-manager` on PATH

            #### Always-present tools #################################
            home.packages = with pkgs; [
              home-manager.packages.${system}.home-manager
              htop
            ];
          }
        ];
      };

    ##################################################################
    # 3 ▸ Wrapper app  →  nix run ~/.config/nix#hm -- switch
    ##################################################################
    apps.${system}.hm =
      let
        hmBin = home-manager.packages.${system}.home-manager;
        hmWrapper = pkgs.writeShellScriptBin "hm" ''
          #!${pkgs.bash}/bin/bash
          # Point to the editable flake dir so lock-file writes work
          exec ${hmBin}/bin/home-manager \
               --flake "$HOME/.config/nix" -b backup "$@"
        '';
      in {
        type    = "app";
        program = "${hmWrapper}/bin/hm";
      };
  };
}