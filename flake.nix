 {

  description= "Paul Grandperrin Nix confs";

  nixConfig = {
    extra-substituters = [
      "http://nixos-nas.wg:5000"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
      "https://nix-amd-ai.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nas.grandperrin.fr:QwhwNrClkzxCvdA0z3idUyl76Lmho6JTJLWplKtC2ig="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-amd-ai.cachix.org-1:F4OU4vw/lV2oiG6SBHZ+nqjl4EFJuqI4X9A7pvaBmhQ="
    ];
  };

  inputs = {

    flake-schemas.url = "github:DeterminateSystems/flake-schemas";

    nixpkgs = {
      type = "indirect"; # take it from the registry
      id   = "nixpkgs";
    };

    nixos-stable.url           = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-stable-lib.url       = "github:NixOS/nixpkgs/nixos-26.05?dir=lib"; # "github:nix-community/nixpkgs.lib" doesn't work
    #nixos-stable-small.url     = "github:NixOS/nixpkgs/nixos-26.05-small";
    #darwin-stable.url          = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    #darwin-unstable.url        = "github:NixOS/nixpkgs/nixpkgs-unstable"; # darwin-unstable for now (https://github.com/NixOS/nixpkgs/issues/107466)
    nixos-unstable.url         = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-unstable-lib.url     = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";
    #nixos-unstable-small.url   = "github:NixOS/nixpkgs/nixos-unstable-small";
    #master.url                 = "github:NixOS/nixpkgs/master";

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixos-stable-lib"; # not needed by NixOS' module thanks to `home-manager.useGlobalPkgs = true` but needed by the unpriviledged module
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixos-unstable-lib"; # not needed by NixOS' module thanks to `home-manager.useGlobalPkgs = true` but needed by the unpriviledged module
    };

    ### NOTE alphabetical order from here

    #amadou_server = {
    #  url = "git+ssh://git@github.com/PaulGrandperrin/amadou_server.git?rev=25a3db8d3868bda51c462377361b6ff58a18739c";
    #  inputs = {
    #    nixpkgs.follows = "nixos-stable";
    #  };
    #};

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs/stable";
      inputs = {
        nixpkgs.follows = "nixos-stable";
        devshell.follows = "devshell";
        flake-utils.follows = "flake-utils";
      };
    };

    bugstalker = {
      url = "github:godzie44/BugStalker";
      inputs = {
        nixpkgs.follows = "nixos-stable";
        rust-overlay.follows = "rust-overlay";
        flake-parts.follows = "flake-parts";
      };
    };

    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs = {
        home-manager.follows = "home-manager-stable"; # TODO try to remove
        flake-schemas.follows = "flake-schemas";
        rust-overlay.follows = "rust-overlay";
      };
    };

    crane = { # eventually, use dream2nix when it's more stable
      url = "github:ipetkov/crane";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs = {
        #nixpkgs.follows = "nixpkgs"; # don't override so that the cache can be used
        flake-compat.follows = "flake-compat";
        #nix.follows = "nix"; # don't override so that the cache can be used
        git-hooks.follows = "git-hooks";
      };
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixos-stable-lib";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "";
    };
    
    dwarffs = {
      url = "github:edolstra/dwarffs";
      inputs = {
        nixpkgs.follows = "nixos-stable";
        nix.follows = "nix";
      };
    };

    firefox-nightly = {
      url = "github:nix-community/flake-firefox-nightly";
      inputs = {
        nixpkgs.follows = "";
      };
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixos-stable-lib";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixos-stable-lib";
        flake-compat.follows = "flake-compat";
      };  
    };

    isd = {
      url = "github:isd-project/isd";
      inputs = {
        nixpkgs.follows = "nixos-stable";
      };
    };

    isd-unstable = {
      url = "github:isd-project/isd";
      inputs = {
        nixpkgs.follows = "nixos-unstable";
      };
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";

      inputs = {
        nixpkgs.follows = "nixos-stable"; # NOTE doesn't only use the lib
        rust-overlay.follows = "rust-overlay";
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
        pre-commit-hooks-nix.follows = "git-hooks";
        crane.follows = "crane";
      };
    };

    #lix = { # too long to build
    #  url = "git+https://git.lix.systems/lix-project/lix.git";
    #  inputs = {
    #    nixpkgs.follows = "nixos-stable";
    #    git-hooks.follows = "git-hooks";
    #    flake-compat.follows = "flake-compat";
    #  };
    #};

    #nar-alike-deduper = {
    #  #url = "github:PaulGrandperrin/nar-alike-deduper";
    #  url = "/home/paulg/Repos/nar-alike-deduper/";
    #  inputs = {
    #    nixpkgs.follows = "nixos-stable";
    #    devenv.follows = "devenv";
    #    rust-overlay.follows = "rust-overlay";
    #    crane.follows = "crane";
    #  };
    #};

    nix = {
      url = "github:NixOS/nix";

      inputs = {
        nixpkgs.follows = "nixos-stable";
        flake-compat.follows = "flake-compat";
      };
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs = {
        nixpkgs.follows = "nixos-stable-lib";
        flake-compat.follows = "flake-compat";
        nix-index-database.follows = "nix-index-database";
      };
    };

    nix-amd-ai = {
      url = "github:noamsto/nix-amd-ai";
      # NOTE: don't override inputs in order to use the cache 
    };

    #nix-cluster = {
    #  url = "git+ssh://git@github.com/PaulGrandperrin/nix-cluster.git";
    #  inputs = {
    #    nixpkgs.follows = "nixos-stable";
    #  };
    #};

    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixos-stable-lib";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixos-stable"; # NOTE doesn't only use the lib
    };

    nix-inspect = {
      url = "github:bluskript/nix-inspect";
      inputs = {
        #nixpkgs.follows = "nixos-stable";
        #flake-parts.follows = "flake-parts";
      };
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      #url = "github:nix-community/nix-on-droid/release-25.11";
      inputs = {
        nixpkgs.follows = "nixos-stable-lib";
        home-manager.follows = "home-manager-stable"; # TODO try to remove
      };
    };

    #nixgl = {
    #  url = "github:guibou/nixGL";
    #  flake = false; # TODO it's now a flake!
    #};

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixos-stable"; # NOTE doesn't only use the lib
    };

    nixpkgs-update = {
      url = "github:ryantm/nixpkgs-update";
      inputs = {
        # nixpkgs.follows = "nixos-stable"; # don't override so that we can use the cache
      };
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs = {
        nixpkgs.follows = "nixos-stable";
        flake-parts.follows = "flake-parts";
      };
    };

    nur.url = "github:nix-community/NUR";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixos-stable";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs  = {
        nixpkgs.follows = ""; # optional, not necessary for the module
      };
    };

    srvos = {
      url = "github:nix-community/srvos";
      inputs = {
        nixpkgs.follows = "nixos-stable-lib";
      };
    };

    system-manager = {
      url = "github:numtide/system-manager";
      inputs = {
        nixpkgs.follows = "nixos-stable";
      };
    };

    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs = {
        nixpkgs.follows = "nixos-stable"; # NOTE doesn't only use the lib
        flake-parts.follows = "flake-parts";
        crane.follows = "crane";
      };
    };
  };

  outputs = inputs: {
    inherit inputs; # useful to debug and inspect

    schemas                  = import ./schemas.nix                  inputs; # not merged yet: https://github.com/NixOS/nix/pull/8892
    devShells                = import ./devShells.nix                inputs;
    overlays                 = import ./overlays.nix                 inputs; # overlays.default is the sum of all the overlays
    legacyPackages           = import ./legacyPackages.nix           inputs; # applies overlays.default to nixpkgs.legacyPackages
    packages                 = import ./packages.nix                 inputs; # custom packages built against nixpkgs
    nixOnDroidConfigurations = import ./nixOnDroidConfigurations.nix inputs; # nix-on-droid switch --flake github:PaulGrandperrin/nix-systems
    darwinConfigurations     = import ./darwinConfigurations.nix     inputs;
    nixosConfigurations      = import ./nixosConfigurations.nix      inputs;
    homeConfigurations       = import ./homeConfigurations.nix       inputs;     
    systemConfigs            = import ./systemConfigs.nix            inputs;
  };
}

