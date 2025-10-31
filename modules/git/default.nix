{ config, lib, pkgs, ... }:

let
  cfg = config.katoflns-nix-modules.git;
  username = config.katoflns-nix-modules.home-manager-username;
in
{
  options.katoflns-nix-modules.git = {
    enable = lib.mkEnableOption ''
      Enable the Git module with configuration including:
      - Core Git with LFS and gitk — targeting high-performance mono-repo-like usage
      - Delta diff viewer
      - GitHub CLI integration
      - lazygit terminal UI
      - Custom git aliases and commands
      - Dracula theme for gitk
      - Mergiraf syntax-aware merge conflict resolver

      See the nix file for full details.
    '';

    userName = lib.mkOption {
      type = lib.types.str;
      description = "Git username.";
      example = "katofln";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Git email.";
      example = "katofln@example.com";
    };

    signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The GPG key ID to use for signing commits.";
      example = "0600 cf90 aa2a ea55 07a0  e657 4f43 3d8d 3205 3651";
    };
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
            katoflns-nix-modules.home-manager-username = "your-username";
        '';
      }
      {
        assertion = cfg.userName != "";
        message = ''
          The option `katoflns-nix-modules.git.userName` must be set
          when the git module is enabled.

          Add this to your configuration:
            katoflns-nix-modules.git.userName = "Your Name";
        '';
      }
      {
        assertion = cfg.userEmail != "";
        message = ''
          The option `katoflns-nix-modules.git.userEmail` must be set
          when the git module is enabled.

          Add this to your configuration:
            katoflns-nix-modules.git.userEmail = "your.email@example.com";
        '';
      }
    ];

    # Ensure Git is installed system-wide.
    environment.systemPackages = with pkgs; [
      git
    ];

    # Home Manager configuration for the specified user.
    home-manager.users.${username} = { config, pkgs, ... }:

      # This is a hack to merge multiple `home.packages` attributes into one.
      # Allowing multiple `home.packages` attributes in the same file, instead of failing with
      # `error: attribute 'home.packages' already defined at /nix/store/…`.
      # Source: https://web.archive.org/web/20250415072300/https://gist.github.com/udf/4d9301bdc02ab38439fd64fbda06ea43
      let
        inherit (lib) attrNames unique concatMap foldAttrs mapAttrs mkMerge;
        # Get a unique flat list of all top-level keys from a list of attribute sets.
        allTopLevelKeys = attrsList:
          unique (concatMap attrNames attrsList);
        # Merge all the attribute sets.
        mergeEverything = attrsList:
          let
            keys = allTopLevelKeys attrsList;
            merged = mapAttrs (_: v: mkMerge v) (
              foldAttrs (n: a: [n] ++ a) [] attrsList
            );
          in
            merged;
      in {
        config = mergeEverything [
          {
            ###
            ### Git
            ###
            programs.git = {
              enable = true;
              package = lib.mkDefault pkgs.gitFull; # Git full adds `gitk`
              settings = {
                user = {
                  name = cfg.userName;
                  email = cfg.userEmail;
                };
                signing = lib.mkIf (cfg.signingKey != null) {
                  key = cfg.signingKey;
                };
                lfs = {
                  enable = lib.mkDefault true;
                };
                core = {
                  editor = lib.mkDefault "hx"; # Helix
                  packedGitLimit = lib.mkDefault "16g";
                  packedGitWindowSize = lib.mkDefault "16g";
                };
                pack = {
                  deltaCacheSize = lib.mkDefault "1g";
                  packSizeLimit = lib.mkDefault "16g";
                  windowMemory = lib.mkDefault "16g";
                };
                http = {
                  postBuffer = lib.mkDefault 524288000;
                };
                init = {
                  defaultBranch = lib.mkDefault "main";
                };
              };
            };
          }
          {
            ###
            ### Delta
            ###
            ### https://github.com/dandavison/delta
            ### 🦀 Rust 🚀
            ###
            programs.delta = {
              enable = lib.mkDefault true;
              enableGitIntegration = lib.mkDefault true;
              options = {
                dark = lib.mkDefault true;
                features = lib.mkDefault "decorations";
                line-numbers = lib.mkDefault true;
              };
            };
          }
          {
            ###
            ### GitHub CLI
            ###
            ### https://cli.github.com/
            ### https://github.com/cli/cli
            ###
            programs.gh = {
              enable = lib.mkDefault true;
              gitCredentialHelper.enable = lib.mkDefault true;
            };
          }
          {
            ###
            ### lazygit
            ###
            ### A simple terminal UI for git commands.
            ###
            ### https://github.com/jesseduffield/lazygit
            ###
            programs.lazygit = {
              enable = lib.mkDefault true;
              settings = {
                gui = {
                  showNumstatInFilesView = lib.mkDefault true;
                  showRandomTip = lib.mkDefault false;
                  showCommandLog = lib.mkDefault false;
                };
                disableStartupPopups = lib.mkDefault true;
              };
            };
          }
          {
            ###
            ### git-* aliases (all shells)
            ###
            home.packages = with pkgs; [
              # Prune or list local tracking branches that do not exist on remote anymore.
              # https://stackoverflow.com/questions/13064613/how-to-prune-local-tracking-branches-that-do-not-exist-on-remote-anymore/17029936#17029936
              (writeShellScriptBin "git-list-untracked" ''
                git fetch --prune && git branch -r | awk "{print \$1}" | grep -E -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}"
              '')
              (writeShellScriptBin "git-remove-untracked" ''
                git fetch --prune && git branch -r | awk "{print \$1}" | grep -E -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -d
              '')
              (writeShellScriptBin "git-remove-untracked-force-unmerged" ''
                git fetch --prune && git branch -r | awk "{print \$1}" | grep -E -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -D
              '')
              # Create backup of the current branch in the format `backup/<branch>_<YYYY>_<MM>_<DD>T<HH>_<MM>_<SS>Z>`
              # #!/usr/bin/env nu
              (writeScriptBin "git-backup-current-branch" ''
                #!${pkgs.nushell}/bin/nu

                git branch $'backup/(git branch --show-current)_(date now | date to-timezone utc | format date "%Y_%m_%dT%H_%M_%SZ")'
              '')
            ];
          }
          {
            ###
            ### git-* aliases (Nushell)
            ###
            programs.nushell.configFile.text = lib.mkAfter (''
              # Aggressively optimize and compress the Git repository.
              def git-optimize [
                --prune # Also expire reflogs and remove all unreachable/dangling objects.
              ] {
                if ($prune) {
                  print $"(ansi yellow)"
                  print "⚠️ Script will:"
                  print "1️⃣ Repack all objects with maximum compression"
                  print "2️⃣ Run an aggressive garbage-collection"
                  print "3️⃣ Expire all reflog entries so unreachable objects become eligible"
                  print "4️⃣ Prune all now-unreachable objects immediately"
                  print $"(ansi reset)"
                } else {
                  print $"(ansi yellow)"
                  print "ℹ️ Script will:"
                  print "1️⃣ Repack all objects with maximum compression"
                  print "2️⃣ Run an aggressive garbage-collection"
                  print $"(ansi reset)"
                }

                print $"(ansi cyan)"
                print "🔧 Optimizing Git repository…"
                print -n $"(ansi reset)"

                # 1. Repack all objects with maximum compression
                git repack -a -d --depth=250 --window=250

                # 2. Run an aggressive garbage-collection
                git gc --aggressive

                if $prune {
                  print $"(ansi cyan)"
                  print "📊 Gathering stats before prune…"
                  print -n $"(ansi reset)"
                  git count-objects --verbose

                  print $"(ansi cyan)"
                  print "🗑️ Pruning objects…"
                  print -n $"(ansi reset)"

                  # 3a. Expire all reflog entries so unreachable objects become eligible
                  git reflog expire --expire-unreachable=now --all

                  # 3b. Prune all now-unreachable objects, listing each deletion
                  git prune --expire now --verbose

                  # 3c. Final aggressive GC with immediate prune to clean up any new loose objects
                  git gc --prune=now

                  print $"(ansi cyan)"
                  print "📊 Gathering stats after prune…"
                  print -n $"(ansi reset)"
                  git count-objects --verbose
                }
              }
            '');
          }
          {
            ###
            ### Git aliases (Nushell)
            ###
            programs.nushell.shellAliases = {
              # Git core command
              g = "git";

              # Single characters for most frequent commands
              "g a" = "git add";                     # add files
              "g c" = "git commit";                  # commit
              "g s" = "git status";                  # status
              "g d" = "git diff";                    # diff working directory
              "g f" = "git fetch --all --prune";     # fetch all and prune
              "g l" = "git log";                     # log
              "g r" = "git restore";                 # restore working directory files

              # Two characters for everything else
              "g aa" = "git add --all";              # add all files
              "g ca" = "git commit --amend";         # amend last commit
              "g co" = "git checkout";               # checkout branch/commit
              "g br" = "git branch";                 # list/create branches
              "g ds" = "git diff --staged";          # diff staged files

              # Remote operations
              "g ps" = "git push";                   # push
              "g pl" = "git pull";                   # pull
              "g mg" = "git merge";                  # merge
              "g rb" = "git rebase";                 # rebase
              "g ri" = "git rebase -i";              # interactive rebase

              # Log variations
              "g ls" = "git log --stat";             # log with file change stats
              "g lo" = "git log --oneline";          # one-line log

              # Stash operations
              "g st" = "git stash";                  # stash changes
              "g sp" = "git stash pop";              # pop stash
              "g sa" = "git stash apply";            # apply stash
              "g sl" = "git stash list";             # list stashes

              # Reset and cleanup
              "g rs" = "git reset";                  # reset
              "g rh" = "git reset --hard";           # hard reset
              "g cl" = "git clean -fd";              # clean untracked files

              # Branch management
              "g bd" = "git branch -d";              # delete branch
              "g bD" = "git branch -D";              # force delete branch
              "g ba" = "git branch -a";              # list all branches

              # Other useful commands
              "g cp" = "git cherry-pick";            # cherry-pick
              "g tg" = "git tag";                    # tags
              "g bl" = "git blame";                  # blame
              "g sh" = "git show";                   # show commit
              "g wt" = "git worktree";               # worktree operations
            };
          }
          {
            ###
            ### Dracula for gitk
            ### 🧛 Dark theme for gitk
            ###
            ### https://draculatheme.com/gitk
            ### https://github.com/dracula/gitk
            ###
            xdg.configFile."git/gitk" = {
              force = true;
              # https://web.archive.org/web/20250910174643/https://github.com/dracula/gitk/blob/6e9749231549ca1a940b733f2629701e80b97fe2/gitk
              text = ''
                set uicolor #44475a
                set want_ttk 0
                set bgcolor #282a36
                set fgcolor #f8f8f2
                set uifgcolor #f8f8f2
                set uifgdisabledcolor #6272a4
                set colors {#50fa7b #ff5555 #bd93f9 #ff79c6 #f8f8f8 #ffb86c #ffb86c}
                set diffcolors {#ff5555 #50fa7b #bd93f9}
                set mergecolors {#ff5555 #bd93f9 #50fa7b #bd93f9 #ffb86c #8be9fd #ff79c6 #f1fa8c #8be9fd #ff79c6 #8be9fd #ffb86c #8be9fd #50fa7b #ffb86c #ff79c6}
                set markbgcolor #282a36
                set selectbgcolor #44475a
                set foundbgcolor #f1fa8c
                set currentsearchhitbgcolor #ffb86c
                set headbgcolor #50fa7b
                set headfgcolor black
                set headoutlinecolor #f8f8f2
                set remotebgcolor #ffb86c
                set tagbgcolor #f1fa8c
                set tagfgcolor black
                set tagoutlinecolor #f8f8f2
                set reflinecolor #f8f8f2
                set filesepbgcolor #44475a
                set filesepfgcolor #f8f8f2
                set linehoverbgcolor #f1fa8c
                set linehoverfgcolor black
                set linehoveroutlinecolor #f8f8f2
                set mainheadcirclecolor #f1fa8c
                set workingfilescirclecolor #ff5555
                set indexcirclecolor #50fa7b
                set circlecolors {#282a36 #bd93f9 #44475a #bd93f9 #bd93f9}
                set linkfgcolor #bd93f9
                set circleoutlinecolor #44475a
                set diffbgcolors {{#342a36} #283636}
              '';
            };
          }
          {
            ###
            ### 🦒 Mergiraf 🦒
            ### A syntax-aware git merge driver for a growing collection of programming languages and file formats.
            ###
            ### https://mergiraf.org/
            ### https://codeberg.org/mergiraf/mergiraf
            ### 🦀 Rust 🚀
            ###
            home.packages = with pkgs; [
              # Install Mergiraf as a package for manual conflict resolution instead of as a merge driver.
              mergiraf
              # See what Mergiraf would do to a file, without actually doing anything.
              (writeShellScriptBin "mergiraf-delta" ''
                # Exit if no file is provided
                if [ -z "$1" ]; then
                  echo "Usage: mergiraf-delta <file-to-compare>"
                  exit 1
                fi

                FILE="$1"

                # Check that the file exists
                if [ ! -f "$FILE" ]; then
                  echo "Error: '$FILE' does not exist."
                  exit 1
                fi

                # Run delta to compare the original file to the output of mergiraf
                delta "$FILE" <(mergiraf solve -p "$FILE")
              '')
            ];
            # Override `mergiraf solve` command to always pass `--keep-backup=false` to avoid creating backup files.
            programs.nushell.configFile.text = lib.mkAfter (''
              # Backup `mergiraf` command.
              alias core-mergiraf = mergiraf

              def "mergiraf solve" [
                --keep-backup # Create a copy of the original file by adding the `.orig` suffix to it
                ...args
              ] {
                (
                  core-mergiraf solve
                  --keep-backup=($keep_backup)
                  ...$args
                )
              }
            '');
          }
      ];
    };
  };
}
