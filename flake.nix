{
  ####################################################################
  # About
  ####################################################################
  description = "Dr G's reproducible Home-Manager setup (aarch64-linux)";

  ####################################################################
  # Inputs
  ####################################################################
  inputs = {
    # Determinate Nix – resolve inputs via FlakeHub
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1.*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spacemacs = {
      url = "github:syl20bnr/spacemacs/develop";
      flake = false;
    };
  };

  ####################################################################
  # Outputs
  ####################################################################
  outputs = { self, nixpkgs, home-manager, determinate, rust-overlay, spacemacs }:
  let
    system = "aarch64-linux";
    pkgs   = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # Helper: build a Home-Manager configuration for a given user/host
    mkHomeUser = {
      user,
      host ? "default",
      modules ? [ ./modules/home.nix ],
      overlays ? [ ],
      specialArgs ? { },
    }:
      let
        userPkgs =
          if builtins.length overlays == 0 then
            pkgs
          else
            import nixpkgs {
              inherit system overlays;
              config.allowUnfree = true;
            };
      in
      home-manager.lib.homeManagerConfiguration {
        pkgs = userPkgs;
        extraSpecialArgs = { inherit user host; } // specialArgs;
        inherit modules;
      };
  in
  {
    ##################################################################
    # Home-Manager configurations
    ##################################################################
    homeConfigurations = {
      # Primary user
      "ubuntu" = mkHomeUser {
        user = "ubuntu";
        host = "default";
      };

      "devel" = mkHomeUser {
        user = "devel";
        host = "default";
      };

      "devel@omarchydevbox" = mkHomeUser {
        user = "devel";
        host = "omarchydevbox";
        modules = [
          ./modules/omarchy-dev.nix
          ./modules/omarchy-spacemacs.nix
        ];
        overlays = [ rust-overlay.overlays.default ];
        specialArgs = { inherit spacemacs; };
      };
    };

    ##################################################################
    # Convenience app  →  nix run ~/.config/nix#hm -- switch
    ##################################################################
    apps.${system}.hm =
      let
        hmBin = home-manager.packages.${system}.home-manager;
        hmWrapper = pkgs.writeShellScriptBin "hm" ''
          exec ${hmBin}/bin/home-manager \
               --flake "$HOME/.config/nix" -b backup "$@"
        '';
      in {
        type    = "app";
        program = "${hmWrapper}/bin/hm";
      };
  };
}
