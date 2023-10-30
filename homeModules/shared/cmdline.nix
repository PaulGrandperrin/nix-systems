{pkgs, config, osConfig ? null, inputs, lib, ...}: {
  imports = [
    inputs.nix-index-database.hmModules.nix-index
    ./fish.nix
  ];


  home = {
    sessionVariables = { # only works for interactive shells, pam works for all kind of sessions
      EDITOR = "vim";
    };


    packages = with pkgs; [
      config.nix.package

      # from https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/system-path.nix
      # acl # linux only
      # attr # linux only
      bashInteractive # bash with ncurses support
      bzip2
      (lib.hiPrio coreutils-full)
      cpio
      curl
      diffutils
      findutils
      gawk
      stdenv.cc.libc
      getent
      getconf
      gnugrep
      gnupatch
      gnused
      gnutar
      gzip
      xz
      less
      # libcap # linux only
      ncurses
      netcat
      openssh # config.programs.ssh.package 
      mkpasswd
      procps
      #su # only useful with suid
      time
      util-linux
      which
      zstd

      # vim distros from my overlay
      ksvim
      lzvim
      nvchad
      aovim
      lnvim
      spvim

      procs
      rsync
      unstable.nixd
      socat
      whois
      parallel
      util-linux # unshare nsenter
      sshfs
      rclone

      gdb
      elfutils

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
      wakelan
      pciutils
      lsof
      nmap
      iperf

      sops
      ssh-to-age

      #man
      man-pages
      man-pages-posix

      # graphics in term
      viu

      #dev
      gnumake
      gcc11
      (lib.setPrio 20 clang_16)
      rnix-lsp

      #((pkgs.writeShellApplication { # hack around https://github.com/NixOS/nix/issues/5810
      #  name = "git";
      #  text = ''
      #    pname="$(ps -o comm= $PPID)"
      #    if [ "$pname" == "nix" ] && [ "$#" -ge 9 ] && [ "$5" == "add" ] && [ "$6" == "--force" ] && [ "$7" == "--intent-to-add" ] && [ "$8" == "--" ] && [ "$9" == "flake.lock" ]; then
      #      exit 0
      #    else
      #      exec -a "$0" "${pkgs.git}/bin/git" "$@" 
      #    fi
      #  '';
      #}).overrideAttrs (final: prev: {
      #  meta.priority = 1;
      #}))
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
        trashy
        e2fsprogs

        (buildFHSEnv {
          name = "fhs-run";
          targetPkgs = pkgs: (with pkgs; [
          ]);
          runScript = writeShellScript "fhs-run" ''
            run="$1"
            if [ "$run" = "" ]; then
              echo "Usage: fhs-run command-to-run args..." >&2
              exit 1
            fi
            shift
  
            exec -- "$run" "$@"
          '';
        })

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
    ) ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (
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
    helix.enable = true;
    htop.enable = true;
    #fzf = {
    #  enable = true;
    #  tmux.enableShellIntegration = true;
    #};
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
    #starship = { # async prompt: https://gist.github.com/duament/bac0181935953b97ca71640727c9c029
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
      extraConfig = ''
      '';
      extraLuaConfig = ''
        vim.opt.undofile = true -- saves to $XDG_STATE_HOME/nvim/undo
        -- set.undolevels = 1000
        -- set.undoreload = 10000

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
      lfs = {
        enable = true;
        skipSmudge = true;
      };
    };
    kitty.enable = true;
    wezterm = {
      enable = true;
      package = pkgs.unstable.wezterm;
      extraConfig = ''
        local wezterm = require("wezterm")
        
        local  c = wezterm.config_builder()
        c:set_strict_mode(true)
        
        local act = wezterm.action
        c.keys = {
          {
            key = "-",
            mods = "SHIFT|ALT",
            action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
          },
          {
            key = "=",
            mods = "SHIFT|ALT",
            action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
          },
        }

        --c.color_scheme = 'Catppuccin Mocha'
        c.color_scheme = 'Darkside'
        
        return c
      '';
    };
  };
}

