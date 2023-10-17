 {

  description= "Paul Grandperrin NixOS confs";

  nixConfig = { # NOTE: sync with nixos/common.nix
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
    nixos-23-05.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixos-23-05-lib.url = "github:NixOS/nixpkgs/nixos-23.05?dir=lib"; # "github:nix-community/nixpkgs.lib" doesn't work
    nixos-23-05-small.url = "github:NixOS/nixpkgs/nixos-23.05-small";
    darwin-23-05.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";
    darwin-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # darwin-unstable for now (https://github.com/NixOS/nixpkgs/issues/107466)
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    #nixos-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    #master.url = "github:NixOS/nixpkgs/master";

    nur.url = "github:nix-community/NUR";

    nix-on-droid = {
      url = "github:t184256/nix-on-droid/testing";
      inputs.nixpkgs.follows = "nixos-23-05-lib";
      inputs.home-manager.follows = "home-manager-23-05"; # TODO try to remove
    };

    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixos-23-05-lib";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixos-23-05-lib";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixos-23-05-lib";
      inputs.flake-utils.follows = "flake-utils";
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
      inputs.nixpkgs.follows = "nixos-23-05-lib";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nix-index-database.follows = "nix-index-database";
    };

    nixgl = {
      url = "github:guibou/nixGL";
      flake = false; # TODO it's now a flake!
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = ""; # optional, not necessary for the module
      inputs.nixpkgs-stable.follows = ""; # optional, not necessary for the module
    };

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixos-23-05-lib";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
      inputs.nixpkgs-stable.follows = "nixos-23-05-lib";
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
      inputs.nixpkgs.follows = "nixos-unstable"; # NOTE doesn't only use the lib
      inputs.home-manager.follows = "home-manager-23-05";
      inputs.flake-parts.follows = "flake-parts";
      inputs.devshell.follows = "devshell";
      inputs.hyprland.follows = ""; # we don't use it
      inputs.naersk.follows = "naersk";
    };

    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixos-23-05-lib";
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

      inputs.nixpkgs.follows = "nixos-unstable"; # NOTE doesn't only use the lib
      inputs.flake-utils.follows = "flake-utils";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-parts.follows = "flake-parts";
      inputs.pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
    };
  };


  outputs = inputs: {
    packages.x86_64-linux.vcv-rack = inputs.nixos-23-05.legacyPackages.x86_64-linux.callPackage ./pkgs/vcv-rack {};

    #packages.x86_64-linux = {
    #  iso = inputs.nixos-generators.nixosGenerate {
    #    pkgs = inputs.nixos-23-05.legacyPackages.x86_64-linux;
    #    modules = [
    #      ./iso.nix
    #    ];
    #    format = "iso";
    #  };
    #};

    #devShell.x86_64-linux = stable-pkgs.mkShell {
    #    buildInputs = with stable-pkgs; [
    #      cowsay
    #      fish
    #    ];

    #    shellHook = ''
    #      cowsay "Welcome"
    #    '';
    #  }
    #;

    nixOnDroidConfigurations = let 
      stability = "stable";
      system = "aarch64-linux";

      selectFlake = stable: unstable: { inherit stable unstable; }.${stability}; 
      nixos-flake = selectFlake inputs.nixos-23-05 inputs.nixos-unstable;
      home-manager-flake = selectFlake inputs.home-manager-23-05 inputs.home-manager-master;
    in {
      default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = nixos-flake.legacyPackages.${system}; # set overlays here?
        extraSpecialArgs = { inherit inputs nixos-flake home-manager-flake;}; # passes inputs and main flakes to modules
        home-manager-path = home-manager-flake.outPath; # remove outPath?
        modules = [
          ({pkgs, ...}: {
            system.stateVersion = "23.05";
            user.shell = "${pkgs.fish}/bin/fish";
            home-manager = {
              useGlobalPkgs = true;
              config = {config, lib, ...}: {
                imports = [
                  ./homeModules/shared/core.nix
                ];

                nixpkgs = {
                  overlays = import ./overlays inputs;
                  config.allowUnfree = true;
                };

                home.activation = {
                  copyFont = let 
                      font_src = "${pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; }}/share/fonts/truetype/NerdFonts/Fira Code Regular Nerd Font Complete Mono.ttf";
                      font_dst = "${config.home.homeDirectory}/.termux/font.ttf";
                    in lib.hm.dag.entryAfter ["writeBoundary"] ''
                      ( test ! -e "${font_dst}" || test $(sha1sum "${font_src}"|cut -d' ' -f1 ) != $(sha1sum "${font_dst}" |cut -d' ' -f1)) && $DRY_RUN_CMD install $VERBOSE_ARG -D "${font_src}" "${font_dst}"
                  '';
                };
                home.packages = [
                  (pkgs.writeShellScriptBin "start_sshd" ''${pkgs.openssh}/bin/sshd -f ${config.home.homeDirectory}/sshd/sshd_config'')
                ];
              };
            };
          })
        ];
      };
      #pixel7pro = inputs.nix-on-droid.lib.nixOnDroidConfiguration rec {
      #  system = "aarch64-linux";
      #  config = {pkgs, ...}: {
      #    user.shell = "${pkgs.fish}/bin/fish";
      #    nix.package = pkgs.nixFlakes;
      #    home-manager = {
      #      extraSpecialArgs = {inherit inputs;};
      #      config = {pkgs, lib, config, ...}: {
      #        imports = [./homeModules/shared/core.nix];
      #        nixpkgs.overlays = import ./overlays inputs;
      #        home.activation = {
      #          copyFont = let 
      #              font_src = "${pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; }}/share/fonts/truetype/NerdFonts/Fira Code Regular Nerd Font Complete Mono.ttf";
      #              font_dst = "${config.home.homeDirectory}/.termux/font.ttf";
      #            in lib.hm.dag.entryAfter ["writeBoundary"] ''
      #              ( test ! -e "${font_dst}" || test $(sha1sum "${font_src}"|cut -d' ' -f1 ) != $(sha1sum "${font_dst}" |cut -d' ' -f1)) && $DRY_RUN_CMD install $VERBOSE_ARG -D "${font_src}" "${font_dst}"
      #          '';
      #        };
      #        home.packages = [
      #          (pkgs.writeShellScriptBin "start_sshd" ''${pkgs.openssh}/bin/sshd -f ${config.home.homeDirectory}/sshd/sshd_config'')
      #        ];
      #      };
      #    };
      #  };
      #  extraModules = [];
      #};
    };

    homeConfigurations   = import ./homeConfigurations.nix   inputs;
    darwinConfigurations = import ./darwinConfigurations.nix inputs;
    nixosConfigurations  = import ./nixosConfigurations.nix  inputs;
  };
}

