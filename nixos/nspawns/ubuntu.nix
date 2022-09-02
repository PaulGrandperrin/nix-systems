{ config, pkgs, ... }:
{
  networking.firewall.trustedInterfaces =  [ "ve-ubuntu" ];
  systemd.nspawn."ubuntu".enable = true;
  systemd.targets.machines.wants = [ "systemd-nspawn@ubuntu.service" ];
}

