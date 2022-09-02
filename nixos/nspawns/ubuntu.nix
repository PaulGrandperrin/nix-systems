{ config, pkgs, ... }:
{
  networking.firewall.trustedInterfaces =  [ "ve-ubuntu" ];
  systemd.nspawn."ubuntu" = {
    enable = true;
    # wantedBy = [ "multi-user.target" ]; # doesn't work https://github.com/NixOS/nixpkgs/issues/189499
    networkConfig = {
      Port = "tcp:222:22";
    };
  };
  systemd.targets.machines.wants = [ "systemd-nspawn@ubuntu.service" ];
}

