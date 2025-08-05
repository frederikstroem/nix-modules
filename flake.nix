{
  description = "Katofln's opinionated Nix modules";

  inputs = {
    # The consumer of the Nix modules are expected to control the inputs,
    # but for the dev environment, actual inputs are needed.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";

    # Development environment inputs.
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Development environment.
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bashInteractive
            devenv
          ];
        };
      }
    ) // {
      # Main module export — imports all available modules.
      default = import ./modules;

      # Metadata for introspection and documentation.
      lib = {
        availableModules = [
          "hello-nushell"
        ];
        supportedSystems = supportedSystems;
      };
    };
}
