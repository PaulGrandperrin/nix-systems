pkgs: {
  ksvim  =  pkgs.callPackage ./vim-distro { name = "ksvim";  conf-repo-url = "https://github.com/nvim-lua/kickstart.nvim.git"; };
  lzvim  =  pkgs.callPackage ./vim-distro { name = "lzvim";  conf-repo-url = "https://github.com/LazyVim/starter.git"; };
  nvchad =  pkgs.callPackage ./vim-distro { name = "nvchad"; conf-repo-url = "https://github.com/NvChad/NvChad.git"; };
  aovim  =  pkgs.callPackage ./vim-distro { name = "aovim";  conf-repo-url = "https://github.com/AstroNvim/AstroNvim.git"; };
  lnvim  =  pkgs.callPackage ./vim-distro { name = "lnvim";  conf-repo-url = "https://github.com/LunarVim/LunarVim.git"; };
  spvim  =  pkgs.callPackage ./vim-distro { name = "spvim";  conf-repo-url = "https://gitlab.com/SpaceVim/SpaceVim.git"; };
  vim-distro-format = pkgs.callPackage ./vim-distro/format.nix {};

  kernel-module-ath-patched = pkgs.callPackage ./kernel-module-ath-patched.nix {};

  firefox-bin = pkgs.callPackage ./firefox-bin {};

  #iso = inputs.nixos-generators.nixosGenerate {
  #  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  #  modules = [
  #    ./iso.nix
  #  ];
  #  format = "iso";
  #};
}
