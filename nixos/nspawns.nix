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
    networking.firewall.trustedInterfaces =  [ "ve-${cfg.name}" ];

    # nix run nixpkgs#debootstrap -- --include=systemd-container --components=main,universe jammy /var/lib/machines/ubuntu http://archive.ubuntu.com/ubuntu/
    # systemctl enable/start systemd-networkd
    # systemctl enable/start systemd-resolved

    systemd.nspawn."${cfg.name}" = {
      enable = true;
      #wantedBy = [ "multi-user.target" ]; # doesn't work https://github.com/NixOS/nixpkgs/issues/189499
      #networkConfig = {
      #  Port = [
      #    "222:22"
      #    "2379"  # pd
      #    "20160" # tikv
      #    "4000"  # tidb
      #    "9090"  # prometheus
      #    "3000"  # grafana
      #  ];
      #};
    };
    # systemd.services."systemd-nspawn@${cfg.name}".restartTriggers = [ config.environment.etc."systemd/nspawn/${cfg.name}.nspawn".source ]; # FIXME breaks the conf because it doesn't understand templates
    systemd.targets.machines.wants = [ "systemd-nspawn@${cfg.name}.service" ];

    systemd.network.networks."05-container-ve-${cfg.name}" = {
      matchConfig = {
        "Name" = "ve-${cfg.name}";
        "Driver" = "veth";
      };
      networkConfig = {
        "Address" = "10.0.${toString cfg.net-id}.254/24";
        "LinkLocalAddressing" = "yes";
        "DHCPServer" = "yes";
        "IPMasquerade" = "ipv4";
        "LLDP" = "yes";
        "EmitLLDP" = "customer-bridge";
      };
      linkConfig = {
        "ActivationPolicy" = "up";
        "RequiredForOnline" = "no";
      };
      dhcpServerConfig = { # 10.0.${toString cfg.net-id}.${toString cfg.id}
        PoolOffset = cfg.id;
        PoolSize = 1;
      };
    };
  };
}

