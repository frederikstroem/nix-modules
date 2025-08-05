{ pkgs, lib, config, inputs, ... }:

{

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

  tasks = {

    "init:git-hooks" = {
      exec = "./git_hooks/setup_git_hooks.sh";
      after = [ "devenv:enterShell" ];
    };

  };

  enterShell = ''
    echo
    echo -e "\033[1;94m❓️\033[0m\033[0;34m Run \`devenv info\` to print information about this developer environment.\033[0m"
  '';

}
