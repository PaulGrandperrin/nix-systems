{pkgs, config, inputs, lib, ...}: {
  imports = [
    inputs.nix-index-database.hmModules.nix-index
    ./fish.nix
    ./git.nix
  ];


  home = {
    sessionVariables = { # only works for interactive shells, pam works for all kind of sessions
      EDITOR = lib.mkDefault "nvim";
      NH_BYPASS_ROOT_CHECK = "true";
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
      nixvim
      unstable.nh
      fh
      zenith
      ruplacer


      socat
      whois
      util-linux # unshare nsenter

      fd
      tree
      wget
      ripgrep
      file
      psmisc # pstree killall
      hostname
      neofetch
      gdu dua du-dust # ncdu dutree pdu # du alternatives
      duf lfs # df alternatives
      choose
      dogdns
      wakelan
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      lsb-release
    ];
  };

  programs = {
    nix-index-database.comma.enable = true;
    lsd = {
      enable = true;
      enableFishIntegration = true;
    };
    bat.enable = true;
    htop.enable = true;
    zellij = {
      enable = true;
      #enableFishIntegration = true;
      settings = {
        pane_frames = false;
      };
    };
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
    gpg = {
      enable = true;
      settings = {
        pinentry-mode = "loopback";
      };
    };
    #neovim =  {
    #  enable = true;
    #  defaultEditor = true;
    #  extraPackages = with pkgs; [
    #    nixd
    #  ];

    #  #package = pkgs.unstable.neovim-unwrapped;
    #  viAlias = true;
    #  vimAlias = true;
    #  vimdiffAlias = true;
    #  plugins =  with pkgs.vimPlugins;  [
    #    vim-surround # Shortcuts for setting () {} etc.
    #    vim-nix # nix highlight
    #    neovim-fuzzy # fuzzy finder through vim
    #    vim-lastplace # restore cursor position
    #    splitjoin-vim # Switch between single-line and multiline forms of code 
    #    # LSP
    #    nvim-lspconfig
    #    lsp-zero-nvim
    #    #(
    #    #  pkgs.vimUtils.buildVimPlugin {
    #    #    pname = "lsp-zero.nvim";
    #    #    version = "2023-09-23";
    #    #    src = pkgs.fetchFromGitHub {
    #    #      owner = "VonHeikemen";
    #    #      repo = "lsp-zero.nvim";
    #    #      rev = "011edd4afede7030cb17248495063ab8f3bd0e57";
    #    #      sha256 = "sha256-AW9QVBjvnxVcAvS1IUivra+B+8hHBfJyy/vIY1TszQs=";
    #    #    };
    #    #    meta.homepage = "https://github.com/VonHeikemen/lsp-zero.nvim/";
    #    #  }
    #    #)
    #    # autocomplete
    #    nvim-cmp
    #    cmp-buffer
    #    cmp-path
    #    cmp_luasnip
    #    cmp-nvim-lsp
    #    cmp-nvim-lua
    #    # snippets
    #    luasnip
    #    friendly-snippets
    #  ];
    #  extraConfig = ''
    #  '';
    #  extraLuaConfig = ''
    #    vim.opt.undofile = true -- saves to $XDG_STATE_HOME/nvim/undo
    #    -- set.undolevels = 1000
    #    -- set.undoreload = 10000

    #    vim.cmd("set mouse=")
    #    -- reserve space for diagnostic icons
    #    vim.opt.signcolumn = 'yes'

    #    local lsp = require('lsp-zero').preset({
    #      name = 'system-lsp',
    #      set_lsp_keymaps = true,
    #      manage_nvim_cmp = true,
    #    })

    #    lsp.configure('rust_analyzer', {
    #    force_setup = true, -- skip checks because it's installed globally
    #      on_attach = function(client, bufnr)
    #        print('hello rust')
    #      end
    #    })

    #    lsp.configure('nixd', {
    #    force_setup = true, -- skip checks because it's installed globally
    #      on_attach = function(client, bufnr)
    #      end
    #    })
  
    #    lsp.setup()
    #  '';
    #};
  };
}

