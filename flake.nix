{

  description = "Paul Grandperrin NixOS confs";

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
    nixos-23-05-lib.url = "github:NixOS/nixpkgs/nixos-23.05?dir=lib";
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
              imports = [./home-manager/cmdline.nix];
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
      paulg-x86_64-linux = inputs.home-manager-23-05.lib.homeManagerConfiguration rec {
        system = "x86_64-linux";
        pkgs = (import inputs.nixos-23-05 {
          # https://github.com/nix-community/home-manager/issues/2954
          # https://github.com/nix-community/home-manager/pull/2720
          inherit system;
          overlays = getOverlays system;
          config.allowUnfree = true;
        });
        extraSpecialArgs = {inherit inputs; mainFlake = inputs.home-manager-23-05.inputs.nixpkgs; is_nixos = false;};
        modules = [ 
          {
            home = {
              username = "paulg";
              homeDirectory = "/Users/paulg";
              stateVersion = "22.05";
            };
          }
          ./home-manager/cmdline.nix
          ./home-manager/desktop.nix
          ./home-manager/desktop-macos.nix
        ];
      };
      paulg-aarch64-darwin = inputs.home-manager-23-05.lib.homeManagerConfiguration rec {
        system = "aarch64-darwin";
        pkgs = (import inputs.nixos-23-05 {
          inherit system;
          overlays = getOverlays system;
          config.allowUnfree = true;
        });
        extraSpecialArgs = {inherit inputs; mainFlake = inputs.home-manager-23-05.inputs.nixpkgs; is_nixos = false;};
        modules = [ 
          {
            home = {
              username = "paulg";
              homeDirectory = "/Users/paulg";
              stateVersion = "22.05";
            };
          }
          ./home-manager/cmdline.nix
          ./home-manager/desktop.nix
          ./home-manager/desktop-macos.nix
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
                config.allowUnfree = true;
              };
            }
            ./nix-darwin/common.nix
            inputs.home-manager-23-05.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nixpkgs; is_nixos = false;};
              home-manager.users.root  = { imports = [./home-manager/cmdline.nix];};
              home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/desktop.nix ./home-manager/desktop-macos.nix ./home-manager/rust-stable.nix];};
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
              config.allowUnfree = true;
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
        ./nixos/hosts/nas/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/nspawns.nix
        ./nixos/net.nix
        ./nixos/modules/web.nix
        ./nixos/auto-upgrade.nix
        ./nixos/wireguard.nix
        ./nixos/headless.nix
        ./nixos/modules/observability.nix
        ./nixos/modules/mastodon.nix
        ./nixos/modules/home-assistant.nix
        ({pkgs, config, lib, ... }:{
          # colmena options
          deployment = {
            allowLocalDeployment = true;
            buildOnTarget = true;
            tags = ["nixos" "server" "headless" "deploy"];
            targetHost = "${config.networking.hostName}.wg";
          };
          
          networking.hostId="51079489";
          networking.hostName = "nixos-nas";
          services.net = {
            enable = true;
            mainInt = "enp3s0";
          }; 

          services.my-wg = {
            enable = true;
          };

          services.my-nspawn = {
            enable = true;
            name = "tidb-nas";
            net-id = 1;
            id = 1;
          };

          # web
          sops.secrets."web-nas.paulg.fr" = {
            sopsFile = ./secrets/nixos-nas.yaml;
            mode = "0440";
            owner = "nginx";
            group = "nginx";
            restartUnits = [ "nginx.service" ];
          };
          services.nginx = {
            #package = pkgs.nginxQuic;
            additionalModules = [ pkgs.nginxModules.fancyindex ];
            virtualHosts."nas.paulg.fr" = {
              enableACME = true;
              forceSSL = true;
              #quic = true;
              default = true;
              root = "/export/public/movies";
              locations."/" = {
                basicAuthFile = config.sops.secrets."web-nas.paulg.fr".path;
                extraConfig = ''
                  #autoindex on;
                  fancyindex on;              # Enable fancy indexes.
                  fancyindex_exact_size off;  # Output human-readable file sizes.
                '';
              };
            };
          };


          powerManagement.cpuFreqGovernor = "schedutil";
          boot.kernelModules = ["coretemp" "it87"]; # detected by sensors-detect
          hardware.fancontrol = {
            enable = true;
            config = ''
              # generated by pwmconfig
              INTERVAL=2
              DEVPATH=hwmon0=devices/platform/coretemp.0 hwmon1=devices/platform/it87.656
              DEVNAME=hwmon0=coretemp hwmon1=it8771
              FCTEMPS=hwmon1/pwm1=hwmon0/temp1_input  hwmon1/pwm2=hwmon1/temp2_input
              FCFANS=hwmon1/pwm1=hwmon1/fan1_input  hwmon1/pwm2=hwmon1/fan2_input
              MINTEMP=hwmon1/pwm1=30  hwmon1/pwm2=20
              MAXTEMP=hwmon1/pwm1=50  hwmon1/pwm2=30
              MINSTART=hwmon1/pwm1=150  hwmon1/pwm2=90
              MINSTOP=hwmon1/pwm1=0  hwmon1/pwm2=60
              MINPWM=hwmon1/pwm2=0
            '';
          };

          fileSystems = {
            "/IronWolf12TB" = {
              device = "IronWolf12TB";
              fsType = "zfs";
            };
            "/IronWolf12TB/clear" = {
              device = "IronWolf12TB/clear";
              fsType = "zfs";
            };
            "/export" = { # for security, make /export its own filesystem instead of just being a directory of / 
              device = "none";
              fsType = "tmpfs";
              options = [ "mode=755" ];
            };
            "/export/public" = {
              device = "/IronWolf12TB/clear";
              options = [ "bind" ];
            };
            "/export/encrypted" = {
              device = "/IronWolf12TB/encrypted";
              options = [ "bind" ];
            };
          };

          sops.secrets."cache-nas.paulg.fr-privkey.pem" = {
            sopsFile = ./secrets/nixos-nas.yaml;
            restartUnits = [ "nix-serve.service" ];
          };
          services.nix-serve = {
            enable = true;
            secretKeyFile = config.sops.secrets."cache-nas.paulg.fr-privkey.pem".path;
            openFirewall = false;
          };

          sops.secrets."deluge-auth" = {
            sopsFile = ./secrets/nixos-nas.yaml;
            owner = "nobody";
            restartUnits = [ "deluged.service" "delugeweb.service" ];
          };
          services.deluge = {
            enable = true;
            declarative = true;
            authFile = config.sops.secrets."deluge-auth".path;
            config = {
              download_location = "/export/public/torrent";
              allow_remote = true;
              daemon_port = 58846;
              listen_ports = [6881 6891];
              pre_allocate_storage = true;
              prioritize_first_last_pieces = true;
              sequential_download = true;
              stop_seed_at_ratio = true;
              stop_seed_ratio = 1.0;
              share_ratio_limit = 1.0;
              
            };
            openFirewall = true;
            user = "nobody";
            group = "nogroup";
            web = {
              enable = true;
              openFirewall = true;
              port = 8112;
            };
          };

          environment.etc."systemd/dnssd/10-nfs.dnssd".text = ''
            [Service]
            Name=NFS share on %H
            Type=_nfs._tcp
            Port=2049
            TxtText=path=/export/public
          '';

          environment.etc."systemd/dnssd/10-smb.dnssd".text = ''
            [Service]
            Name=SMB share on %H
            Type=_smb._tcp
            Port=445
            TxtText=path=/public
          '';

          systemd.services.systemd-resolved.restartTriggers = # reload resolved when a dnssd file changes
            map (i: i.source) (builtins.attrValues (lib.filterAttrs (n: _: builtins.isList (builtins.match "systemd/dnssd/.+" n)) config.environment.etc));

          services.nfs.server = {
            enable = true;
            exports = let
              root_options      = "fsid=root,insecure,no_subtree_check,all_squash,ro";
              public_options    = "insecure,no_subtree_check,all_squash,no_wdelay,rw";
              encrypted_options = "insecure,no_subtree_check,all_squash,no_wdelay,rw,anonuid=${toString config.users.users.paulg.uid},anongid=${toString config.users.groups.${config.users.users.paulg.group}.gid}";
            in ''
              /export           10.42.0.0/24(${root_options})   192.168.1.0/24(${root_options})
              /export/public    10.42.0.0/24(${public_options}) 192.168.1.0/24(${public_options})
              /export/encrypted 10.42.0.4(${encrypted_options}) 10.42.0.5(${encrypted_options}) # nixos-nas and nixos-macbook
            '';

            # fixed rpc.statd port; for firewall
            lockdPort = 4101;
            mountdPort = 4102;
            statdPort = 4100;
          };

          networking.firewall.allowedTCPPorts = [ 
            5357 # wsdd 
            2049 # nfs v3 and v4
            111 4100 4101 4102 20048 # nfs v3
            5201
          ];
          networking.firewall.allowedUDPPorts = [
            3702 # wsdd
            2049 # nfs v3 and v4
            111 4100 4101 4102 20048 # nfs v3
          ];

          services.samba-wsdd.enable = true; # make shares visible for windows 10 clients

          services.samba = {
            enable = true;
            openFirewall = true;
            nsswins = true; # name resolution
            securityType = "user";
            extraConfig = ''
              workgroup = WORKGROUP
              security = user 
              use sendfile = yes
              # note: localhost is the ipv6 localhost ::1
              hosts allow = 192.168. 10.42.0 127.0.0.1 localhost
              hosts deny = 0.0.0.0/0
              guest account = nobody
              map to guest = bad user
              #dfree command = 
            '';
            shares = {
              public = {
                path = "/export/public";
                browseable = "yes";
                #"read only" = "yes";
                writable = "yes";
                "guest ok" = "yes";
                public = "yes";
                "only guest" = "yes";
                #"create mask" = "0644";
                #"directory mask" = "0755";
                #"force user" = "username";
                #"force group" = "groupname";
                "vfs objects" = "recycle";
                #"recycle:repository" = ".recycle";
                "recycle:keeptree" = "yes";
                "recycle:versions" = "yes";
              };
            };
          };
        })
      ]
      "home-manager-23-05"
      [
        ./home-manager/cmdline.nix
      ];

      nixos-macmini = mkNixosConf "x86_64" "nixos-23-05" [
        ./nixos/hosts/nixos-macmini/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/net.nix
        ./nixos/nspawns.nix
        ./nixos/wireguard.nix
        ./nixos/auto-upgrade.nix
        ./nixos/headless.nix
        ({pkgs, config, lib, ... }:{
          # colmena options
          deployment = {
            allowLocalDeployment = true;
            buildOnTarget = true;
            tags = ["nixos" "server" "headless" "deploy"];
            targetHost = "${config.networking.hostName}.wg";
          };

          networking.hostId="aedc67f9";
          networking.hostName = "nixos-macmini";
          services.net = {
            enable = true;
            mainInt = "enp3s0f0";
          }; 
          powerManagement.cpuFreqGovernor = "schedutil";

          services.my-wg = {
            enable = true;
          };

          services.my-nspawn = {
            enable = true;
            name = "tidb-macmini";
            net-id = 2;
            id = 1;
          };

          boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless


          # broadcom_sta fails to build on linux 5.18: https://github.com/NixOS/nixpkgs/issues/177798
          #boot.kernelPackages = lib.mkForce pkgs.linuxPackages; # use stable kernel where broadcom_sta build
        })
      ]
      "home-manager-23-05"
      [
        ./home-manager/cmdline.nix
      ];

      nixos-gcp = mkNixosConf "x86_64" "nixos-23-05" [
        ./nixos/hosts/gcp/hardware-configuration.nix
        ./nixos/google-compute-config.nix
        ./nixos/common.nix
        ./nixos/net.nix
        ./nixos/wireguard.nix
        ./nixos/modules/thelounge.nix
        ./nixos/headless.nix
        # ./nixos/auto-upgrade.nix # 1G of memory is not enough to evaluate the system's derivation, even with zram...
        ({pkgs, lib, config, ...}:{
          # colmena options
          deployment = {
            allowLocalDeployment = false;
            buildOnTarget = false;
            tags = ["nixos" "server" "headless" "web"];
            targetHost = "${config.networking.hostName}.wg";
          };

          networking.hostId = "1c734661"; # for ZFS
          networking.hostName = "nixos-gcp";
          networking.interfaces.eth0.useDHCP = true;

          services.net = {
            enable = true;
            mainInt = "eth0";
          }; 

          services.my-wg = {
            enable = true;
          };

          boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless
          
          # useful to build and deploy closures from nixos-nas which a lot beefier than nixos-gcp
          users.users.root.openssh.authorizedKeys.keys = [ 
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5s0Fe3Y2kX5bxhipkD/OGePPRew40fElqzgacdavuY" # root@nixos-nas
          ];
          
          services.smartd.enable = lib.mkForce false;
        
          environment.systemPackages = with pkgs; [
            google-cloud-sdk-gce
          ];
        })
      ]
      "home-manager-23-05"
      [
        ./home-manager/cmdline.nix
      ];

      nixos-oci = mkNixosConf "aarch64" "nixos-23-05" [
        ./nixos/hosts/nixos-oci/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/containers/web.nix
        ./nixos/net.nix
        ./nixos/wireguard.nix
        ./nixos/auto-upgrade.nix
        ./nixos/headless.nix
        ({pkgs, lib, config, ...}:{
          # colmena options
          deployment = {
            allowLocalDeployment = true;
            buildOnTarget = true;
            tags = ["nixos" "server" "headless" "web"];
            targetHost = "${config.networking.hostName}.wg";
          };

          networking.hostId = "ea026662"; # head -c 8 /etc/machine-id
          networking.hostName = "nixos-oci";
          networking.interfaces.eth0.useDHCP = true;

          boot.kernelParams = [ "net.ifnames=0" ]; # so that network is always eth0

          services.net = {
            enable = true;
            mainInt = "eth0";
          }; 

          services.my-wg = {
            enable = true;
          };

          boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless

          services.smartd.enable = lib.mkForce false;

          environment.systemPackages = with pkgs; [
          ];
        })
      ]
      "home-manager-23-05"
      [
        ./home-manager/cmdline.nix
        ./home-manager/rust-stable.nix
      ];

      nixos-xps = mkNixosConf "x86_64" "nixos-unstable" [
        ./nixos/hosts/xps/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/net.nix
        ./nixos/wireguard.nix
        ./nixos/desktop.nix
        ./nixos/desktop-i915.nix
        ./nixos/nvidia.nix
        ./nixos/modules/gaming.nix
        ({config, pkgs, ...}:{
          # colmena options
          deployment = {
            allowLocalDeployment = true;
            buildOnTarget = true;
            tags = ["nixos" "laptop" "desktop" "deploy"];
            targetHost = "${config.networking.hostName}.wg";
          };

          networking.hostId="7ee1da4a";
          networking.hostName = "nixos-xps";
          services.net = {
            enable = true;
            mainInt = "wlp2s0";
          };

          services.my-wg = {
            enable = true;
          };

          services.thermald.enable = false; # should be disabled when throttled is enabled
          services.throttled.enable = true;

          systemd.services.smbios-thermal = {
            script = ''
              ${pkgs.libsmbios}/bin/smbios-thermal-ctl --set-thermal-mode quiet
            '';
            wantedBy = [ "multi-user.target" ];
          };

          boot.kernelParams = [
            "nvme_core.default_ps_max_latency_us=170000" # https://wiki.archlinux.org/title/Dell_XPS_15_(9560)#Enable_NVMe_APST and https://wiki.archlinux.org/title/Solid_state_drive/NVMe#Power_Saving_(APST)
            "enable_psr=1" "disable_power_well=0" # https://wiki.archlinux.org/title/Dell_XPS_15_(9560)#Enable_power_saving_features_for_the_i915_kernel_module
            #"acpi_rev_override=1" # https://wiki.archlinux.org/title/Dell_XPS_15_(9560)
          ];

          # workaround kernel bug
          boot.blacklistedKernelModules = [
            "rtsx_pci_sdmmc"
            "rtsx_pci"
          ];
          #boot.kernelPatches = [
          #  {
          #    patch = ./nixos/0001-Revert-misc-rtsx-judge-ASPM-Mode-to-set-PETXCFG-Reg.patch;
          #    name = "0001-Revert-misc-rtsx-judge-ASPM-Mode-to-set-PETXCFG-Reg";
          #  }
          #];
        })
        # secure boot
        inputs.lanzaboote.nixosModules.lanzaboote
        ({lib, pkgs, ...}:{
          boot.loader.systemd-boot.enable = lib.mkForce false;
          boot.lanzaboote = {
            enable = true;
            pkiBundle = "/etc/secureboot";
          };
          boot.initrd.systemd = let
            challenge = pkgs.writeText "challenge" "bf239fcf13ad263cb235eaa4aa6709a4cc8c0e843fa921bccbf083e70a3619f3  /sysroot/etc/secureboot/keys/PK/PK.key"; # don't forget to prepend /sysroot
          in {
            emergencyAccess = "$6$L5luqeVnXrobIl$TyGUOBnB.jvLxdq7t70TFFKkPbfkSqkN.fx8rU3rAomJhZjCBsTZkhC3CIDBFVQjNslcDmExjnGHjDT7TNHIR0";

            storePaths = [ pkgs.coreutils challenge];
            services.challenge-root-fs = {
              requires = ["initrd-root-fs.target"];
              after = ["initrd-root-fs.target"];
              requiredBy = ["initrd-parse-etc.service"];
              before = ["initrd-parse-etc.service"];
              unitConfig.AssertPathExists = "/etc/initrd-release";
              serviceConfig.Type = "oneshot";
              description = "Challenging the authenticity of the root FS";
              script = ''
                ${pkgs.coreutils}/bin/sha256sum -c ${challenge}
              '';
            };
          };

        })
      ]
      "home-manager-master"
      [
        ./home-manager/cmdline.nix
        ./home-manager/desktop.nix
        ./home-manager/desktop-linux.nix
        ./home-manager/rust-stable.nix
        ./home-manager/modules/wine.nix
      ];

      nixos-macbook = mkNixosConf "x86_64" "nixos-unstable" [
        ./nixos/hosts/nixos-macbook/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/net.nix
        ./nixos/wireguard.nix
        ./nixos/desktop.nix
        ./nixos/desktop-i915.nix
        ({pkgs, lib, config, ...}:{
          # colmena options
          deployment = {
            allowLocalDeployment = true;
            buildOnTarget = true;
            tags = ["nixos" "laptop" "desktop" "deploy"];
            targetHost = "${config.networking.hostName}.wg";
          };

          networking.hostId="f2b2467d";
          # hardware.facetimehd.enable = true; # FIXME broken
          services.mbpfan.enable = true;

          services.my-wg = {
            enable = true;
          };

          # use stable ZFS from nixos-unstable
          # NOTE: this also pulls the latest ZFS compatible linux from nixos-unstable
          nixpkgs.config.packageOverrides = _pkgs: {
            zfsStable = pkgs.unstable.zfsStable;
          };

          powerManagement = {
            powerDownCommands = lib.mkBefore ''
              modprobe -r thunderbolt # seems to help with resuming faster from S3

              # brcmfmac being loaded during hibernation would not let a successful resume
              # https://bugzilla.kernel.org/show_bug.cgi?id=101681#c116.
              # Also brcmfmac could randomly crash on resume from sleep.
              # And also, brcmfac prevents suspending
              ${pkgs.kmod}/bin/rmmod brcmfmac
              #echo disabled > /sys/bus/pci/devices/0000:03:00.0/power/wakeup # ARPT in /proc/acpi/wakeup, wifi adapter always wakes up the machine, already disabled by rmmod

              # if the LID is open
              if grep open /proc/acpi/button/lid/LID0/state; then
                # disable the open-lid sensor but enable the keyboard (USB) wake up events
                echo enabled > /sys/bus/pci/devices/0000:00:14.0/power/wakeup # XHC1 in /proc/acpi/wakeup, USB controller, sometimes wakes up the machine
                echo disabled > /sys/bus/acpi/devices/PNP0C0D:00/power/wakeup # LID0 in /proc/acpi/wakeup, wakes up the machine when the lid is in open position
              else 
                # enable the open-lid sensor wake events but disable to USB controller to be extra sure
                echo enabled > /sys/bus/acpi/devices/PNP0C0D:00/power/wakeup # LID0 in /proc/acpi/wakeup, wakes up the machine when the lid is in open position
                echo disabled > /sys/bus/pci/devices/0000:00:14.0/power/wakeup # XHC1 in /proc/acpi/wakeup, USB controller, sometimes wakes up the machine
              fi
            '';
            powerUpCommands = lib.mkBefore ''[ "$IN_NIXOS_SYSTEMD_STAGE1" = "true" ] || ${pkgs.kmod}/bin/modprobe brcmfmac''; # must not run in stage1 because module loading is not ready yet
          };

          # USB subsystem wakes up MBP right after suspend unless we disable it.
          #services.udev.extraRules = ''
          #  ### fix suspend on MacBookPro12,1 
          #  # found using:
          #  # cat /proc/acpi/wakeup
          #  # echo $device > /proc/acpi/wakeup # to bruteforce which devices woke up the laptop
          #  # fd $sysfs_node /sys
          #  # udevadm info -a -p $path
          #  #SUBSYSTEM=="pci", KERNEL=="0000:03:00.0", DRIVER=="brcmfmac", ATTR{power/wakeup}="disabled"
          #  #SUBSYSTEM=="acpi", KERNEL=="PNP0C0D:00", DRIVER=="button", ATTR{power/wakeup}="disabled" # LID0 in /proc/acpi/wakeup
          #  SUBSYSTEM=="acpi", KERNEL=="PNP0C0D:00", ATTR{power/wakeup}="disabled" # LID0 in /proc/acpi/wakeup
          #'';
          networking.hostName = "nixos-macbook";
          services.net = {
            enable = true;
            mainInt = "wlp3s0";
          };
        })
      ]
      "home-manager-master"
      [
        ./home-manager/cmdline.nix
        ./home-manager/desktop.nix
        ./home-manager/desktop-linux.nix
        #./home-manager/rust-stable.nix
        #./home-manager/modules/wine.nix
      ];

    };
  };
}

