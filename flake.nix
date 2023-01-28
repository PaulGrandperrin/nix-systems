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
    nixos-22-11.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-22-11-small.url = "github:NixOS/nixpkgs/nixos-22.11-small";
    darwin-22-11.url = "github:NixOS/nixpkgs/nixpkgs-22.11-darwin";
    darwin-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # darwin-unstable for now (https://github.com/NixOS/nixpkgs/issues/107466)
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    #master.url = "github:NixOS/nixpkgs/master";

    nur.url = "github:nix-community/NUR";

    nix-on-droid = {
      url = "github:t184256/nix-on-droid/testing";
      inputs.nixpkgs.follows = "nixos-22-11"; # TODO try to remove
      inputs.flake-utils.follows = "flake-utils";
      inputs.home-manager.follows = "home-manager-22-11"; # TODO try to remove
    };

    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "darwin-22-11"; # FIXME only used to access lib...
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixos-22-11"; # FIXME used only for the lib
      inputs.flake-utils.follows = "flake-utils";
    };

    home-manager-22-11 = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixos-22-11"; # not needed by NixOS' module thanks to `home-manager.useGlobalPkgs = true` but needed by the unpriviledged module
    };

    #home-manager-master = {
    #  url = "github:nix-community/home-manager/master";
    #  inputs.nixpkgs.follows = "nixos-22-11"; # not needed by NixOS' module thanks to `home-manager.useGlobalPkgs = true` but needed by the unpriviledged module
    #};

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixos-22-11"; # TODO the overlay is using it, but I would like it to not use it
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
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixos-22-11";
    };
  };


  outputs = inputs: let 
    getOverlays = system: let # FIXME not sure those are the good channels for darwin
      pkgs-22-11 = inputs.nixos-22-11.legacyPackages.${system};
      #unstable-pkgs = inputs.nixos-unstable.legacyPackages.${system};
      #unstable-overlay = final: prev: { unstable = unstable-pkgs; };
    in
      [ inputs.nur.overlay inputs.rust-overlay.overlay inputs.nix-alien.overlay];
  in {
    colmena = {
      meta.nixpkgs = inputs.nixos-22-11.legacyPackages.x86_64-linux;
    } // builtins.mapAttrs (name: value: { # from https://github.com/zhaofengli/colmena/issues/60#issuecomment-1047199551
        nixpkgs.system = value.config.nixpkgs.system;
        imports = value._module.args.modules;
      }) (inputs.self.nixosConfigurations);

    packages.x86_64-linux.vcv-rack = inputs.nixos-22-11.legacyPackages.x86_64-linux.callPackage ./pkgs/vcv-rack {};

    #packages.x86_64-linux = {
    #  iso = inputs.nixos-generators.nixosGenerate {
    #    pkgs = inputs.nixos-22-11.legacyPackages.x86_64-linux;
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
      paulg-x86_64-linux = inputs.home-manager-22-11.lib.homeManagerConfiguration rec {
        system = "x86_64-linux";
        homeDirectory = "/home/paulg";
        username = "paulg";
        stateVersion = "22.05";
        pkgs = (import inputs.nixos-22-11 {
          # https://github.com/nix-community/home-manager/issues/2954
          # https://github.com/nix-community/home-manager/pull/2720
          inherit system;
          overlays = getOverlays system;
          config.allowUnfree = true;
        });
        extraSpecialArgs = {inherit system inputs; mainFlake = inputs.home-manager-22-11.inputs.nixpkgs; is_nixos = false;};
        configuration = { config, pkgs, lib, ... }: {
          imports = [ ./home-manager/cmdline.nix ./home-manager/desktop.nix];
        };
      };
      paulg-aarch64-darwin = inputs.home-manager-22-11.lib.homeManagerConfiguration rec {
        system = "aarch64-darwin";
        homeDirectory = "/Users/paulg";
        username = "paulg";
        stateVersion = "22.05";
        pkgs = (import inputs.nixos-22-11 {
          inherit system;
          overlays = getOverlays system;
          config.allowUnfree = true;
        });
        extraSpecialArgs = {inherit system inputs; mainFlake = inputs.home-manager-22-11.inputs.nixpkgs; is_nixos = false;};
        configuration = { config, pkgs, lib, ... }: {
          imports = [ ./home-manager/cmdline.nix ./home-manager/desktop.nix ./home-manager/desktop-macos.nix];
        };  
      };
    };

    darwinConfigurations = let
      mkDarwinConf = arch: let
          inputs-patched = inputs // {nixpkgs = inputs.darwin-22-11; darwin = inputs.nix-darwin;};
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
            inputs.home-manager-22-11.darwinModules.home-manager
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
          { nixpkgs = {overlays = getOverlays system; }; }
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
      nixos-nas = mkNixosConf "x86_64" "nixos-22-11-small" [
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
            additionalModules = [ pkgs.nginxModules.fancyindex ];
            virtualHosts."nas.paulg.fr" = {
              enableACME = true;
              forceSSL = true;
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
      "home-manager-22-11"
      [
        ./home-manager/cmdline.nix
      ];

      nixos-macmini = mkNixosConf "x86_64" "nixos-22-11-small" [
        ./nixos/hosts/nixos-macmini/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/net.nix
        ./nixos/nspawns.nix
        ./nixos/wireguard.nix
        ./nixos/auto-upgrade.nix
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
      "home-manager-22-11"
      [
        ./home-manager/cmdline.nix
      ];

      nixos-gcp = mkNixosConf "x86_64" "nixos-22-11-small" [
        ./nixos/hosts/gcp/hardware-configuration.nix
        ./nixos/google-compute-config.nix
        ./nixos/common.nix
        ./nixos/net.nix
        ./nixos/wireguard.nix
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
      "home-manager-22-11"
      [
        ./home-manager/cmdline.nix
      ];

      nixos-oci = mkNixosConf "aarch64" "nixos-22-11-small" [
        ./nixos/hosts/nixos-oci/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/containers/web.nix
        ./nixos/net.nix
        ./nixos/wireguard.nix
        ./nixos/auto-upgrade.nix
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
      "home-manager-22-11"
      [
        ./home-manager/cmdline.nix
        ./home-manager/rust-stable.nix
      ];

      nixos-xps = mkNixosConf "x86_64" "nixos-22-11" [
        ./nixos/hosts/xps/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/net.nix
        ./nixos/wireguard.nix
        ./nixos/desktop.nix
        ./nixos/desktop-i915.nix
        ./nixos/nvidia.nix
        ./nixos/modules/gaming.nix
        ({config, ...}:{
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

        })
      ]
      "home-manager-22-11"
      [
        ./home-manager/cmdline.nix
        ./home-manager/desktop.nix
        ./home-manager/desktop-linux.nix
        ./home-manager/rust-stable.nix
        ./home-manager/modules/wine.nix
      ];

      nixos-macbook = mkNixosConf "x86_64" "nixos-22-11" [
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

          powerManagement = {
            powerDownCommands = lib.mkBefore ''
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
      "home-manager-22-11"
      [
        ./home-manager/cmdline.nix
        ./home-manager/desktop.nix
        ./home-manager/desktop-linux.nix
        ./home-manager/rust-stable.nix
        ./home-manager/modules/wine.nix
      ];

    };
  };
}

