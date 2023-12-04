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
      wifi4 = {
        enable = true;
        capabilities = [
          # iw phy phy0 info: Capabilities: 0x19ef
          # from https://github.com/openwrt/openwrt/blob/main/package/kernel/mac80211/files/lib/netifd/wireless/mac80211.sh
          "LDPC"
          "SHORT-GI-20"
          "SHORT-GI-40"
          "TX-STBC"
          "RX-STBC1"
          "MAX-AMSDU-7935"
          "DSSS_CCK-40"
          "HT40-"
          #"HT40+"
        ];
      };
      wifi5 = {
        enable = true;
        operatingChannelWidth = "80";
        capabilities = [
          # iw phy phy0 info: Capabilities: 0x339071b2
          # from https://github.com/openwrt/openwrt/blob/main/package/kernel/mac80211/files/lib/netifd/wireless/mac80211.sh
          "RXLDPC"
          "SHORT-GI-80"
          "TX-STBC-2BY1"
          "SU-BEAMFORMEE"
          "MU-BEAMFORMEE"
          "RX-ANTENNA-PATTERN"
          "TX-ANTENNA-PATTERN"
          "RX-STBC-1"
          "MAX-MPDU-11454"
          "MAX-A-MPDU-LEN-EXP7"
          "BF-ANTENNA-4" # really?
        ];
      };
      countryCode = "FR";
      channel = 48;
      band = "5g";
      settings = {
        vht_oper_centr_freq_seg0_idx = 42; # needed by wifi 5 80Mhz
      };
      networks.wlp1s0 = {
        ssid = "paulg";
        authentication = {
          mode = "wpa3-sae";
          saePasswords = [{password = "0123456789";}];
          enableRecommendedPairwiseCiphers = false; # unsupported 
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
