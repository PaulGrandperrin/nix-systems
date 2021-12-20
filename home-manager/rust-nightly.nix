{pkgs, inputs, ...}: let 

  my-rust = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
    extensions = [
      "rust-src" # needed by rust-analyzer vscode extension when installed through internet
      "rust-analyzer-preview"
    ];
    targets = ["wasm32-unknown-emscripten"];
  });

in {
  home.packages = [
    my-rust
  ];
  programs = {
    vscode = {
      extensions = [
        (inputs.nixos-unstable.legacyPackages.x86_64-linux.vscode-extensions.matklad.rust-analyzer.override {
          rust-analyzer = my-rust;
        })
      ];
    };
  };
}
