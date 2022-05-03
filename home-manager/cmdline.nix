args @ {pkgs, config, inputs, system, lib, ...}: {
  home.file.".config/nixpkgs/config.nix".text = "{ allowUnfree = true; }"; # "nixpkgs.config.allowUnfree = true;" is not enough to work with `nix run/shell`, also needs `--impure`
  home.file.".config/nix/nix.conf".text = "experimental-features = nix-command flakes";

  # install ssh authorized keys, sshd complains if that's a symlink to the /nix/store
  home.activation = let
    ssh-authorized-keys = pkgs.writeText "ssh-authorized-keys" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+tckVW3zh58Cr246EuceDY/HdgoJrmSnYTNEv0Y3HW
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVW/7zXgQwIAk46daSBfP5ti7zpADrs1p//f5IyRHJH
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdJ9evK0Ay1KFOBG+EZC7xPOb8udcltjg8rTFpHimz5
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjsf+KqGyIAhHxL54740gfH+qQxQl7K1liLsvaGvlHK
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3KlABFus1z3jTDvylO6e6gSnn7nIqJKZOZJ9di5OW4
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOIxgOXuz4/8JB++umc4fEvFwIlM3eeVadTsvCZCQN2
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBKbOypMYzisA9fwYtZVWWtcvsOqA294EEBIYN/9YCr
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMK/GnaGGlU7pl4po31XP6K5VpodTu67J+D1/3d74R57
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5s0Fe3Y2kX5bxhipkD/OGePPRew40fElqzgacdavuY
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSJQGYQs+KJX+V/X3KxhyQgahE0g+ITF2jr1wUY1s/3
  '';
  in {
    copySshAuthorizedKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
     $DRY_RUN_CMD install $VERBOSE_ARG -m700 -d ${config.home.homeDirectory}/.ssh
     $DRY_RUN_CMD install $VERBOSE_ARG -m600 ${ssh-authorized-keys} ${config.home.homeDirectory}/.ssh/authorized_keys
   '';
  };

  # systemd.user.systemctlPath = "/usr/bin/systemctl"; # TODO ?
  home = {
    stateVersion = "21.11";
    enableNixpkgsReleaseCheck = true; # check for release version mismatch between Home Manager and Nixpkgs
    sessionVariables = { # only works for interactive shells, pam works for all kind of sessions
      EDITOR = "vim";
    };
    packages = with pkgs; [
      gnugrep
      findutils
      which
      gzip
      openssh
      rsync

      fd
      tree
      ncdu
      wget
      ripgrep
      pstree
      file
      #nvd # nix store diff-closures
      killall # psmisc, toybox?
      hostname
      nix-du graphviz-nox
      jq yq
      ruby pry
      mycli
      tldr
      hyperfine
      ranger
      cachix
      manix
      neofetch
      unzip p7zip
      pv
      duf
      wireshark-cli
      youtube-dl
      ffmpeg
      gdu
      pgcli
      sd
      difftastic
      httpie curlie xh
      entr
      tig
      choose
      tmate
      du-dust
      unstable.fq # not yet available in 21.11
      smartmontools


      #dev
      gnumake
      gcc11
      (lib.setPrio 20 clang_13)

      # utility to fetch and launch missing but unambiguous commands
      (pkgs.writeShellApplication {
        name = "fr";
        text = ''
          result=$(${sqlite}/bin/sqlite3 "/nix/var/nix/profiles/per-user/root/channels/nixos/programs.sqlite" "select package from Programs where system = '${system}' and name = '$1'")
          if [ -z "$result" ]; then
            >&2 printf "Failed: no package provides '%s'\n" "$1"
          elif [ "$(echo "$result"|wc -l)" -gt 1 ]; then
            >&2 printf "Failed: multiple packages provide '%s': \n%s\n" "$1" "$result"
          else
            exec nix shell "n#$result" -c "$@"
          fi
        '';
      })
    ]
    ++ (if system == "x86_64-linux" then [ # linux only
      dstat
      sysstat
      strace
      bmon
      btop
      zenith

      nix-alien
      nix-index
      nix-index-update

      unstable.nix
      unstable.nixos-rebuild
    ] else []);
  };

  programs = {
    home-manager.enable = true;
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      } // pkgs.lib.optionalAttrs (!args ? is_unstable) { enableFlakes = true; };
    };
    emacs.enable = true;
    exa = {
      enable = true;
      enableAliases = false;
    };
    lsd = {
      enable = true;
      enableAliases = true;
    };
    bat.enable = true;
    htop.enable = true;
    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
    };
    gh.enable = true;
    nnn.enable = true;
    noti.enable = true;
    nushell.enable = true;
    bottom.enable = true;
    broot.enable = true;
    tmux = {
      enable = true;
      plugins = with pkgs; [
        tmuxPlugins.cpu
    #    {
    #      plugin = tmuxPlugins.resurrect;
    #      extraConfig = "set -g @resurrect-strategy-nvim 'session'";
    #    }
    #    {
    #      plugin = tmuxPlugins.continuum;
    #      extraConfig = ''
    #        set -g @continuum-boot 'on'
    #        set -g @continuum-restore 'on'
    #        set -g @continuum-save-interval '5' # minutes
    #      '';
    #    }
      ];
    };
    #topgrade.enable = true; # FIXME currently broken on darwin
    gpg.enable = true;
    jq.enable = true;
    lazygit.enable = true;
    skim.enable = true;
    rbw = {
      enable = true;
      settings = {
        email = "paul.grandperrin@gmail.com";
        lock_timeout = 300;
        pinentry = "curses";
        device_id = "ea9f961d-c0cc-423c-accf-599fc08c42e0";
      };
    };
    zoxide.enable = true;
    #powerline-go.enable = true;
    man = {
      enable = true; # by default
      generateCaches = true;
    };
    #mcfly = {
    #  enable = true;
    #  enableFuzzySearch = true;
    #};
    neovim = {
      enable = true;
      ## "backport" neovim from unstable
      #package = pkgs.callPackage (inputs.nixos-unstable.outPath + "/pkgs/applications/editors/neovim") { lua = pkgs.luajit; };
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins =  with pkgs.vimPlugins;  [
        vim-surround # Shortcuts for setting () {} etc.
        vim-nix # nix highlight
        neovim-fuzzy # fuzzy finder through vim
        vim-lastplace # restore cursor position
      ];
    };
    git = {
      enable = true;
      userName = "Paul Grandperrin";
      userEmail = "paul.grandperrin@gmail.com";
      delta = {
        enable = true;
        options = {
          navigate = true;
          line-numbers = true;
          syntax-theme = "Dracula";
        };
      };
      extraConfig = {
        init.defaultBranch = "main";
        pull.ff = "only";
        merge.conflictstyle = "diff3";
      };
      #signing?
    };
    fish = {
      enable = true;
      interactiveShellInit = ''
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source # use fish in nix run and nix-shell
        source ${
          pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/gnachman/iTerm2/c52136b7c0bae545436be8d1441449f19e21faa1/Resources/shell_integration/iterm2_shell_integration.fish";
            sha256 = "sha256-l7KdmiJlbGy/ozC+l5rrmEebA8kZgV7quYG5I/MHDOI=";
          }
        }
      '';
      loginShellInit = ''
        fish_add_path --move --prepend --path $HOME/.nix-profile/bin /run/wrappers/bin /etc/profiles/per-user/$USER/bin /nix/var/nix/profiles/default/bin /run/current-system/sw/bin # https://github.com/LnL7/nix-darwin/issues/122
      '';
      shellAbbrs = {
        ssh-keygen = "ssh-keygen -t ed25519";
        nixos-rebuild-gcp = "nixos-rebuild --flake git+file:///etc/nixos#nixos-gcp --use-substitutes --target-host root@paulg.fr";
      };
      plugins = [{ # TODO add fish-done
        name = "bobthefish";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "theme-bobthefish";
          rev = "14a6f2b317661e959e13a23870cf89274f867f12";
          #sha256 = pkgs.lib.fakeSha256;
          sha256 = "sha256-kl6XR6IFk5J5Bw7/0/wER4+TnQfC18GKxYbt9C+YHJ0=";
        };
      }];
    };
  };


}

