> [!WARNING]
> **tl;dr:** There be dragons! 🐉<br>
> These modules are under heavy and rapid development — expect breaking changes and frequent updates.

# 🥔 Katofln's Nix Modules
A collection of heavily opinionated, reusable Home Manager and NixOS modules—importable via Flakes—designed to be composable and explicitly enabled.

Created with the help of these awesome projects:
[devenv](https://github.com/cachix/devenv),
[direnv](https://github.com/direnv/direnv),
[Home Manager](https://github.com/nix-community/home-manager),
[nix-options-doc](https://github.com/Thunderbottom/nix-options-doc),
[NixOS](https://nixos.org/),
[Nixpkgs](https://github.com/NixOS/nixpkgs),
[Nushell](https://github.com/nushell/nushell)

## 🎯 Philosophy
- **Bring Your Own Dependencies**: This repository does not include a `flake.lock` file — you control all dependency versions through your own flake inputs.
- **Composable & Explicit Enablement**: Mix and match modules as needed for your specific use case. All modules are disabled by default and require explicit enablement.
- **Home Manager First**: Primarily focused on Home Manager modules for user environment configuration.

## 🚀 Quick Start
**Import the modules in your `flake.nix`:**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    katoflns-nix-modules = {
      url = "github:frederikstroem/nix-modules/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, home-manager, katoflns-nix-modules }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit katoflns-nix-modules; };
      modules = [
        home-manager.nixosModules.home-manager
        katoflns-nix-modules.default  # Import all of Katofln's modules; everything is disabled by default
        ./example/default.nix         # Your own configuration
      ];
    };
  };
}
```

**Enable a module in your NixOS configuration (`example/default.nix`):**

```nix
{ config, pkgs, katoflns-nix-modules, ... }: {
  # Set your username once for all modules
  katoflns-nix-modules.home-manager-username = "katofln";

  # Enable any modules you want — they'll use the username above
  katoflns-nix-modules.hello-nushell.enable = true;

  # Standard Home Manager setup
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.katofln = {
      home.stateVersion = "23.11";
    };
  };

  # Your user configuration
  users.users.katofln = {
    isNormalUser = true;
    # ... other user config
  };
}
```

Now you can run `hello-nushell` in your shell to get a friendly potato greeting! 🥔

# 🎛️ Module Options
## [`katoflns-nix-modules.git.enable`](modules/git/default.nix#L9)
Enable the Git module with configuration including:
- Core Git with LFS and gitk — targeting high-performance mono-repo-like usage
- Delta diff viewer
- GitHub CLI integration
- lazygit terminal UI
- gitui terminal UI
- Custom git aliases and commands
- Dracula theme for gitk
- Mergiraf syntax-aware merge conflict resolver

See the nix file for full details.

**Type:** `boolean`

**Default:** `false`

**Example:** `true`

## [`katoflns-nix-modules.git.signingKey`](modules/git/default.nix#L35)
The GPG key ID to use for signing commits.

**Type:** `lib.types.nullOr lib.types.str`

**Default:** `null`

**Example:** `"0600 cf90 aa2a ea55 07a0  e657 4f43 3d8d 3205 3651"`

## [`katoflns-nix-modules.git.userEmail`](modules/git/default.nix#L29)
Git email.

**Type:** `lib.types.str`

**Example:** `"katofln@example.com"`

## [`katoflns-nix-modules.git.userName`](modules/git/default.nix#L23)
Git username.

**Type:** `lib.types.str`

**Example:** `"katofln"`

## [`katoflns-nix-modules.helix.enable`](modules/helix/default.nix#L9)
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

**Type:** `boolean`

**Default:** `false`

**Example:** `true`

## [`katoflns-nix-modules.hello-nushell.enable`](modules/examples/hello-nushell/default.nix#L9)
Enable the `hello-nushell` greeting command.

**Type:** `boolean`

**Default:** `false`

**Example:** `true`

## [`katoflns-nix-modules.home-manager-username`](modules/default/default.nix#L5)
Username used for Home Manager integration across all of Katofln's modules. 🥔

This must be set when using any of Katofln's modules that integrate with Home Manager.
All modules will use this username in their Home Manager configuration.

**Type:** `lib.types.str`

**Example:** `"katofln"`
