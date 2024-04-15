{ config, pkgs, lib, ... }:
with lib;
let cfg = config.virtualisation.my-nspawn;
in {
  options.virtualisation.my-nspawn = {
    enable = mkEnableOption "My NSpawn";
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
          iifname "br-nspawn" oifname != "${config.services.net.mainInt}" drop
          oifname "br-nspawn" iifname != "${config.services.net.mainInt}" drop

          # and drop all ipv6 traffic
          meta nfproto ipv6 iifname "br-nspawn" drop
          meta nfproto ipv6 oifname "br-nspawn" drop
          
          # and since I don't trust my iptables skills so just to be sure
          ip saddr 10.43.0.0/16 ip daddr 169.254.169.254 accept # local resolved
          ip daddr 10.43.0.0/16 ip saddr 169.254.169.254 accept # local resolved
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
          #LinkLocalAddressing = "yes";
          #ConfigureWithoutCarrier=yes
          #LLDP = "yes";
          #EmitLLDP = "customer-bridge";
        };
        #linkConfig = {
        #  "ActivationPolicy" = "up";
        #  "RequiredForOnline" = "no";
        #};
        dhcpServerConfig = {
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
          config.systemd.network.networks."05-br-nspawn".dhcpServerConfig
          config.systemd.network.networks."05-br-nspawn".dhcpServerStaticLeases
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

            # install Debian with systemd for containers, kernel dbus, resolved DNS and unattended upgrades
            debootstrap --include=systemd-container,dbus-broker,systemd-resolved,unattended-upgrades --components=main,contrib,non-free,non-free-firmware --extra-suites=bookworm-updates bookworm /var/lib/machines/${name} http://deb.debian.org/debian/

            # debootstrap doesn't properly cleanup its mounts
            umount -q /var/lib/machines/${name}/proc
            umount -q /var/lib/machines/${name}/sys

            # enable networkd and resolved
            systemd-nspawn --machine=${name} /usr/bin/systemctl enable systemd-networkd.service
            systemd-nspawn --machine=${name} /usr/bin/systemctl enable systemd-resolved.service

            # set hostname
            echo "${name}" > /var/lib/machines/${name}/etc/hostname

            # security sources
            echo "deb http://security.debian.org/ bookworm-security main contrib non-free non-free-firmware" >> /var/lib/machines/${name}/etc/apt/sources.list
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
        };
      };

      targets.machines.wants = [ "systemd-nspawn@${name}.service" ];

    }) cfg.containers ));
  };
}

