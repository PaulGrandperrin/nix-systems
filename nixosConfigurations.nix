inputs: getOverlays: let
  mkNixosConf = stability: nixos-modules: hm-modules: let
    selectFlake = stable: unstable: { inherit stable unstable; }.${stability}; 
    nixos-flake = selectFlake inputs.nixos-23-05 inputs.nixos-unstable;
    home-manager-flake = selectFlake inputs.home-manager-23-05 inputs.home-manager-master;
  in
  nixos-flake.lib.nixosSystem rec {
    specialArgs = { inherit inputs nixos-flake home-manager-flake;}; #  passes inputs to modules
    modules = [ 
      { nixpkgs = {
          overlays = getOverlays;
        };
      }
      home-manager-flake.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true; # means that pkgs are taken from the nixosSystem and not from home-manager.inputs.nixpkgs
        home-manager.useUserPackages = true; # means that pkgs are installed at /etc/profiles instead of $HOME/.nix-profile
        home-manager.extraSpecialArgs = {inherit inputs;};
        home-manager.users.root  = { imports = hm-modules;};
        home-manager.users.paulg = { imports = hm-modules;};
      }
      inputs.sops-nix.nixosModules.sops
    ] ++ nixos-modules;
  };
in { 
  nixos-nas = mkNixosConf "stable" [
    ./nixosModules/nixos-nas/configuration.nix
  ]
  [
    ./hmModules/nixos-nas.nix
  ];

  nixos-macmini = mkNixosConf "stable" [
    ./nixosModules/nixos-macmini/configuration.nix
  ]
  [
    ./hmModules/nixos-macmini.nix
  ];

  nixos-gcp = mkNixosConf "stable" [
    ./nixosModules/nixos-gcp/configuration.nix
  ]
  [
    ./hmModules/nixos-gcp.nix
  ];

  nixos-oci = mkNixosConf "stable" [
    ./nixosModules/nixos-oci/configuration.nix
  ]
  [
    ./hmModules/nixos-oci.nix
  ];

  nixos-xps = mkNixosConf "unstable" [
    ./nixosModules/nixos-xps/configuration.nix
  ]
  [
    ./hmModules/nixos-xps.nix
  ];

  nixos-macbook = mkNixosConf "unstable" [
    ./nixosModules/nixos-macbook/configuration.nix
  ]
  [
    ./hmModules/nixos-macbook.nix
  ];

}


