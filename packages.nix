inputs: let 
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in {
  x86_64-linux.vcv-rack = pkgs.callPackage ./packages/vcv-rack {};

  #x86_64-linux = {
  #  iso = inputs.nixos-generators.nixosGenerate {
  #    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  #    modules = [
  #      ./iso.nix
  #    ];
  #    format = "iso";
  #  };
  #};
}
