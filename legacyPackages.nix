inputs: let
  lib = inputs.nixos-23-05-lib.lib;
in lib.listToAttrs (
  map
    (system: {
      name = system;
      value = (import inputs.nixpkgs {
        inherit system;
        overlays = [ (import ./overlays.nix inputs).default ];
        config.allowUnfree = true;
      });
    })
    lib.systems.flakeExposed
)