{ pkgs, lib, config, inputs, ... }:

{

  # Import the parallel-git-hooks module.
  imports = [
    inputs.parallel-git-hooks.devenvModule
  ];

  packages = with pkgs; [
    nushell
    inputs.nix-options-doc.packages.${pkgs.system}.default
  ];

  scripts = {

    update-readme = {
      exec = builtins.readFile ./scripts/update-readme.nu;
      package = pkgs.nushell;
      binary = "nu";
    };

  };

  # Configure parallel Git hooks.
  parallel-git-hooks = {
    enable = true;
    # logLevel = "DEBUG";
    hooks = [
      {
        name = "Update README.md";
        cmd = "update-readme";
        fileFilter = "^README\\.md$";
      }
    ];
  };

  enterShell = ''
    echo
    echo -e "\033[1;94m❓️\033[0m\033[0;34m Run \`devenv info\` to print information about this developer environment.\033[0m"
  '';

}
