inputs: {
  x86_64-linux.vcv-rack = inputs.nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/vcv-rack {};

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
