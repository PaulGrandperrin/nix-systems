inputs: let 
  lib = inputs.nixos-23-05-lib.lib;
in {
  x86_64-linux = let 
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  in {
    vcv-rack = pkgs.callPackage ./packages/vcv-rack {};

    ksvim  =  pkgs.callPackage ./packages/vim-distro { name = "ksvim";  conf-repo-url = "https://github.com/nvim-lua/kickstart.nvim.git"; };
    lzvim  =  pkgs.callPackage ./packages/vim-distro { name = "lzvim";  conf-repo-url = "https://github.com/LazyVim/starter.git"; };
    nvchad =  pkgs.callPackage ./packages/vim-distro { name = "nvchad"; conf-repo-url = "https://github.com/NvChad/NvChad.git"; };
    aovim  =  pkgs.callPackage ./packages/vim-distro { name = "aovim";  conf-repo-url = "https://github.com/AstroNvim/AstroNvim.git"; };
    lnvim  =  pkgs.callPackage ./packages/vim-distro { name = "lnvim";  conf-repo-url = "https://github.com/LunarVim/LunarVim.git"; };
    spvim  =  pkgs.callPackage ./packages/vim-distro { name = "spvim";  conf-repo-url = "https://gitlab.com/SpaceVim/SpaceVim.git"; };
    vim-distro-format = pkgs.callPackage ./packages/vim-distro/format.nix {};

    #iso = inputs.nixos-generators.nixosGenerate {
    #  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    #  modules = [
    #    ./iso.nix
    #  ];
    #  format = "iso";
    #};
  };
}
