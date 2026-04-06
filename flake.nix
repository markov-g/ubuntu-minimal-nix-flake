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
  };

  ####################################################################
  # Outputs
  ####################################################################
  outputs = { self, nixpkgs, home-manager, determinate }:
  let
    system = "aarch64-linux";
    pkgs   = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # Helper: build a Home-Manager configuration for a given user/host
    mkHomeUser = { user, host ? "default" }:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit user host; };
        modules = [
          ./modules/home.nix
        ];
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

      # Add more users/hosts as needed:
      # "devel" = mkHomeUser {
      #   user = "devel";
      #   host = "devbox";
      # };
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
