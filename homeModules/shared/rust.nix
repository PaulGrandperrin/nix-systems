{pkgs, inputs, lib, ...}: let 

  ## Stable

  my-rust = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "rust-src" # needed by rust-analyzer vscode extension when installed through internet
      "rust-analyzer" 
    ];
    targets = ["wasm32-unknown-emscripten"];
  };

  #my-rust-analyzer = (pkgs.symlinkJoin {
  #  name = "rust-analyzer";
  #  paths = [ inputs.nixos-23-05.legacyPackages.${pkgs.stdenv.hostPlatform.system}.rust-analyzer ];
  #  buildInputs = [ pkgs.makeWrapper ];
  #  postBuild = ''
  #    wrapProgram $out/bin/rust-analyzer \
  #      --set-default "RUST_SRC_PATH" "${my-rust}"
  #  '';
  #}) ;

  ## Nightly

  #my-rust = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
  #  extensions = [
  #    "rust-src" # needed by rust-analyzer vscode extension when installed through internet
  #    "rust-analyzer-preview"
  #  ];
  #  targets = ["wasm32-unknown-emscripten"];
  #});

  #my-rust = pkgs.rust-bin.nightly."2022-09-28".default.override {
  #  extensions = [
  #    "rust-src" # needed by rust-analyzer vscode extension when installed through internet
  #    "rust-analyzer"
  #  ];
  #  targets = ["wasm32-unknown-emscripten"];
  #};
  
in {
  home = {
    packages = with pkgs; [
    my-rust
    #my-rust-analyzer
    ];

    file.".cargo/config.toml" = lib.mkIf pkgs.stdenv.isLinux {
      text = ''
        [target.x86_64-unknown-linux-gnu]
        linker = "${pkgs.clang_13}/bin/clang"
        rustflags = ["-C", "link-arg=--ld-path=${pkgs.mold}/bin/mold"]
      '';
    };
  };

  #programs = {
  #  vscode = {
  #    extensions = [
  #      (inputs.nixos-23-05.legacyPackages.${pkgs.stdenv.hostPlatform.system}.vscode-extensions.matklad.rust-analyzer.override {
  #        rust-analyzer = my-rust;
  #      })
  #    ];
  #  };
  #};
}
