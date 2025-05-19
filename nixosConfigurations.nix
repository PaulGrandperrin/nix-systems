inputs: let
  mkNixosConf = stability: modules: let
    selectFlake = stable: unstable: cosmic-stable: { inherit stable unstable cosmic-stable; }.${stability}; 
    #nixos-flake = selectFlake inputs.nixos-stable inputs.nixos-unstable inputs.nixos-cosmic-stable;
    nixos-flake = selectFlake inputs.nixos-stable inputs.nixos-unstable inputs.nixos-stable;
    home-manager-flake = selectFlake inputs.home-manager-stable inputs.home-manager-unstable inputs.home-manager-stable;
  in
    nixos-flake.lib.nixosSystem {
      specialArgs = { inherit inputs nixos-flake home-manager-flake;}; #  passes inputs and main flakes to modules
      inherit modules;
    };
in { 
  nixos-nas            = mkNixosConf "stable"        [ ./nixosModules/nixos-nas/configuration.nix                                         ];
  nixos-nas-lean       = mkNixosConf "stable"        [ ./nixosModules/nixos-nas/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-macmini        = mkNixosConf "stable"        [ ./nixosModules/nixos-macmini/configuration.nix                                     ];
  nixos-macmini-lean   = mkNixosConf "stable"        [ ./nixosModules/nixos-macmini/configuration.nix   ./nixosModules/shared/leanify.nix ];
  nixos-gcp            = mkNixosConf "stable"        [ ./nixosModules/nixos-gcp/configuration.nix                                         ];
  nixos-gcp-lean       = mkNixosConf "stable"        [ ./nixosModules/nixos-gcp/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-oci            = mkNixosConf "stable"        [ ./nixosModules/nixos-oci/configuration.nix                                         ];
  nixos-oci-lean       = mkNixosConf "stable"        [ ./nixosModules/nixos-oci/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-xps            = mkNixosConf "cosmic-stable" [ ./nixosModules/nixos-xps/configuration.nix                                         ];
  nixos-xps-lean       = mkNixosConf "cosmic-stable" [ ./nixosModules/nixos-xps/configuration.nix       ./nixosModules/shared/leanify.nix ];
  nixos-xps2           = mkNixosConf "unstable"      [ ./nixosModules/nixos-xps2/configuration.nix                                        ];
  nixos-xps2-lean      = mkNixosConf "unstable"      [ ./nixosModules/nixos-xps2/configuration.nix      ./nixosModules/shared/leanify.nix ];
  nixos-macbook        = mkNixosConf "stable"        [ ./nixosModules/nixos-macbook/configuration.nix                                     ];
  nixos-macbook-lean   = mkNixosConf "stable"        [ ./nixosModules/nixos-macbook/configuration.nix   ./nixosModules/shared/leanify.nix ];
  nixos-testvm         = mkNixosConf "stable"        [ ./nixosModules/nixos-testvm/configuration.nix                                      ];
  nixos-testvm-lean    = mkNixosConf "stable"        [ ./nixosModules/nixos-testvm/configuration.nix    ./nixosModules/shared/leanify.nix ];
  nixos-chromebox      = mkNixosConf "stable"        [ ./nixosModules/nixos-chromebox/configuration.nix                                   ];
  nixos-chromebox-lean = mkNixosConf "stable"        [ ./nixosModules/nixos-chromebox/configuration.nix ./nixosModules/shared/leanify.nix ];
  nixos-asus           = mkNixosConf "cosmic-stable" [ ./nixosModules/nixos-asus/configuration.nix                                        ];
  nixos-asus-lean      = mkNixosConf "cosmic-stable" [ ./nixosModules/nixos-asus/configuration.nix      ./nixosModules/shared/leanify.nix ];
}


