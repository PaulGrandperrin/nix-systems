args @ {pkgs, config, inputs, system, lib, mainFlake, ...}: {
  xdg.enable = true; # export XDG vars to ensure the correct directories are used

  nixpkgs.config.allowUnfree = true; # only works inside HM
  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }"; # works for `nix run/shell`, also needs `--impure`

  nix.package = pkgs.nixUnstable;
  nix.settings."experimental-features" = "nix-command flakes";

  nix.registry = {
    #nixos.flake = inputs.nixos;
    #nixos-small.flake = inputs.nixos-small;
    #nixos-unstable.flake = inputs.nixos-unstable;
    #nixpkgs-darwin.flake = inputs.nixpkgs-darwin;
    #nur.flake = inputs.nur;
    #flake-utils.flake = inputs.flake-utils;
    #rust-overlay.flake = inputs.rust-overlay;
    #home-manager.flake = inputs.home-manager;
    n.flake = mainFlake;
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
      httpie curlie xh
      entr
      tig
      choose
      tmate
      du-dust
      fq # not yet available in 21.11
      smartmontools

      sops
      ssh-to-age

      #man
      man-pages
      man-pages-posix


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
    ++ lib.optionals pkgs.stdenv.isLinux (
      [
        dstat
        sysstat
        strace
        bmon
        btop
        zenith
        intel-gpu-tools
        difftastic # FIXME broken on darwin

        nix-alien
        nix-index
        nix-index-update

        #unstable.nix
        #unstable.nixos-rebuild

        cpuid
        stress
        hwinfo
        lm_sensors
 
        mold
      ] ++ lib.optionals (config.home.username == "root") [ # if root and linux
        parted
        iftop
        powertop
        i7z
      ]
    );
  };

  # install ssh authorized keys, sshd complains if that's a symlink to the /nix/store
  # only for non-root users
  home.activation = lib.mkIf (config.home.username != "root") (let
    ssh-authorized-keys = pkgs.writeText "ssh-authorized-keys" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVW/7zXgQwIAk46daSBfP5ti7zpADrs1p//f5IyRHJH paulg@darwin-MacBookPaul
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE paulg@nixos-gcp
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE root@nixos-gcp
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3KlABFus1z3jTDvylO6e6gSnn7nIqJKZOZJ9di5OW4 paulg@nixos-xps
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOIxgOXuz4/8JB++umc4fEvFwIlM3eeVadTsvCZCQN2 root@nixos-xps
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBKbOypMYzisA9fwYtZVWWtcvsOqA294EEBIYN/9YCr paulg@nixos-MacBookPaul
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMK/GnaGGlU7pl4po31XP6K5VpodTu67J+D1/3d74R57 root@nixos-MacBookPaul
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5s0Fe3Y2kX5bxhipkD/OGePPRew40fElqzgacdavuY root@nixos-nas
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSJQGYQs+KJX+V/X3KxhyQgahE0g+ITF2jr1wUY1s/3 paulg@nixos-nas
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvmspiXsIgqF+idEIyEierOJa3m/665LP1U1TkwNx/8 root@MacMiniPaul
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLwI5YV8LFCX4MD64uZg6KV5ln+HgMWHR1r/rjVV6T7 paulg@MacMiniPaul
  '';
  in {
    copySshAuthorizedKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
     $DRY_RUN_CMD install $VERBOSE_ARG -m700 -d ${config.home.homeDirectory}/.ssh
     $DRY_RUN_CMD install $VERBOSE_ARG -m600 ${ssh-authorized-keys} ${config.home.homeDirectory}/.ssh/authorized_keys
   '';
  });

  services.gpg-agent = {
    enable = true;
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };
  programs = {
    home-manager.enable = true;
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
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
    topgrade.enable = !pkgs.stdenv.isDarwin; # FIXME broken on darwin
    gpg = {
      enable = true;
      settings = {
        pinentry-mode = "loopback";
      };
    };
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
    #starship = {
    #  enable = true;
    #};
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
      signing = {
        key = "4AB1353033774DA3";
      };
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
        fish_add_path --move --prepend --path $HOME/.nix-profile/bin /run/wrappers/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin # https://github.com/LnL7/nix-darwin/issues/122
      '';
      shellAbbrs = {
        ssh-keygen = "ssh-keygen -t ed25519";
        nixos-rebuild-gcp = "nixos-rebuild --flake git+file:///etc/nixos#nixos-gcp --use-substitutes --target-host root@paulg.fr";
      };
      plugins = [ # TODO add fish-done
        {
           name = "bobthefish";
           src = pkgs.fetchFromGitHub {
             owner = "oh-my-fish";
             repo = "theme-bobthefish";
             rev = "14a6f2b317661e959e13a23870cf89274f867f12";
             #sha256 = pkgs.lib.fakeSha256;
             sha256 = "sha256-kl6XR6IFk5J5Bw7/0/wER4+TnQfC18GKxYbt9C+YHJ0=";
           };
        }
        #{ 
        #  name = "tide";
        #  src = pkgs.fetchFromGitHub {
        #    owner = "IlanCosman";
        #    repo = "tide";
        #    rev = "v5.2.2";
        #    #sha256 = pkgs.lib.fakeSha256;
        #    sha256 = "sha256-yj6Oh7gxjrzc4N8WdCGRDImdOLHqI+cFIg1VF3nx33g=";
        #  };
        #}
        #{ 
        #  name = "fish-async-prompt";
        #  src = pkgs.fetchFromGitHub {
        #    owner = "acomagu";
        #    repo = "fish-async-prompt";
        #    rev = "v1.2.0";
        #    #sha256 = pkgs.lib.fakeSha256;
        #    sha256 = "sha256-B7Ze0a5Zp+5JVsQUOv97mKHh5wiv3ejsDhJMrK7YOx4=";
        #  };
        #}
      ];
    };
  };


}

