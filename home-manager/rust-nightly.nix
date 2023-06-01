{pkgs, system, inputs, ...}: let 

  #my-rust = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
  #  extensions = [
  #    "rust-src" # needed by rust-analyzer vscode extension when installed through internet
  #    "rust-analyzer-preview"
  #  ];
  #  targets = ["wasm32-unknown-emscripten"];
  #});

  my-rust = pkgs.rust-bin.nightly."2022-09-28".default.override {
    extensions = [
      "rust-src" # needed by rust-analyzer vscode extension when installed through internet
      "rust-analyzer"
    ];
    targets = ["wasm32-unknown-emscripten"];
  };

in {
  home.packages = with pkgs; [
    my-rust
  ];
  #programs = {
  #  vscode = {
  #    extensions = [
  #      (inputs.nixos-23-05.legacyPackages.${system}.vscode-extensions.matklad.rust-analyzer.override {
  #        rust-analyzer = my-rust;
  #      })
  #    ];
  #  };
  #};
}
