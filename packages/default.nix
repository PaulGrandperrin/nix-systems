{pkgs, inputs, ...}: rec {
  ksvim  =  pkgs.callPackage ./vim-distro { name = "ksvim";  conf-repo-url = "https://github.com/nvim-lua/kickstart.nvim.git"; };
  lzvim  =  pkgs.callPackage ./vim-distro { name = "lzvim";  conf-repo-url = "https://github.com/LazyVim/starter.git"; };
  nvchad =  pkgs.callPackage ./vim-distro { name = "nvchad"; conf-repo-url = "https://github.com/NvChad/NvChad.git"; };
  aovim  =  pkgs.callPackage ./vim-distro { name = "aovim";  conf-repo-url = "https://github.com/AstroNvim/AstroNvim.git"; };
  lnvim  =  pkgs.callPackage ./vim-distro { name = "lnvim";  conf-repo-url = "https://github.com/LunarVim/LunarVim.git"; };
  spvim  =  pkgs.callPackage ./vim-distro { name = "spvim";  conf-repo-url = "https://gitlab.com/SpaceVim/SpaceVim.git"; };
  vim-distro-format = pkgs.callPackage ./vim-distro/format.nix {};

  kernel-module-ath-patched = pkgs.callPackage ./kernel-module-ath-patched.nix {};

  firefox-bin = pkgs.callPackage ./firefox-bin {};

  nixvim = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
    pkgs = inputs.nixvim.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    module = ../nixvimModules;
    extraSpecialArgs = {
      inherit inputs;
    };
  };

  my-rust-stable = (inputs.rust-overlay.overlays.default pkgs pkgs).rust-bin.stable.latest.default.override {
    extensions = [
      "rust-src" # needed by rust-analyzer vscode extension when installed through internet
      "rust-analyzer" 
    ];
    targets = ["wasm32-unknown-emscripten"];
  };

  my-rust-analyzer = (pkgs.symlinkJoin {
    name = "rust-analyzer";
    paths = [ inputs.nixos-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.rust-analyzer ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/rust-analyzer \
        --set-default "RUST_SRC_PATH" "${my-rust-stable}"
    '';
  }) ;

  my-rust-mightly = (inputs.rust-overlay.overlays.default pkgs pkgs).rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
    extensions = [
      "rust-src" # needed by rust-analyzer vscode extension when installed through internet
      "rust-analyzer-preview"
    ];
    targets = ["wasm32-unknown-emscripten"];
  });

  my-rust-pinned = (inputs.rust-overlay.overlays.default pkgs pkgs).rust-bin.nightly."2022-09-28".default.override {
    extensions = [
      "rust-src" # needed by rust-analyzer vscode extension when installed through internet
      "rust-analyzer"
    ];
    targets = ["wasm32-unknown-emscripten"];
  };
  

  #iso = inputs.nixos-generators.nixosGenerate {
  #  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  #  modules = [
  #    ./iso.nix
  #  ];
  #  format = "iso";
  #};
}
