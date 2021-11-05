{ config, pkgs, ... }:
{
  systemd.nspawn."archlinux" = {
    enable = true;
    networkConfig = { VirtualEthernet = false; };
    execConfig = {
      "PrivateUsers" = "pick"; # elsewhere "-U" is used by default
    };
    filesConfig = {
      "PrivateUsersChown" = true; # elsewhere "-U" is used by default
    };
  };
  systemd.services."systemd-nspawn@archlinux" = {
    enable = true;
    wantedBy = [ "machines.target" ];
    serviceConfig = {
      "KillMode" = "mixed";
      "RestartForceExitStatus" = "133";
      "SuccessExitStatus" = "133";
    };
    
  };

}

