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

    # nix run nixpkgs#debootstrap -- --include=systemd-container --components=main,universe jammy /var/lib/machines/ubuntu http://archive.ubuntu.com/ubuntu/
    # systemctl enable/start systemd-networkd
    # systemctl enable/start systemd-resolved

    systemd.nspawn."${cfg.name}" = {
      enable = true;
      #wantedBy = [ "multi-user.target" ]; # doesn't work https://github.com/NixOS/nixpkgs/issues/189499
      networkConfig = {
        Bridge = "br-my-nspawn";
        #Port = [
        #  "222:22"
        #  "2379"  # pd
        #  "20160" # tikv
        #  "4000"  # tidb
        #  "9090"  # prometheus
        #  "3000"  # grafana
        #];
      };
    };
    # systemd.services."systemd-nspawn@${cfg.name}".restartTriggers = [ config.environment.etc."systemd/nspawn/${cfg.name}.nspawn".source ]; # FIXME breaks the conf because it doesn't understand templates
    systemd.targets.machines.wants = [ "systemd-nspawn@${cfg.name}.service" ];

    services.kea.dhcp4 = {
      enable = true;
      settings = {
        interfaces-config = {
          interfaces = [
            "br-my-nspawn"
          ];
        };
        subnet4 = [
          {
            pools = [ { pool = "10.0.${toString cfg.net-id}.100 - 10.0.${toString cfg.net-id}.200"; } ];
            subnet = "10.0.${toString cfg.net-id}.0/24";
            #interface = "br-my-nspawn";
            reservations = [
              {
                hw-address = "4e:56:49:a0:4f:07";
                ip-address = "10.0.${toString cfg.net-id}.${toString cfg.id}";
              }
            ];
          }
        ];
      };
    };

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
        Address = "10.0.${toString cfg.net-id}.254/24";
        LinkLocalAddressing = "yes";
        #DHCPServer = "yes"; # doesn't work properly. using kea instead. https://github.com/systemd/systemd/issues/21368
        IPMasquerade = "ipv4";
        LLDP = "yes";
        EmitLLDP = "customer-bridge";
      };
      linkConfig = {
        "ActivationPolicy" = "up";
        "RequiredForOnline" = "no";
      };
      #dhcpServerConfig = { # 10.0.${toString cfg.net-id}.${toString cfg.id}
      #  PoolOffset = 100;
      #  PoolSize = 200;
      #};
      #dhcpServerStaticLeases = [{
      #  dhcpServerStaticLeaseConfig = {
      #    MACAddress = "4e:56:49:a0:4f:07";
      #    Address = "10.0.${toString cfg.net-id}.${toString cfg.id}";
      #  };
      #}];

    };
  };
}

