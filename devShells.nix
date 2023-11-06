inputs: let 
  lib = inputs.nixpkgs.lib;
in lib.genAttrs
  lib.systems.flakeExposed
  (system: {
    default = inputs.devenv.lib.mkShell {
      inherit inputs;
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = import ./nixpkgs/config.nix;
        overlays = [ (import ./overlays.nix inputs).default ];
      };

      modules = [({pkgs, config, ...}:{
        languages.nix.enable = true;
        packages = with pkgs; [
          devenv
          cargo
        ];
      })];
    };
  })
