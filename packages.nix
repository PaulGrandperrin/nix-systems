inputs: let 
  lib = inputs.nixos-23-05-lib.lib;
in {
  x86_64-linux = let 
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config = import ./nixpkgs/config.nix;
    };
  in
    (import ./packages pkgs);
}
