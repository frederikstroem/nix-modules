{ config, lib, pkgs, ... }:

let
  cfg = config.katoflns-nix-modules.hello-nushell;
  username = config.katoflns-nix-modules.home-manager-username;
in
{
  options.katoflns-nix-modules.hello-nushell = {
    enable = lib.mkEnableOption "the hello-nushell greeting command";
  };

  config = lib.mkIf cfg.enable {
    # Ensure that a username is provided.
    assertions = [{
      assertion = username != "";
      message = ''
        The option `katoflns-nix-modules.home-manager-username` must be set
        when using Katofln's modules with Home Manager integration.

        Add this to your configuration:
          katoflns-nix-modules.home-manager-username = "your-username";
      '';
    }];

    # Home Manager configuration for the specified user.
    home-manager.users.${username} = { config, pkgs, ... }: {
      # Alternatively, this module could define the function directly
      # in the Nushell configuration via Home Manager:
      #
      # programs.nushell = {
      #   enable = lib.mkDefault true;
      #
      #   configFile.text = lib.mkAfter (''
      #     # 🥔 Katofln's `hello-nushell` module.
      #     def hello-nushell [] {
      #       print $"(ansi green_bold)Hello, Nushell!(ansi reset) 🥔"
      #     }
      #   '');
      # };
      #
      # By default, this module provides a standalone script accessible from all shells.
      home.packages = with pkgs; [
        (writeScriptBin "hello-nushell" ''
          #!${pkgs.nushell}/bin/nu

          print $"(ansi green_bold)Hello, Nushell!(ansi reset) 🥔"
        '')
      ];
    };
  };
}
