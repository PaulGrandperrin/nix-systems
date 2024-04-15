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
          dhcpServerStaticLeaseConfig = {
            MACAddress = value.mac;
            Address = "10.43.0.${toString value.id}";
          };
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
        (pkgs.writeTextDir "etc/systemd/system/systemd-nspawn@${name}.service.d/10-restart-triggers.conf" ''
         [Unit]
         X-Restart-Triggers=${pkgs.writeText "X-Restart-Triggers-${name}" (builtins.toJSON triggers)}

         [Service]
         MemoryMax=${value.max-mem}
         MemorySwapMax=0
        '')
      ];

      services."systemd-nspawn-${name}-init" = let
        exec-start-pre = pkgs.writeShellApplication {
          name = "systemd-nspawn-exec-start-pre";
          runtimeInputs = [pkgs.debootstrap pkgs.umount];
          text = ''
            # exit if machine already exists
            test -d /var/lib/machines/${name} && exit 0

            # undo any unfinished work
            umount -q /var/lib/machines/${name}_wip/* || true
            rm -rf /var/lib/machines/${name}_wip

            # install Debian with systemd for containers, kernel dbus, resolved DNS and unattended upgrades
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
          '';
        };
      in {
        requires = ["network-online.target"];
        after = ["network-online.target"];
        requiredBy = ["systemd-nspawn@${name}.service"];
        before = ["systemd-nspawn@${name}.service"];
        serviceConfig = {
          ExecStart = "${exec-start-pre}/bin/systemd-nspawn-exec-start-pre";
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

