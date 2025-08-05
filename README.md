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
## [`katoflns-nix-modules.home-manager-username`](modules/default/default.nix#L5)
Username used for Home Manager integration across all of Katofln's modules. 🥔

This must be set when using any of Katofln's modules that integrate with Home Manager.
All modules will use this username in their Home Manager configuration.

**Type:** `lib.types.str`

**Example:** `"katofln"`

## [`katoflns-nix-modules.hello-nushell.enable`](modules/examples/hello-nushell/default.nix#L9)
Enable the `hello-nushell` greeting command.

**Type:** `boolean`

**Default:** `false`

**Example:** `true`
