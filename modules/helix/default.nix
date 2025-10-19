{ config, lib, pkgs, ... }:

let
  cfg = config.katoflns-nix-modules.helix;
  username = config.katoflns-nix-modules.home-manager-username;
in
{
  options.katoflns-nix-modules.helix = {
    enable = lib.mkEnableOption ''
      Enable the Helix module with configuration including:
      - Helix text editor (post-modern modal text editor)
      - Custom themes (transparent variants)
      - Indent guides and cursor customization
      - Custom keybindings for Danish keyboard layout
      - Integration with Nushell

      A post-modern modal text editor written in Rust.
      https://github.com/helix-editor/helix
      https://helix-editor.com/

      See the nix file for full details.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Ensure that a username is provided.
    assertions = [
      {
        assertion = username != "";
        message = ''
          The option `katoflns-nix-modules.home-manager-username` must be set
          when using Katofln's modules with Home Manager integration.

          Add this to your configuration:
            katoflns-nix-modules.home-manager-username = "yourusername";
        '';
      }
    ];

    environment.systemPackages = with pkgs; [
      helix
    ];

    environment.variables = { EDITOR = "hx"; };

    home-manager.users.${username} = { config, pkgs, lib, ... }: {

      # https://home-manager-options.extranix.com/?query=programs.helix&release=master

      programs.helix = {
        enable = true;
        # Whether to configure {command}hx as the default editor using the {env}EDITOR environment variable.
        defaultEditor = true;
        # Each theme is written to {file}$XDG_CONFIG_HOME/helix/themes/theme-name.toml. Where the name of each attribute is the theme-name (in the example "base16".
        # See <https://docs.helix-editor.com/themes.html> for the full list of options.
        # Type attribute set of (TOML value or absolute path or strings concatenated with "\n")
        themes = {
          github_dark_transparent = {
            # Inherit all settings from `github_dark`.
            # https://github.com/helix-editor/helix/blob/master/runtime/themes/github_dark.toml
            inherits = "github_dark";

            # Override the background to make it transparent.
            "ui.background" = "none";
          };
          onedarker_transparent = {
            # Inherit all settings from `onedarker`.
            # https://github.com/helix-editor/helix/blob/master/runtime/themes/onedarker.toml
            inherits = "onedarker";

            # Override the background to make it transparent.
            "ui.background" = "none";
          };
        };
        # Configuration written to {file}$XDG_CONFIG_HOME/helix/config.toml.
        # See <https://docs.helix-editor.com/configuration.html> for the full list of options.
        settings = {
          theme = "github_dark_transparent";
          editor = {
            true-color = true; # Set to `true` to override automatic detection of terminal truecolor support in the event of a false negative
            # Note the bug where the indent guides character takes priority over the cursor:
            # https://github.com/helix-editor/helix/issues/8909
            indent-guides = {
              render = true;
              character = "▏"; # Literal character to use for rendering the indent guide # Default: "│" | Some characters that work well: "▏", "┆", "┊", "⸽"
            };
            cursor-shape = {
              insert = "bar";
            };
          };
          # Custom keybindings for Danish keyboard layout
          # Using æ, ø, å for easier access to case control and other hard-to-reach keys
          keys.normal = {
            # Case control remapping (easier for Danish keyboard)
            "æ" = "switch_to_lowercase";      # Original: ` (backtick)
            "ø" = "switch_case";              # Original: ~ (tilde)
            "A-æ" = "switch_to_uppercase";    # Original: Alt-` (Alt-backtick)
          };
        };
      };

      # Set Helix as the default editor in Nushell.
      programs.nushell.configFile.text = lib.mkAfter ''
        # Set the editor to Helix.
        $env.EDITOR = "hx"
      '';

    };

  };

}
