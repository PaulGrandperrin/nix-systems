{ config, pkgs, lib, ... }:
with lib;
let cfg = config.virtualisation.my-nspawn;
in {
  options.virtualisation.my-nspawn = {
    enable = mkEnableOption "My NSpawn";
    wan-if = mkOption {
      type = types.str;
    };
    containers = mkOption {
      description = "List of nspawn containers";
      default = {};
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          id = mkOption {
            type = types.ints.u8;
          };
          mac = mkOption {
            type = types.str;
          };
          ports = mkOption {
            type = types.listOf types.str;
          };
          max-mem = mkOption {
            type = types.str;
          };
          os = mkOption {
            type = types.str;
          };
        };
      }));
    };
  };


  config = mkIf cfg.enable {
    networking.firewall = {
      trustedInterfaces =  [ "br-nspawn" ];
    };

    networking.nftables.tables."my-nspawns" = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority filter; policy accept;

          # drop all traffic not going through the main int
          iifname "br-nspawn" oifname != "${cfg.wan-if}" drop
          oifname "br-nspawn" iifname != "${cfg.wan-if}" drop

          # drop all ipv6 traffic
          meta nfproto ipv6 iifname "br-nspawn" drop
          meta nfproto ipv6 oifname "br-nspawn" drop

          # drop all traffic with wrong network
          iifname "br-nspawn" ip saddr != 10.43.0.0/16 drop
          oifname "br-nspawn" ip daddr != 10.43.0.0/16 drop
          
          # drop all traffic with local, link-local and private networks
          ip saddr 10.43.0.0/16 ip daddr {127.0.0.0/8, 169.254.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16} drop
          ip daddr 10.43.0.0/16 ip saddr {127.0.0.0/8, 169.254.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16} drop
        }
      '';
    };

    systemd = lib.mkMerge ([{

      network.netdevs."05-br-nspawn".netdevConfig = {
        Kind = "bridge";
        Name = "br-nspawn";
      };

      network.networks."05-br-nspawn" = {
        matchConfig = {
          Name = "br-nspawn";
          Driver = "bridge";
        };
        networkConfig = {
          Address = "10.43.0.254/24";
          DHCPServer = "yes";
          IPMasquerade = "ipv4";
        };
        dhcpServerConfig = {
          DNS = "9.9.9.1 149.112.112.112";
          PoolOffset = 100;
          PoolSize = 100;
        };
      };

    }] ++ (lib.mapAttrsToList ( name: value: {
      network.networks."05-br-nspawn" = {
        dhcpServerStaticLeases = [{
          MACAddress = value.mac;
          Address = "10.43.0.${toString value.id}";
        }];
      };

      nspawn."${name}" = {
        enable = true;
        networkConfig = {
          Bridge = "br-nspawn";
          Port = value.ports;
        };
      };

      # `systemd.services."systemd-nspawn@${name}".restartTriggers` will not work because it would make Nix write a new service file
      # not derived from the systemd provided template. This new service file will therefore be incomplete but will fully replace the template.
      # So we write the X-Restart-Triggers in an override file ourself.
      # `environment.etc."systemd/system/systemd-nspawn@${name}.service.d/10-restart-triggers.conf"` won't work either so we create a systemd package instead.
      packages = let
        triggers = [
          config.systemd.nspawn.${name}
          config.systemd.network.networks."05-br-nspawn".networkConfig
          #config.systemd.network.networks."05-br-nspawn".dhcpServerConfig
          #config.systemd.network.networks."05-br-nspawn".dhcpServerStaticLeases
        ]; 
      in [
        (pkgs.writeTextDir "etc/systemd/system/systemd-nspawn@${name}.service.d/10-restart-triggers-${name}.conf" ''
         [Unit]
         X-Restart-Triggers=${pkgs.writeText "X-Restart-Triggers-${name}" (builtins.toJSON triggers)}

         [Service]
         MemoryMax=${value.max-mem}
         MemorySwapMax=0
        '')
      ];

      services."systemd-nspawn-${name}-init" = let
        exec-start-pre = pkgs.writeShellApplication {
          name = "systemd-nspawn-${name}-init";
          runtimeInputs = with pkgs; [debootstrap umount util-linux nixos-install-tools nix];
          text = ({
            debian = ''
              # exit if machine already exists
              test -d /var/lib/machines/${name} && exit 0

              # undo any unfinished work
              umount -q /var/lib/machines/${name}_wip/* || true
              rm -rf /var/lib/machines/${name}_wip

              # install debian with systemd for containers, kernel dbus, resolved dns and unattended upgrades
              debootstrap --include=systemd-container,dbus-broker,systemd-resolved,unattended-upgrades --components=main,contrib,non-free,non-free-firmware --extra-suites=bookworm-updates bookworm /var/lib/machines/${name}_wip http://deb.debian.org/debian/

              # debootstrap doesn't properly cleanup its mounts
              umount -q /var/lib/machines/${name}_wip/* || true

              # enable networkd and resolved
              systemd-nspawn -D /var/lib/machines/${name}_wip /usr/bin/systemctl enable systemd-networkd.service
              systemd-nspawn -D /var/lib/machines/${name}_wip /usr/bin/systemctl enable systemd-resolved.service

              # set hostname
              echo "${name}" > /var/lib/machines/${name}_wip/etc/hostname

              # security sources
              echo "deb http://security.debian.org/ bookworm-security main contrib non-free non-free-firmware" >> /var/lib/machines/${name}_wip/etc/apt/sources.list

              mv /var/lib/machines/${name}_wip /var/lib/machines/${name}
            '' ;
            nixos = ''
              # exit if machine already exists
              test -d /var/lib/machines/${name} && exit 0

              # undo any unfinished work
              rm -rf /var/lib/machines/${name}_wip

              mkdir -p /var/lib/machines/${name}_wip/etc/nixos

              cat >/var/lib/machines/${name}_wip/etc/nixos/flake.nix <<EOF
              {
                inputs = {
                  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
                };
              
                outputs = { self, nixpkgs, ... } @ inputs: let
                  system = "x86_64-linux";
                  pkgs = nixpkgs.legacyPackages.\''${system};
                  nixpkgs-patched-drv = pkgs.applyPatches { # see https://discourse.nixos.org/t/proper-way-of-applying-patch-to-system-managed-via-flake/21073/26 , https://github.com/NixOS/nix/issues/3920 and https://github.com/NixOS/nix/pull/6530
                    name = "nixpkgs-patched";
                    src = nixpkgs;
                    patches = [
                      (pkgs.fetchpatch2 { # use fetchurl if includes renames: https://github.com/NixOS/nixpkgs/issues/32084
                        url = "https://github.com/NixOS/nixpkgs/pull/301915.patch"; # allows disabling FSs
                        hash = "sha256-iqwsFpTamojyOGO40FMx+vi4SHb4mQSMQvrNFY3wZUA=";
                      })
                    ];
                  };
                  nixpkgs-patched = (import "\''${nixpkgs-patched-drv}/flake.nix").outputs { self = inputs.self; }; # TODO maybe use fix: https://discourse.nixos.org/t/how-to-override-let-variables/23741 and https://discourse.nixos.org/t/trying-to-understand-lib-fix/29667
              
                in {
                  nixosConfigurations.${name} = nixpkgs-patched.lib.nixosSystem rec {
                    modules = [
                      ({ config, lib, pkgs, modulesPath, ... }: {
                        imports = [
                        ];
              
                        # disabled mounts already handled by the host
                        boot.specialFileSystems."/dev".enable = false;
                        boot.specialFileSystems."/dev/pts".enable = false;
                        boot.specialFileSystems."/dev/shm".enable = false;
                        boot.specialFileSystems."/run".enable = false;
              
                        boot.loader.initScript.enable = true; # creates /sbin/init which is needed by nspawn
              
                        boot.isContainer = true;
                        # override some options set by isContainer
                        services.udev.enable = lib.mkForce true; # maybe we just need systemd.additionalUpstreamSystemUnits = ["systemd-udev-trigger.service"];
                        nix.optimise.automatic = lib.mkOverride 999 true;
                        documentation.nixos.enable = lib.mkOverride 999 true;
                        environment.variables.NIX_REMOTE = lib.mkForce "";
              
                        nix.settings = {
                          sandbox = false; # unpriviledged containers can't create namespaces
                          experimental-features = [ "nix-command" "flakes" ];
                        };
              
                        networking.hostName = "${name}";
                        networking.useNetworkd = true;
                        networking.enableIPv6 = false;
              
                        services.resolved.enable = true;
                        networking.useHostResolvConf = false; # mandatory to enabled resolved
              
                        networking.useDHCP = lib.mkDefault true;
                        networking.interfaces.host0.useDHCP = lib.mkDefault true;
              
                        environment.systemPackages = with pkgs; [
                          vim
                          wget
                        ];
              
                        system.stateVersion = "25.05";
                        nixpkgs.hostPlatform = lib.mkDefault system;
                      })
                    ];
                  };
                };
              }
              EOF

              unshare -m /bin/sh -exc "mount -o bind /var/lib/machines/${name}_wip /mnt; nixos-install --no-channel-copy --no-bootloader --no-root-password --flake /mnt/etc/nixos#${name} "

              systemd-nspawn -D /var/lib/machines/${name}_wip -- /nix/var/nix/profiles/system/activate

              mkdir -p /var/lib/machines/${name}_wip/sbin
              
              ln -s /nix/var/nix/profiles/system/init /var/lib/machines/${name}_wip/sbin/init

              mv /var/lib/machines/${name}_wip /var/lib/machines/${name}

            '';
          }.${value.os});
        };
      in {
        requires = ["network-online.target"];
        after = ["network-online.target"];
        requiredBy = ["systemd-nspawn@${name}.service"];
        before = ["systemd-nspawn@${name}.service"];
        serviceConfig = {
          ExecStart = "${exec-start-pre}/bin/systemd-nspawn-${name}-init";
          Type = "oneshot";
          TimeoutStartSec = "5min";
          Restart = "on-failure";
          RestartSec = "5";
          RestartMode = "direct"; # skip failed state on restarts, don't notify dependents on temporary failures
        };
      };

      targets.machines.wants = [ "systemd-nspawn@${name}.service" ];

    }) cfg.containers ));
  };
}

