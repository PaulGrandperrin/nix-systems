{ config, pkgs, ... }:
{
  networking.firewall.trustedInterfaces =  [ "ve-debian" ];
  systemd.nspawn."debian" = {
    enable = true;
    networkConfig = {
      VirtualEthernet = "yes"; # workaround: https://github.com/systemd/systemd/issues/12313#issuecomment-487489767 
    };
    execConfig = {
      "PrivateUsers" = "pick"; # upstream uses "-U" by default
    };
    filesConfig = {
      "PrivateUsersChown" = true; # upstream uses "-U" by default
    };
  };
  systemd.services."systemd-nspawn@debian" = {
    enable = true;
    wantedBy = [ "machines.target" ];
    serviceConfig = {
      "KillMode" = "mixed";
      "RestartForceExitStatus" = "133";
      "SuccessExitStatus" = "133";
    };
    
  };

}

