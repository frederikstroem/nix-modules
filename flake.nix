{
  description = "Katofln's opinionated Nix modules";

  inputs = {
    # `nixpkgs` and `home-manager` are intentionally not pinned here — the consumer of these modules controls all input versions.
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # home-manager.url = "github:nix-community/home-manager/master";
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    {
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
