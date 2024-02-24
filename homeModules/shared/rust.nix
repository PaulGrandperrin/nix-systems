{pkgs, inputs, lib, ...}: let 
in {
  home = {
    packages = with pkgs; [
    my-rust-stable
    tokio-console
    #my-rust-analyzer
    ];

    file.".cargo/config.toml" = lib.mkIf pkgs.stdenv.isLinux {
      text = ''
        [build]
        rustflags = ["-C", "link-arg=--ld-path=${pkgs.mold}/bin/mold"]
        [target.x86_64-unknown-linux-gnu]
        linker = "${pkgs.clang_17}/bin/clang"
      '';
    };
  };

  #programs = {
  #  vscode = {
  #    extensions = [
  #      (inputs.nixos-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.vscode-extensions.matklad.rust-analyzer.override {
  #        rust-analyzer = my-rust;
  #      })
  #    ];
  #  };
  #};
}
