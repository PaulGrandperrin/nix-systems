{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;
  home.file.".config/nixpkgs/config.nix".text = "{ allowUnfree = true; }"; # necessary to use unfree packages in `nix run/shell`, also needs `--impure`
  # systemd.user.systemctlPath = "/usr/bin/systemctl"; # TODO ?
  # targets.darwin.defaults # TODO?
  home = {
    stateVersion = "21.11";
    enableNixpkgsReleaseCheck = true; # check for release version mismatch between Home Manager and Nixpkgs
    sessionVariables = { # only works for interactive shells, pam works for all kind of sessions
      EDITOR = "vim";
    };
    packages = with pkgs; [
      # home-manager
      tree
      ncdu
      wget
      ripgrep
      pstree
      file
      #nvd # nix store diff-closures
      strace
      killall # psmisc, toybox?
      hostname
      #nix_2_4
      nix-du graphviz-nox
      #(rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
      #  #extensions = [ "rust-src" ];
      #  targets = [ "wasm32-unknown-emscripten" "wasm32-unknown-unknown"];
      #}))
      #(input.nixpkgs.rust-bin.stable.latest.default.override {
      #  #extensions = ["rust-src"];
      #  #targets = ["wasm32-unknown-emscripten"];
      #})
    ];
  };

  programs = {
    home-manager.enable = true;
    emacs.enable = true;
    exa.enable = true;
    direnv.enable = true;
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
        {
          plugin = tmuxPlugins.resurrect;
          extraConfig = "set -g @resurrect-strategy-nvim 'session'";
        }
        {
          plugin = tmuxPlugins.continuum;
          extraConfig = ''
            set -g @continuum-boot 'on'
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '5' # minutes
          '';
        }
      ];
    };
    topgrade.enable = true;
    gpg.enable = true;
    jq.enable = true;
    lazygit.enable = true;
    lsd.enable = true;
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
    powerline-go.enable = true;
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
      delta.enable = true;
      #signing?
    };
    fish = {
      enable = true;
      plugins = [{ # TODO add fish-done
        name = "bobthefish";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "theme-bobthefish";
          rev = "626bd39b002535d69e56adba5b58a1060cfb6d7b";
          #sha256 = lib.fakeSha256;
          sha256 = "zUngqEZgHLmlyvoiVO3MwJTSFsYD7t3XiP6yMzmMkBs=";
        };
      }];
    };
  };


}

