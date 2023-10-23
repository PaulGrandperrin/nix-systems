inputs: let 
  lib = inputs.nixos-23-05-lib.lib;
in lib.genAttrs
      lib.systems.flakeExposed
      (system:
        let 
          pkgs = import inputs.nixpkgs {
            inherit system;
            config = import ./nixpkgs/config.nix;
          };
        in
          (import ./packages pkgs)
)
