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
      git
      ripgrep
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
}

