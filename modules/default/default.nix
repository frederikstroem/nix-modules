{ lib, ... }:

{
  options.katoflns-nix-modules = {
    home-manager-username = lib.mkOption {
      type = lib.types.str;
      description = ''
        Username used for Home Manager integration across all of Katofln's modules. 🥔

        This must be set when using any of Katofln's modules that integrate with Home Manager.
        All modules will use this username in their Home Manager configuration.
      '';
      example = "katofln";
    };
  };

  # No configuration is needed here — this module only defines shared options.
  config = {};
}
