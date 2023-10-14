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

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = ""; # optional, not necessary for the module
      inputs.stable.follows = ""; # optional, not necessary for the module
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
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


  outputs = inputs: let 
    getOverlays = system: let # FIXME not sure those are the good channels for darwin
      pkgs-stable = inputs.nixos-23-05.legacyPackages.${system};
      pkgs-unstable = inputs.nixos-unstable.legacyPackages.${system};
      all-pkgs-overlay = final: prev: { unstable = pkgs-unstable; stable = pkgs-stable;};
    in [
      all-pkgs-overlay
      inputs.nur.overlay
      inputs.rust-overlay.overlays.default
      inputs.nix-alien.overlays.default
      (final: prev: {
        rclone = (prev.symlinkJoin { # create filesystem helpers until https://github.com/NixOS/nixpkgs/issues/258478
          name = "rclone";
          paths = [ prev.rclone ];
          postBuild = ''
            ln -sf $out/bin/rclone $out/bin/mount.rclone 
            ln -sf $out/bin/rclone $out/bin/rclonefs
          '';
        });
      })
    ];
  in {
    colmena = {
      meta.nixpkgs = inputs.nixos-23-05.legacyPackages.x86_64-linux;
    } // builtins.mapAttrs (name: value: { # from https://github.com/zhaofengli/colmena/issues/60#issuecomment-1047199551
        nixpkgs.system = value.config.nixpkgs.system;
        imports = value._module.args.modules;
      }) (inputs.self.nixosConfigurations);

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

    nixOnDroidConfigurations = {
      pixel6pro = inputs.nix-on-droid.lib.nixOnDroidConfiguration rec {
        system = "aarch64-linux";
        config = {pkgs, ...}: {
          user.shell = "${pkgs.fish}/bin/fish";
          nix.package = pkgs.nixFlakes;
          home-manager = {
            extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nix-on-droid.inputs.nixpkgs; is_nixos = false;};
            config = {pkgs, lib, config, ...}: {
              imports = [./hmModules/shared/core.nix];
              nixpkgs.overlays = getOverlays system;
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
	};
        extraModules = [];
      };
    };

    homeConfigurations = {
      paulg-x86_64-linux = inputs.home-manager-master.lib.homeManagerConfiguration rec {
        pkgs = (import inputs.nixos-unstable rec {
          # https://github.com/nix-community/home-manager/issues/2954
          # https://github.com/nix-community/home-manager/pull/2720
          system = "x86_64-linux";
          overlays = getOverlays system;
        });
        extraSpecialArgs = {inherit inputs; mainFlake = inputs.home-manager-master.inputs.nixpkgs; is_nixos = false;};
        modules = [ 
          {
            home = {
              username = "paulg";
              homeDirectory = "/home/paulg";
              stateVersion = "22.05";
            };
          }
          ./hmModules/shared/core.nix
          ./hmModules/shared/firefox.nix
          ./hmModules/shared/chromium.nix
        ];
      };
      paulg-aarch64-darwin = inputs.home-manager-master.lib.homeManagerConfiguration rec {
        pkgs = (import inputs.nixos-unstable rec {
          system = "aarch64-darwin";
          overlays = getOverlays system;
        });
        extraSpecialArgs = {inherit inputs; mainFlake = inputs.home-manager-master.inputs.nixpkgs; is_nixos = false;};
        modules = [ 
          {
            home = {
              username = "paulg";
              homeDirectory = "/Users/paulg";
              stateVersion = "22.05";
            };
          }
          ./hmModules/shared/core.nix
          ./hmModules/shared/firefox.nix
          ./hmModules/shared/chromium.nix
          ./hmModules/shared/desktop-macos.nix
        ];
      };
    };

    darwinConfigurations = let
      mkDarwinConf = arch: let
          inputs-patched = inputs // {nixpkgs = inputs.darwin-23-05; darwin = inputs.nix-darwin;};
        in inputs-patched.darwin.lib.darwinSystem rec {
          system = "${arch}-darwin";
          inputs = inputs-patched; # otherwise it would take this flake's inputs and expect nixpkgs and darwin to be hardcoded
          specialArgs = { inherit system inputs; }; #  passes inputs to modules
          modules = [
            { 
              nixpkgs = {
                overlays = getOverlays system;
              };
            }
            ./nix-darwin/common.nix
            inputs.home-manager-23-05.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nixpkgs; is_nixos = false;};
              home-manager.users.root  = { imports = [./hmModules/shared/core.nix];};
              home-manager.users.paulg = { imports = [
                ./hmModules/shared/core.nix
                ./hmModules/shared/firefox.nix
                ./hmModules/shared/chromium.nix
                ./hmModules/shared/desktop-macos.nix
                ./hmModules/shared/rust.nix
              ];};
            }
          ];
        };
    in {
      "MacBookPaul" = mkDarwinConf "x86_64";
      "MacMiniPaul" = mkDarwinConf "x86_64";
    };

    # Used with `nixos-rebuild --flake .#<hostname>`
    # nixosConfigurations."<hostname>".config.system.build.toplevel must be a derivation
    nixosConfigurations = let
      mkNixosConf = arch: nixos-channel: nixos-modules: hm-channel: hm-modules: inputs.${nixos-channel}.lib.nixosSystem rec {
        system = "${arch}-linux";
        specialArgs = { inherit system inputs nixos-channel; }; #  passes inputs to modules
        extraModules = [ inputs.colmena.nixosModules.deploymentOptions ]; # from https://github.com/zhaofengli/colmena/issues/60#issuecomment-1047199551
        modules = [ 
          { nixpkgs = {
              overlays = getOverlays system;
            };
          }
          inputs.${hm-channel}.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true; # means that pkgs are taken from the nixosSystem and not from home-manager.inputs.nixpkgs
            home-manager.useUserPackages = true; # means that pkgs are installed at /etc/profiles instead of $HOME/.nix-profile
            home-manager.extraSpecialArgs = {inherit system inputs;  mainFlake = inputs.${nixos-channel}; is_nixos = true;};
            home-manager.users.root  = { imports = hm-modules;};
            home-manager.users.paulg = { imports = hm-modules;};
          }
          inputs.sops-nix.nixosModules.sops
        ] ++ nixos-modules;
      };
    in { 
      nixos-nas = mkNixosConf "x86_64" "nixos-23-05" [
        ./nixosModules/nixos-nas.nix
      ]
      "home-manager-23-05"
      [
        ./hmModules/nixos-nas.nix
      ];

      nixos-macmini = mkNixosConf "x86_64" "nixos-23-05" [
        ./nixosModules/nixos-macmini.nix
      ]
      "home-manager-23-05"
      [
        ./hmModules/nixos-macmini.nix
      ];

      nixos-gcp = mkNixosConf "x86_64" "nixos-23-05" [
        ./nixosModules/nixos-gcp.nix
      ]
      "home-manager-23-05"
      [
        ./hmModules/nixos-gcp.nix
      ];

      nixos-oci = mkNixosConf "aarch64" "nixos-23-05" [
        ./nixosModules/nixos-oci.nix
      ]
      "home-manager-23-05"
      [
        ./hmModules/nixos-oci.nix
      ];

      nixos-xps = mkNixosConf "x86_64" "nixos-unstable" [
        ./nixosModules/nixos-xps.nix
      ]
      "home-manager-master"
      [
        ./hmModules/nixos-xps.nix
      ];

      nixos-macbook = mkNixosConf "x86_64" "nixos-unstable" [
        ./nixosModules/nixos-macbook.nix
      ]
      "home-manager-master"
      [
        ./hmModules/nixos-macbook.nix
      ];

    };
  };
}

