inputs: let 
  lib = inputs.nixpkgs.lib;
in lib.genAttrs
  lib.systems.flakeExposed
  (system: let 
    pkgs = import inputs.nixpkgs {
      inherit system;
      config = import ./nixpkgs/config.nix;
      overlays = [ (import ./overlays.nix inputs).default ];
    };
  in {
    default = inputs.devenv.lib.mkShell {
      inherit inputs pkgs;
      modules = [
        ./devenvModules/default.nix
      ];
    };
    flutter = inputs.devenv.lib.mkShell {
      inherit inputs pkgs;
      modules = [
        ./devenvModules/flutter.nix
      ];
    };
  })
