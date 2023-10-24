 {

  description= "Paul Grandperrin Nix confs";

  nixConfig = {
    extra-substituters = [
      "http://nixos-nas.wg:5000"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nas.paulg.fr:QwhwNrClkzxCvdA0z3idUyl76Lmho6JTJLWplKtC2ig="
    ];
  };

  inputs = {

    flake-schemas.url = "github:DeterminateSystems/flake-schemas";

    nixpkgs = {
      type = "indirect"; # take it from the registry
      id   = "nixpkgs";
    };

    nixos-23-05.url           = "github:NixOS/nixpkgs/nixos-23.05";
    nixos-23-05-lib.url       = "github:NixOS/nixpkgs/nixos-23.05?dir=lib"; # "github:nix-community/nixpkgs.lib" doesn't work
    nixos-23-05-small.url     = "github:NixOS/nixpkgs/nixos-23.05-small";
    darwin-23-05.url          = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";
    darwin-unstable.url       = "github:NixOS/nixpkgs/nixpkgs-unstable"; # darwin-unstable for now (https://github.com/NixOS/nixpkgs/issues/107466)
    nixos-unstable.url        = "github:NixOS/nixpkgs/nixos-unstable";
    #nixos-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    #master.url               = "github:NixOS/nixpkgs/master";

    nur.url = "github:nix-community/NUR";

    nix-on-droid = {
      url = "github:t184256/nix-on-droid/testing";
      inputs = {
        nixpkgs.follows = "nixos-23-05-lib";
        home-manager.follows = "home-manager-23-05"; # TODO try to remove
      };
    };

    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixos-23-05-lib";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixos-23-05-lib";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixos-23-05-lib";
        flake-utils.follows = "flake-utils";
      };
    };

    home-manager-23-05 = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixos-23-05-lib"; # not needed by NixOS' module thanks to `home-manager.useGlobalPkgs = true` but needed by the unpriviledged module
    };
    home-manager-master = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixos-23-05-lib"; # not needed by NixOS' module thanks to `home-manager.useGlobalPkgs = true` but needed by the unpriviledged module
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs = {
        nixpkgs.follows = "nixos-23-05-lib";
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        nix-index-database.follows = "nix-index-database";
      };
    };

    nixgl = {
      url = "github:guibou/nixGL";
      flake = false; # TODO it's now a flake!
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs  = {
        nixpkgs.follows = ""; # optional, not necessary for the module
        nixpkgs-stable.follows = ""; # optional, not necessary for the module
      };
    };

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixos-23-05-lib";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
        nixpkgs-stable.follows = "nixos-23-05-lib";
      };  
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixos-unstable"; # NOTE doesn't only use the lib
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixos-unstable"; # NOTE doesn't only use the lib
    };

    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs = {
        nixpkgs.follows = "nixos-unstable"; # NOTE doesn't only use the lib
        home-manager.follows = "home-manager-23-05";
        flake-parts.follows = "flake-parts";
        devshell.follows = "devshell";
        hyprland.follows = ""; # we don't use it
        naersk.follows = "naersk";
      };
    };

    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixos-23-05-lib";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixos-23-05-lib";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";

      inputs = {
        nixpkgs.follows = "nixos-unstable"; # NOTE doesn't only use the lib
        flake-utils.follows = "flake-utils";
        rust-overlay.follows = "rust-overlay";
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
        pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
      };
    };

    nix = {
      url = "github:NixOS/nix";

      inputs = {
        nixpkgs.follows = "nixos-unstable";
        flake-compat.follows = "flake-compat";
      };
    };
    
    dwarffs = {
      url = "github:edolstra/dwarffs";
      inputs = {
        nixpkgs.follows = "nixos-unstable";
        nix.follows = "nix";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "";
    };

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixos-unstable";
      inputs.flake-utils.follows = "flake-utils";
      inputs.devshell.follows = "devshell";
    };
  };

  outputs = inputs: {
    inherit inputs; # useful to debug and inspect

    schemas                  = import ./schemas.nix                  inputs; # not merged yet: https://github.com/NixOS/nix/pull/8892
    devshells                = import ./devShells.nix                inputs;
    overlays                 = import ./overlays.nix                 inputs; # overlays.default is the sum of all the overlays
    legacyPackages           = import ./legacyPackages.nix           inputs; # applies overlays.default to nixpkgs.legacyPackages
    packages                 = import ./packages.nix                 inputs; # custom packages built against nixpkgs
    nixOnDroidConfigurations = import ./nixOnDroidConfigurations.nix inputs; # nix-on-droid switch --flake github:PaulGrandperrin/nix-systems
    darwinConfigurations     = import ./darwinConfigurations.nix     inputs;
    nixosConfigurations      = import ./nixosConfigurations.nix      inputs;
    homeConfigurations       = import ./homeConfigurations.nix       inputs;     
  };
}

