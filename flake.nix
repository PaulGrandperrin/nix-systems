{

  description = "Paul Grandperrin NixOS confs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11"; # defined by default in the registry, overrides it
    nixos.url = "github:NixOS/nixpkgs/nixos-21.11";


    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    nur.url = "github:nix-community/NUR";

    nix-on-droid = {
      url = "github:t184256/nix-on-droid";
      inputs.nixpkgs.follows = "nixos";
      inputs.flake-utils.follows = "flake-utils";
      inputs.home-manager.follows = "home-manager";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixos";
    };

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

    devShell.x86_64-linux = let pkgs = inputs.nixos.legacyPackages.x86_64-linux; in 
      pkgs.mkShell {
        buildInputs = with pkgs; [
          cowsay
          fish
        ];

        shellHook = ''
          cowsay "Welcome"
        '';
      }
    ;

    nixOnDroidConfigurations = {
      pixel6pro = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        system = "aarch64-linux";
        config = {
          home-manager.config = import ./home-manager/cmdline.nix;
	};
        extraModules = [];
      };
    };

    homeConfigurations = let
      system = "x86_64-linux";
    in {
      paulg = inputs.home-manager.lib.homeManagerConfiguration {
        inherit system;
        stateVersion = "21.11";
        homeDirectory = "/home/paulg";
        username = "paulg";
        extraSpecialArgs = {inherit system inputs; installDesktopApp = false;};
        configuration = { config, pkgs, lib, ... }: {
          imports = [ ./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix];
          nixpkgs.overlays = [ inputs.nur.overlay inputs.rust-overlay.overlay ];
          nixpkgs.config.allowUnfree = true;
          home.packages = [
            (pkgs.writeShellScriptBin "nixGLNvidia" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A auto.nixGLNvidia --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixGLIntel" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A nixGLIntel --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixVulkanIntel" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A nixVulkanIntel --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixVulkanNvidia" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A auto.nixVulkanNvidia --no-out-link)/bin/* "$@"'')
          ];
        };  
      };
    };

    darwinConfigurations = let
      system = "x86_64-darwin";
    in {
      "MacBookPaul" = inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [
          { 
            nixpkgs.overlays = [ inputs.nur.overlay inputs.rust-overlay.overlay ];
            nixpkgs.config.allowUnfree = true;
          }
          ./nix-darwin/common.nix
          ./nix-darwin/hosts/MacBookPaul.nix
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = false;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix ./home-manager/rust-stable.nix];};
          }
        ];
      };

      "MacMiniPaul" = inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [
          { 
            nixpkgs.overlays = [ inputs.nur.overlay inputs.rust-overlay.overlay ];
            nixpkgs.config.allowUnfree = true;
          }
          ./nix-darwin/common.nix
          ./nix-darwin/hosts/MacMiniPaul.nix
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = false;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix];};
          }
        ];
      };
    };

    # Used with `nixos-rebuild --flake .#<hostname>`
    # nixosConfigurations."<hostname>".config.system.build.toplevel must be a derivation
    nixosConfigurations = let
        system = "x86_64-linux";
    in { 
      nixos-nas = inputs.nixos.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs.overlays = [ inputs.nur.overlay inputs.rust-overlay.overlay ]; }
          ./nixos/hosts/nas/configuration.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = false;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix];};
          }
        ];
      };

      nixos-gcp = inputs.nixos.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs.overlays = [ inputs.nur.overlay inputs.rust-overlay.overlay ]; }
          ./nixos/hosts/gcp/configuration.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = false;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix];};
          }
        ];
      };

      nixos-xps = inputs.nixos.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs.overlays = [ inputs.nur.overlay inputs.rust-overlay.overlay ]; }
          ./nixos/hosts/xps/configuration.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = true;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix ./home-manager/desktop-linux.nix ./home-manager/rust-nightly.nix];};
          }
        ];
      };
    };
  };
}

