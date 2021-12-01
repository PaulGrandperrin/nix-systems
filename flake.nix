{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11"; # defined by default in the registry, overrides it

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  #specialArgs = { inherit inputs; }; # many people write that, no idea why

  outputs = inputs: {
    # Used with `nixos-rebuild --flake .#<hostname>`
    # nixosConfigurations."<hostname>".config.system.build.toplevel must be a derivation
    nixosConfigurations = { 
      nixos-nas = inputs.nixpkgs.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        # inherit specialArgs; # many people write that, no idea why
        system = "x86_64-linux"; # maybe related to legacyPackages?
        modules = [ 
          ./hosts/nas/configuration.nix
          ({ pkgs, ... }: { # pkgs is in fact inputs.nixpkgs I guess, somehow, but no idea how the magic is done
              nixpkgs.overlays = [ inputs.rust-overlay.overlay ];
          })
        ];
      };

      nixos-gcp = inputs.nixpkgs.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        # inherit specialArgs; # many people write that, no idea why
        system = "x86_64-linux"; # maybe related to legacyPackages?
        modules = [ 
          ./hosts/gcp/configuration.nix
          ({ pkgs, ... }: { # pkgs is in fact inputs.nixpkgs I guess, somehow, but no idea how the magic is done
              nixpkgs.overlays = [ inputs.rust-overlay.overlay ];
          })
        ];
      };

      nixos-xps = inputs.nixpkgs.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        # inherit specialArgs; # many people write that, no idea why
        system = "x86_64-linux"; # maybe related to legacyPackages?
        modules = [ 
          ./hosts/xps/configuration.nix
          ({ pkgs, ... }: { # pkgs is in fact inputs.nixpkgs I guess, somehow, but no idea how the magic is done
              nixpkgs.overlays = [ inputs.rust-overlay.overlay ];
          })
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.paulg = import ./users/paulg/home.nix;
          }
        ];
      };
    };
  };
}

