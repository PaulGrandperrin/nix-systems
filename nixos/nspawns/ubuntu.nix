{ config, pkgs, lib, ... }:
{
  networking.firewall.trustedInterfaces =  [ "ve-ubuntu" ];

  # nix run nixpkgs#debootstrap -- --include=systemd-container --components=main,universe jammy /var/lib/machines/ubuntu http://archive.ubuntu.com/ubuntu/
  # systemctl enable/start systemd-networkd
  # systemctl enable/start systemd-resolved

  systemd.nspawn."ubuntu" = {
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
  # systemd.services."systemd-nspawn@ubuntu".restartTriggers = [ config.environment.etc."systemd/nspawn/ubuntu.nspawn".source ]; # FIXME breaks the conf because it doesn't understand templates
  systemd.targets.machines.wants = [ "systemd-nspawn@ubuntu.service" ];

  systemd.network.networks."05-container-ve-ubuntu" = {
    matchConfig = {
      "Name" = "ve-ubuntu";
      "Driver" = "veth";
    };
    networkConfig = {
      "Address" = "10.0.1.1/24";
      "LinkLocalAddressing" = "yes";
      "DHCPServer" = "yes";
      "IPMasquerade" = "ipv4";
      "LLDP" = "yes";
      "EmitLLDP" = "customer-bridge";
    };
    dhcpServerConfig = { # 10.0.1.2
      PoolOffset = 2;
      PoolSize = 1;
    };
  };
}

