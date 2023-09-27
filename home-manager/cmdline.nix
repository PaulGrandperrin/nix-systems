args @ {pkgs, config, inputs, system, lib, mainFlake, ...}: {
  imports = [
    inputs.nix-index-database.hmModules.nix-index
  ];
  xdg.enable = true; # export XDG vars to ensure the correct directories are used

  nixpkgs.config.allowUnfree = true; # only works inside HM
  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }"; # works for `nix run/shell`, also needs `--impure`

  nix = {
    settings."experimental-features" = "nix-command flakes repl-flake";

    registry = {
      #nixos.flake = inputs.nixos;
      #nixos-small.flake = inputs.nixos-small;
      nixos-unstable.flake = inputs.nixos-unstable;
      #nixpkgs-darwin.flake = inputs.nixpkgs-darwin;
      #nur.flake = inputs.nur;
      #flake-utils.flake = inputs.flake-utils;
      #rust-overlay.flake = inputs.rust-overlay;
      #home-manager.flake = inputs.home-manager;
      n.flake = mainFlake;
      nixpkgs.flake = mainFlake;
    };
    #registry = lib.mapAttrs (_: value: { flake = value; }) inputs; # nix.generateRegistryFromInputs in flake-utils-plus
    #nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry; # nix.generateNixPathFromInputs in flake-utils-plus # nix.nixPath is not available in HM
  };

  # systemd.user.systemctlPath = "/usr/bin/systemctl"; # TODO ?
  home = {
    stateVersion = "22.05";
    enableNixpkgsReleaseCheck = true; # check for release version mismatch between Home Manager and Nixpkgs
    sessionVariables = { # only works for interactive shells, pam works for all kind of sessions
      EDITOR = "vim";
      NIX_PATH = (lib.concatStringsSep ":" (lib.mapAttrsToList (name: path: "${name}=${path.to.path}") config.nix.registry));
    };

    file.".cargo/config.toml" = lib.mkIf pkgs.stdenv.isLinux {
      text = ''
        [target.x86_64-unknown-linux-gnu]
        linker = "${pkgs.clang_13}/bin/clang"
        rustflags = ["-C", "link-arg=--ld-path=${pkgs.mold}/bin/mold"]
      '';
    };

    # always keep a reference to the source flake that generated each generations
    file.".source-flake".source = ../.;

    packages = with pkgs; [
      config.nix.package
      gnugrep
      findutils
      which
      gzip
      openssh
      rsync
      unstable.nixd
      socat
      whois

      trashy
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
      #mycli
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
      fq
      smartmontools
      wireguard-tools
      dogdns
      colmena
      wakelan
      pciutils
      lsof
      e2fsprogs
      nmap
      iperf

      sops
      ssh-to-age

      #man
      man-pages
      man-pages-posix


      #dev
      gnumake
      gcc11
      (lib.setPrio 20 clang_13)
      rnix-lsp

      ((pkgs.writeShellApplication {
        name = "git";
        text = ''
          pname="$(ps -o comm= $PPID)"
          if [ "$pname" == "nix" ] && [ "$#" -ge 9 ] && [ "$5" == "add" ] && [ "$6" == "--force" ] && [ "$7" == "--intent-to-add" ] && [ "$8" == "--" ] && [ "$9" == "flake.lock" ]; then
            exit 0
          else
            exec -a "$0" "${pkgs.git}/bin/git" "$@" 
          fi
        '';
      }).overrideAttrs (final: prev: {
        meta.priority = 1;
      }))
    ]
    ++ lib.optionals pkgs.stdenv.isLinux (
      [
        lshw
        dstat
        sysstat
        strace
        bmon
        btop
        difftastic # FIXME broken on darwin
        lsb-release
        usbutils
        usbtop
        wl-clipboard # used by neovim to yank to clipboard

        #nix-alien # or nix-autobahn
        #nix-index
        #nix-index-update

        #unstable.nix
        #unstable.nixos-rebuild

        stress
        hwinfo
        lm_sensors
 
        mold
        bintools
        distrobox
      ] ++ lib.optionals (config.home.username == "root") [ # if root and linux
        parted
        iftop
        powertop
        ethtool
        dmidecode
        bcc
        #mkosi # in 23.11
        tpm2-tools
        ntfs3g
      ]
    ) ++ lib.optionals (system == "x86_64-linux") (
      [ 
        cpuid
        cpufrequtils
        zenith
        intel-gpu-tools
      ] ++ lib.optionals (config.home.username == "root") [ # if root and linux
        i7z
        sbctl # secure boot key manager
        efibootmgr
        efitools
      ]
    );
  };

  # install ssh authorized keys, sshd complains if that's a symlink to the /nix/store
  # only for non-root users
  home.activation = lib.mkIf (config.home.username != "root") (let
    ssh-authorized-keys = pkgs.writeText "ssh-authorized-keys" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVW/7zXgQwIAk46daSBfP5ti7zpADrs1p//f5IyRHJH paulg@darwin-macbook
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE paulg@nixos-gcp
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE root@nixos-gcp
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3KlABFus1z3jTDvylO6e6gSnn7nIqJKZOZJ9di5OW4 paulg@nixos-xps
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOIxgOXuz4/8JB++umc4fEvFwIlM3eeVadTsvCZCQN2 root@nixos-xps
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBKbOypMYzisA9fwYtZVWWtcvsOqA294EEBIYN/9YCr paulg@nixos-macbook
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMK/GnaGGlU7pl4po31XP6K5VpodTu67J+D1/3d74R57 root@nixos-macbook
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5s0Fe3Y2kX5bxhipkD/OGePPRew40fElqzgacdavuY root@nixos-nas
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSJQGYQs+KJX+V/X3KxhyQgahE0g+ITF2jr1wUY1s/3 paulg@nixos-nas
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvmspiXsIgqF+idEIyEierOJa3m/665LP1U1TkwNx/8 root@nixos-macmini
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLwI5YV8LFCX4MD64uZg6KV5ln+HgMWHR1r/rjVV6T7 paulg@nixos-macmini
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsQJwr21m67xQIUqnHAc4wGkaj6o/Uy002xgN34G8Wj root@nixos-oci
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUV9km+CluTn/QZGOstjxNpPEVkxWktmNrlC8Xqss4F paulg@nixos-oci
  '';
  in {
    copySshAuthorizedKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
     $DRY_RUN_CMD install $VERBOSE_ARG -m700 -d ${config.home.homeDirectory}/.ssh
     $DRY_RUN_CMD install $VERBOSE_ARG -m600 ${ssh-authorized-keys} ${config.home.homeDirectory}/.ssh/authorized_keys
   '';
  });

  services.gpg-agent = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    defaultCacheTtl = 60 * 60 * 24;
    extraConfig = ''
      allow-loopback-pinentry
      max-cache-ttl ${toString (60 * 60 * 24 * 7)}
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
    nix-index-database.comma.enable = true;
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
    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };
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
    neovim =  {
      enable = true;
      #package = pkgs.unstable.neovim-unwrapped;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins =  with pkgs.vimPlugins;  [
        vim-surround # Shortcuts for setting () {} etc.
        vim-nix # nix highlight
        neovim-fuzzy # fuzzy finder through vim
        vim-lastplace # restore cursor position
        # LSP
        pkgs.unstable.vimPlugins.nvim-lspconfig
        #pkgs.unstable.vimPlugins.lsp-zero-nvim
        (
          pkgs.vimUtils.buildVimPluginFrom2Nix {
            pname = "lsp-zero.nvim";
            version = "2023-09-23";
            src = pkgs.fetchFromGitHub {
              owner = "VonHeikemen";
              repo = "lsp-zero.nvim";
              rev = "011edd4afede7030cb17248495063ab8f3bd0e57";
              sha256 = "sha256-AW9QVBjvnxVcAvS1IUivra+B+8hHBfJyy/vIY1TszQs=";
            };
            meta.homepage = "https://github.com/VonHeikemen/lsp-zero.nvim/";
          }
        )
        # autocomplete
        pkgs.unstable.vimPlugins.nvim-cmp
        pkgs.unstable.vimPlugins.cmp-buffer
        pkgs.unstable.vimPlugins.cmp-path
        pkgs.unstable.vimPlugins.cmp_luasnip
        pkgs.unstable.vimPlugins.cmp-nvim-lsp
        pkgs.unstable.vimPlugins.cmp-nvim-lua
        # snippets
        pkgs.unstable.vimPlugins.luasnip
        pkgs.unstable.vimPlugins.friendly-snippets
      ];
      #extraConfig = ''
      #'';
      extraLuaConfig = ''
        vim.cmd("set mouse=")
        -- reserve space for diagnostic icons
        vim.opt.signcolumn = 'yes'

        local lsp = require('lsp-zero').preset({
          name = 'system-lsp',
          set_lsp_keymaps = true,
          manage_nvim_cmp = true,
        })

        lsp.configure('rust_analyzer', {
        force_setup = true, -- skip checks because it's installed globally
          on_attach = function(client, bufnr)
            print('hello rust')
          end
        })

        lsp.configure('nixd', {
        force_setup = true, -- skip checks because it's installed globally
          on_attach = function(client, bufnr)
            print('hello nix')
          end
        })
  
        lsp.setup()
      '';
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
      difftastic = {
        #enable = true;
        background = "dark";
        #display = "side-by-side"; # "side-by-side", "side-by-side-show-both", "inline"
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
    kitty.enable = true;
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
      shellAliases = {
        icat = "kitty +kitten icat";
        ssh = "kitty +kitten ssh";
      };
      shellAbbrs = {
        ssh-keygen-ed25519 = "ssh-keygen -t ed25519";
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

