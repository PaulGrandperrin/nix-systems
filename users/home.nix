{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      # home-manager
      tree
      htop
      ncdu
      tmux
      topgrade
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
    git = {
      enable = true;
      userName = "Paul Grandperrin";
      userEmail = "paul.grandperrin@gmail.com";
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

