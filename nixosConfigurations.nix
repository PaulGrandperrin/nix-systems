inputs: let
  mkNixosConf = stability: modules: let
    selectFlake = stable: unstable: { inherit stable unstable; }.${stability}; 
    nixos-flake = selectFlake inputs.nixos-stable inputs.nixos-unstable;
    home-manager-flake = selectFlake inputs.home-manager-stable inputs.home-manager-unstable;
  in
    nixos-flake.lib.nixosSystem {
      specialArgs = { inherit inputs nixos-flake home-manager-flake;}; #  passes inputs and main flakes to modules
      inherit modules;
    };
in { 
  nixos-nas            = mkNixosConf "unstable"   [ ./nixosModules/nixos-nas/configuration.nix                                         ];
  nixos-nas-lean       = mkNixosConf "unstable"   [ ./nixosModules/nixos-nas/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-macmini        = mkNixosConf "unstable"   [ ./nixosModules/nixos-macmini/configuration.nix                                     ];
  nixos-macmini-lean   = mkNixosConf "unstable"   [ ./nixosModules/nixos-macmini/configuration.nix   ./nixosModules/shared/leanify.nix ];
  nixos-gcp            = mkNixosConf "unstable"   [ ./nixosModules/nixos-gcp/configuration.nix                                         ];
  nixos-gcp-lean       = mkNixosConf "unstable"   [ ./nixosModules/nixos-gcp/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-oci            = mkNixosConf "unstable"   [ ./nixosModules/nixos-oci/configuration.nix                                         ];
  nixos-oci-lean       = mkNixosConf "unstable"   [ ./nixosModules/nixos-oci/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-xps            = mkNixosConf "unstable"   [ ./nixosModules/nixos-xps/configuration.nix                                         ];
  nixos-xps-lean       = mkNixosConf "unstable"   [ ./nixosModules/nixos-xps/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-xps2           = mkNixosConf "unstable" [ ./nixosModules/nixos-xps2/configuration.nix                                        ];
  nixos-xps2-lean      = mkNixosConf "unstable" [ ./nixosModules/nixos-xps2/configuration.nix      ./nixosModules/shared/leanify.nix ];
  nixos-macbook        = mkNixosConf "unstable"   [ ./nixosModules/nixos-macbook/configuration.nix                                     ];
  nixos-macbook-lean   = mkNixosConf "unstable"   [ ./nixosModules/nixos-macbook/configuration.nix   ./nixosModules/shared/leanify.nix ];
  nixos-testvm         = mkNixosConf "unstable"   [ ./nixosModules/nixos-testvm/configuration.nix                                      ];
  nixos-testvm-lean    = mkNixosConf "unstable"   [ ./nixosModules/nixos-testvm/configuration.nix    ./nixosModules/shared/leanify.nix ];
  nixos-chromebox      = mkNixosConf "unstable"   [ ./nixosModules/nixos-chromebox/configuration.nix                                   ];
  nixos-chromebox-lean = mkNixosConf "unstable"   [ ./nixosModules/nixos-chromebox/configuration.nix ./nixosModules/shared/leanify.nix ];
  nixos-asus           = mkNixosConf "unstable"   [ ./nixosModules/nixos-asus/configuration.nix                                        ];
  nixos-asus-lean      = mkNixosConf "unstable"   [ ./nixosModules/nixos-asus/configuration.nix      ./nixosModules/shared/leanify.nix ];
}


