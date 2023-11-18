inputs: let
  mkNixosConf = stability: modules: let
    selectFlake = stable: unstable: { inherit stable unstable; }.${stability}; 
    nixos-flake = selectFlake inputs.nixos-23-05 inputs.nixos-unstable;
    home-manager-flake = selectFlake inputs.home-manager-23-05 inputs.home-manager-master;
  in
    nixos-flake.lib.nixosSystem {
      specialArgs = { inherit inputs nixos-flake home-manager-flake;}; #  passes inputs and main flakes to modules
      inherit modules;
    };
in { 
  nixos-nas            = mkNixosConf "stable"   [ ./nixosModules/nixos-nas/configuration.nix                                         ];
  nixos-nas-lean       = mkNixosConf "stable"   [ ./nixosModules/nixos-nas/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-macmini        = mkNixosConf "unstable" [ ./nixosModules/nixos-macmini/configuration.nix                                     ];
  nixos-macmini-lean   = mkNixosConf "unstable" [ ./nixosModules/nixos-macmini/configuration.nix   ./nixosModules/shared/leanify.nix ];
  nixos-gcp            = mkNixosConf "stable"   [ ./nixosModules/nixos-gcp/configuration.nix                                         ];
  nixos-gcp-lean       = mkNixosConf "stable"   [ ./nixosModules/nixos-gcp/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-oci            = mkNixosConf "stable"   [ ./nixosModules/nixos-oci/configuration.nix                                         ];
  nixos-oci-lean       = mkNixosConf "stable"   [ ./nixosModules/nixos-oci/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-xps            = mkNixosConf "unstable" [ ./nixosModules/nixos-xps/configuration.nix                                         ];
  nixos-xps-lean       = mkNixosConf "unstable" [ ./nixosModules/nixos-xps/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-macbook        = mkNixosConf "unstable" [ ./nixosModules/nixos-macbook/configuration.nix                                     ];
  nixos-macbook-lean   = mkNixosConf "unstable" [ ./nixosModules/nixos-macbook/configuration.nix   ./nixosModules/shared/leanify.nix ];
  nixos-testvm         = mkNixosConf "unstable" [ ./nixosModules/nixos-testvm/configuration.nix                                      ];
  nixos-testvm-lean    = mkNixosConf "unstable" [ ./nixosModules/nixos-testvm/configuration.nix    ./nixosModules/shared/leanify.nix ];
  nixos-chromebox      = mkNixosConf "unstable" [ ./nixosModules/nixos-chromebox/configuration.nix                                   ];
  nixos-chromebox-lean = mkNixosConf "unstable" [ ./nixosModules/nixos-chromebox/configuration.nix ./nixosModules/shared/leanify.nix ];
}


