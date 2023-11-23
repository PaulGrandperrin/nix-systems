inputs: let
  lib = inputs.nixos-stable.lib;
in lib.genAttrs 
  lib.systems.flakeExposed
  (system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [ (import ./overlays.nix inputs).default ];
      config = import ./nixpkgs/config.nix;
    }
  )

