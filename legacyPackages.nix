inputs: let
  lib = inputs.nixos-23-05-lib.lib;
in lib.genAttrs 
  lib.systems.flakeExposed
  (system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [ (import ./overlays.nix inputs).default ];
      config = import ./nixpkgs/config.nix;
    }
  )

