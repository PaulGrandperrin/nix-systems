inputs: let 
  lib = inputs.nixos-stable.lib;
  mkHomeConf = stability: system: username: module: let 
    selectFlake = stable: unstable: { inherit stable unstable; }.${stability};
    nixos-flake = selectFlake inputs.nixos-stable inputs.nixos-unstable;
    home-manager-flake = selectFlake inputs.home-manager-stable inputs.home-manager-unstable;
  in
    home-manager-flake.lib.homeManagerConfiguration {
      pkgs = nixos-flake.legacyPackages.${system};
      extraSpecialArgs = {inherit inputs nixos-flake home-manager-flake;};
      modules = [ 
        {
          home = {
            inherit username;
          };
        }
        module
      ];
    };
in 
  # Generate all combinations in the form:
  # {
  #   stable-x86_64-linux-root = mkHomeConf "stable" "x86_64-linux" "root" ./homeModules/standalone.nix;
  #   ...
  # }
  builtins.listToAttrs (
    map 
      ({stability, system, username, extra}: {
        name = "${stability}-${system}-${username}${lib.optionalString extra "-extra"}";
        value = mkHomeConf stability system username (if extra then ./homeModules/standalone-extra.nix else ./homeModules/standalone.nix);
      }) 
      (lib.cartesianProductOfSets {
        stability = ["stable" "unstable"];
        system    = lib.systems.flakeExposed;
        username  = ["root" "paulg"];
        extra     = [false true];
      })
  ) // {
    "root@debian"       = mkHomeConf "stable" "x86_86-linux"   "root"  ./homeModules/standalone.nix;     
    "paulg@debian"      = mkHomeConf "stable" "x86_86-linux"   "paulg" ./homeModules/standalone.nix;     
    "paulg@MacBookPhil" = mkHomeConf "stable" "aarch64-darwin" "paulg" ./homeModules/standalone-extra.nix;     
  }
  

