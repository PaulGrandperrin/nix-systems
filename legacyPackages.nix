inputs: let
  lib = inputs.nixos-23-05-lib.lib;
in lib.listToAttrs (
  map
    (system: {
      name = system;
      value = inputs.nixpkgs.legacyPackages.${system}.extend (import ./overlays.nix inputs).default;
    })
    lib.systems.flakeExposed
)
