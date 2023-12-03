{pkgs, ...}: {
  #networking.wireless = {
  #  enable = true;
  #  userControlled.enable = true;
  #};

  services.net = {
    bridged = true;
    extraBridgesInterfaces = ["wlp1s0"];
  };

  #systemd.network.networks."40-wlp1s0" = { # allows networkd to configure bridge even without a carrier
  #  name = "wlp1s0";
  #  linkConfig.ActivationPolicy = "manual";
  #};


  services.hostapd = {
    enable = true;
    radios."wlp1s0" = {
      wifi4.enable = true;
      wifi5.enable = true;
      #wifi6.enable = true;
      countryCode = "FR";
      channel = 40;
      # work-40hz: 40(38) 48(46) 153(151) 161(159) 169(167)
      # fallback : 44->40(38) 157->153(151) 165->161(159) 173->169(167)
      # fail-not-found-in-channel-list: 36 100 149
      # fail-can't determine operating frequency: 32 68 96 148 177
      # fail DFS: 52 56 60 64 104-144 
      band = "5g";
      networks.wlp1s0 = {
        ssid = "paulg";
        authentication = {
          mode = "wpa3-sae";
          saePasswords = [{password = "0123456789";}];
        };
      };
    };
  };

  systemd.services.hostapd = { # taken from https://github.com/NixOS/nixpkgs/issues/30225
    serviceConfig = {
      ExecStartPost = [
        "${pkgs.coreutils}/bin/sleep 5" # systemd-networkd-wait-online doesn't work for me
        "networkctl reconfigure wlp1s0" # bring up the bridge
      ];
    };
  };


}
