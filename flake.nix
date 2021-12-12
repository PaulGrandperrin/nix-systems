{

  description = "Paul Grandperrin NixOS confs";

  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-21.11"; # defined by default in the registry, overrides it
    #nixos.url = "/root/nixpkgs/"; # defined by default in the registry, overrides it
    #nixos = {
    #  type = "github";
    #  owner = "NixOS";
    #  repo = "nixpkgs";
    #  rev = "573095944e7c1d58d30fc679c81af63668b54056";
    #};

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixos";
      inputs.flake-utils.follows = "flake-utils";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixos";
    };

    nixgl = {
      url = "github:guibou/nixGL";
      flake = false;
    };
  };


  outputs = inputs: {

    homeConfigurations = { # TODO figure out how to pass inputs to modules
      paulg = inputs.home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        stateVersion = "21.11";
        homeDirectory = "/home/paulg";
        username = "paulg";
        configuration = { config, pkgs, lib, ... }: {
          imports = [ ./users/home.nix ./users/paulg/home.nix ./users/paulg/home-desktop.nix];
          home.packages = [
            (pkgs.writeShellScriptBin "nixGLNvidia" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A auto.nixGLNvidia --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixGLIntel" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A nixGLIntel --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixVulkanIntel" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A nixVulkanIntel --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixVulkanNvidia" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A auto.nixVulkanNvidia --no-out-link)/bin/* "$@"'')
          ];
        };  
      };
    };

    # Used with `nixos-rebuild --flake .#<hostname>`
    # nixosConfigurations."<hostname>".config.system.build.toplevel must be a derivation
    nixosConfigurations = { 
      nixos-nas = inputs.nixos.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        specialArgs = { inherit inputs; }; #  passes inputs to modules
        system = "x86_64-linux"; # maybe related to legacyPackages?
        modules = [ 
          ./hosts/nas/configuration.nix
          ({ pkgs, ... }: { # pkgs is in fact inputs.nixos I guess, somehow, but no idea how the magic is done
              nixpkgs.overlays = [ inputs.rust-overlay.overlay ];
          })
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.root  = { imports = [./users/home.nix ./users/root/home.nix];};
            home-manager.users.paulg = { imports = [./users/home.nix ./users/paulg/home.nix];};
          }
        ];
      };

      nixos-gcp = inputs.nixos.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        specialArgs = { inherit inputs; }; #  passes inputs to modules
        system = "x86_64-linux"; # maybe related to legacyPackages?
        modules = [ 
          ./hosts/gcp/configuration.nix
          ({ pkgs, ... }: { # pkgs is in fact inputs.nixos I guess, somehow, but no idea how the magic is done
              nixpkgs.overlays = [ inputs.rust-overlay.overlay ];
          })
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.root  = { imports = [./users/home.nix ./users/root/home.nix];};
            home-manager.users.paulg = { imports = [./users/home.nix ./users/paulg/home.nix];};
          }
        ];
      };

      nixos-xps = inputs.nixos.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        specialArgs = { inherit inputs; }; #  passes inputs to modules
        system = "x86_64-linux"; # maybe related to legacyPackages?
        modules = [ 
          ./hosts/xps/configuration.nix
          ({ pkgs, ... }: { # pkgs is in fact inputs.nixos I guess, somehow, but no idea how the magic is done
              nixpkgs.overlays = [ inputs.rust-overlay.overlay ];
          })
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.root  = { imports = [./users/home.nix ./users/root/home.nix];};
            home-manager.users.paulg = { imports = [./users/home.nix ./users/paulg/home.nix ./users/paulg/home-desktop.nix];};
          }
        ];
      };
    };
  };
}

