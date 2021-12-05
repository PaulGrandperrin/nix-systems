{pkgs, ...}: {
  home = {
    stateVersion = "21.11";
    enableNixpkgsReleaseCheck = true;
    sessionVariables = {
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
      nvd
      strace
      killall # psmisc, toybox?
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
    #foot kitty alacritty
    emacs.enable = true;
    exa.enable = true;
    direnv.enable = true;
    bat.enable = true;
    htop.enable = true;
    fzf.enable = true;
    gh.enable = true;
    bottom.enable = true;
    broot.enable = true;
    tmux.enable = true;
    topgrade.enable = true;
    gpg.enable = true;
    jq.enable = true;
    lazygit.enable = true;
    lsd.enable = true;
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
      plugins = [{
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

