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
        };
      }));
    };
  };


  config = mkIf cfg.enable {
    networking.firewall.trustedInterfaces =  [ "br-nspawn" ];

    networking.firewall.extraCommands = ''
      iptables -A FORWARD -i br-nspawn -o "eth0" -j ACCEPT # accept packet going to the public internet (using "!eth0" doesn't work...)
      iptables -A FORWARD -i br-nspawn -j DROP # drop everything else

      # block the other way too
      iptables -A FORWARD -o br-nspawn -i "eth0" -j ACCEPT
      iptables -A FORWARD -o br-nspawn -j DROP

      # and drop all ipv6 traffic
      ip6tables -A FORWARD -i br-nspawn -j DROP
      ip6tables -A FORWARD -o br-nspawn -j DROP
      
      # and since I don't trust my iptables skills so just to be sure
      iptables -A FORWARD -s 10.43.0.0/16 -d 10.0.0.0/8 -j DROP
      iptables -A FORWARD -s 10.43.0.0/16 -d 172.16.0.0/12 -j DROP
      iptables -A FORWARD -s 10.43.0.0/16 -d 192.168.0.0/16 -j DROP
      iptables -A FORWARD -s 10.43.0.0/16 -d 127.0.0.0/8 -j DROP
      iptables -A FORWARD -s 10.43.0.0/16 -d 169.254.0.0/16 -j DROP

      # and the other way too
      iptables -A FORWARD -d 10.43.0.0/16 -s 10.0.0.0/8 -j DROP
      iptables -A FORWARD -d 10.43.0.0/16 -s 172.16.0.0/12 -j DROP
      iptables -A FORWARD -d 10.43.0.0/16 -s 192.168.0.0/16 -j DROP
      iptables -A FORWARD -d 10.43.0.0/16 -s 127.0.0.0/8 -j DROP
      iptables -A FORWARD -d 10.43.0.0/16 -s 169.254.0.0/16 -j DROP
    '';


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
        '')
      ];

      services."systemd-nspawn-${name}-init" = let
        exec-start-pre = pkgs.writeShellApplication {
          name = "systemd-nspawn-exec-start-pre";
          runtimeInputs = [pkgs.debootstrap pkgs.umount];
          text = ''
            # exit if machine already exists
            test -d /var/lib/machines/${name} && exit 0

            # install Debian
            debootstrap --include=systemd-container,dbus-broker,systemd-resolved --components=main,contrib,non-free --extra-suites=bookworm-updates bookworm /var/lib/machines/${name} http://deb.debian.org/debian/

            # debootstrap doesn't properly cleanup its mounts
            umount -q /var/lib/machines/${name}/proc
            umount -q /var/lib/machines/${name}/sys

            # enable networkd and resolved
            systemd-nspawn --machine=${name} /usr/bin/systemctl enable systemd-networkd.service
            systemd-nspawn --machine=${name} /usr/bin/systemctl enable systemd-resolved.service

            # set hostname
            echo "${name}" > /var/lib/machines/${name}/etc/hostname
          '';
        };
      in {
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

