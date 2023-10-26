inputs: let
  mkNixosConf = stability: module: let
    selectFlake = stable: unstable: { inherit stable unstable; }.${stability}; 
    nixos-flake = selectFlake inputs.nixos-23-05 inputs.nixos-unstable;
    home-manager-flake = selectFlake inputs.home-manager-23-05 inputs.home-manager-master;
  in
    nixos-flake.lib.nixosSystem {
      specialArgs = { inherit inputs nixos-flake home-manager-flake;}; #  passes inputs and main flakes to modules
      modules = [
        module
      ];
    };
in { 
  nixos-nas     = mkNixosConf "stable"   ./nixosModules/nixos-nas/configuration.nix;
  nixos-macmini = mkNixosConf "stable"   ./nixosModules/nixos-macmini/configuration.nix;
  nixos-gcp     = mkNixosConf "stable"   ./nixosModules/nixos-gcp/configuration.nix;
  nixos-oci     = mkNixosConf "stable"   ./nixosModules/nixos-oci/configuration.nix;
  nixos-xps     = mkNixosConf "unstable" ./nixosModules/nixos-xps/configuration.nix;
  nixos-macbook = mkNixosConf "unstable" ./nixosModules/nixos-macbook/configuration.nix;
  nixos-testvm  = mkNixosConf "unstable" ./nixosModules/nixos-testvm/configuration.nix;
}


