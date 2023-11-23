inputs: let 
  lib = inputs.nixos-stable.lib;
in lib.genAttrs
  lib.systems.flakeExposed
  (system:
    let 
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = import ./nixpkgs/config.nix;
        overlays = [ (import ./overlays.nix inputs).default ];
      };
    in
      (import ./packages pkgs)
)
