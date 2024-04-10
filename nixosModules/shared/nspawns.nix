{ config, pkgs, lib, ... }:
with lib;
let cfg = config.services.my-nspawn;
in {
  options.services.my-nspawn = {
    enable = mkEnableOption "My NSpawn";
    name = mkOption {
      type = types.str;
    };
    net-id = mkOption {
      type = types.ints.u8;
    };
    id = mkOption {
      type = types.ints.u8;
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.trustedInterfaces =  [ "br-my-nspawn" ]; # when using regular veth: "vb-${cfg.name}"

    systemd.nspawn."${cfg.name}" = {
      enable = true;
      networkConfig = {
        Bridge = "br-my-nspawn";
        Port = [
          "222:22"
        ];
      };
    };

    # `systemd.services."systemd-nspawn@${cfg.name}".restartTriggers` will not work because it would make Nix write a new service file
    # not derived from the systemd provided template. This new service file will therefore be incomplete but will fully replace the template.
    # So we write the X-Restart-Triggers in an override file ourself.
    # `environment.etc."systemd/system/systemd-nspawn@debian.service.d/10-restart-triggers.conf"` won't work either so we create a systemd package instead.
    systemd.packages = [
      (pkgs.writeTextDir "etc/systemd/system/systemd-nspawn@debian.service.d/10-restart-triggers.conf" ''
       [Unit]
       X-Restart-Triggers=${pkgs.writeText "X-Restart-Triggers-${cfg.name}" (builtins.toJSON [ config.systemd.nspawn.${cfg.name} config.systemd.network.networks."05-br-my-nspawn"])}
      '')
    ];

    systemd.services."systemd-nspawn-${cfg.name}-init" = let
      exec-start-pre = pkgs.writeShellApplication {
        name = "systemd-nspawn-exec-start-pre";
        runtimeInputs = [pkgs.debootstrap pkgs.umount];
        text = ''
          # exit if machine already exists
          test -d /var/lib/machines/${cfg.name} && exit 0

          # install Debian
          debootstrap --include=systemd-container,dbus-broker,systemd-resolved --components=main,contrib,non-free --extra-suites=bookworm-updates bookworm /var/lib/machines/${cfg.name} http://deb.debian.org/debian/

          # debootstrap doesn't properly cleanup its mounts
          umount -q /var/lib/machines/${cfg.name}/proc
          umount -q /var/lib/machines/${cfg.name}/sys

          # enable networkd and resolved
          systemd-nspawn --machine=debian /usr/bin/systemctl enable systemd-networkd.service
          systemd-nspawn --machine=debian /usr/bin/systemctl enable systemd-resolved.service

          # set hostname
          echo "${cfg.name}" > /var/lib/machines/${cfg.name}/etc/hostname
        '';
      };
    in {
      requiredBy = ["systemd-nspawn@${cfg.name}.service"];
      before = ["systemd-nspawn@${cfg.name}.service"];
      serviceConfig = {
        ExecStart = "${exec-start-pre}/bin/systemd-nspawn-exec-start-pre";
        Type = "oneshot";
        TimeoutStartSec = "5min";
      };
    };

    systemd.targets.machines.wants = [ "systemd-nspawn@${cfg.name}.service" ];

    systemd.network.netdevs."05-br-my-nspawn".netdevConfig = {
      Kind = "bridge";
      Name = "br-my-nspawn";
    };

    systemd.network.networks."05-br-my-nspawn" = {
      matchConfig = {
        Name = "br-my-nspawn";
        Driver = "bridge";
      };

      networkConfig = {
        Address = "10.43.${toString cfg.net-id}.254/24";
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
      dhcpServerStaticLeases = [{
        dhcpServerStaticLeaseConfig = {
          MACAddress = "6e:e0:b3:08:f0:aa"; # debian
          Address = "10.43.${toString cfg.net-id}.${toString cfg.id}";
        };
      }];

    };
  };
}

