{pkgs, system, inputs, ...}: let 

  my-rust = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "rust-src" # needed by rust-analyzer vscode extension when installed through internet
      # "rust-analyzer-preview" is not available in stable yet 
    ];
    targets = ["wasm32-unknown-emscripten"];
  };

  my-rust-analyzer = (pkgs.symlinkJoin {
    name = "rust-analyzer";
    paths = [ inputs.nixos-22-05.legacyPackages.${system}.rust-analyzer ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/rust-analyzer \
        --set-default "RUST_SRC_PATH" "${my-rust}"
    '';
  }) ;
  
in {
  home.packages = with pkgs; [
    my-rust
  ];
  programs = {
    vscode = {
      extensions = [
        (inputs.nixos-22-05.legacyPackages.${system}.vscode-extensions.matklad.rust-analyzer.override {
          rust-analyzer = my-rust-analyzer;
        })
      ];
    };
  };
}
