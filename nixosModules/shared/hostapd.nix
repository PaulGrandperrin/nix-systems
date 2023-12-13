{pkgs, config, ...}: {
  environment.systemPackages = [ pkgs.iw ];

  services.net = {
    bridged = true;
    extraBridgesInterfaces = ["wlp1s0"];
  };

  #systemd.network.networks."40-wlp1s0" = { # allows networkd to configure bridge even without a carrier
  #  name = "wlp1s0";
  #  linkConfig.ActivationPolicy = "manual";
  #};

  sops.secrets."hostapd-password" = {
    restartUnits = [ "hostapd.service" ];
  };

  # networking.wireless.athUserRegulatoryDomain = true;

  services.hostapd = {
    enable = true;
    radios."wlp1s0" = {
      wifi4 = {
        enable = true;
        capabilities = [
          # from https://github.com/openwrt/openwrt/blob/main/package/kernel/mac80211/files/lib/netifd/wireless/mac80211.sh
          "HT40-"
          "LDPC"
          "SHORT-GI-20"
          "SHORT-GI-40"
          "TX-STBC"
          #"RX-STBC123" # not supported by driver
          "MAX-AMSDU-7935"
          "DSSS_CCK-40"
        ];
      };
      wifi5 = {
        enable = true;
        operatingChannelWidth = "80";
        capabilities = [
          # from https://github.com/openwrt/openwrt/blob/main/package/kernel/mac80211/files/lib/netifd/wireless/mac80211.sh
          "RXLDPC"
          "SHORT-GI-80"
          "SHORT-GI-160"
          "TX-STBC-2BY1"
          "SU-BEAMFORMEE"
          "MU-BEAMFORMEE"
          "RX-ANTENNA-PATTERN"
          "TX-ANTENNA-PATTERN"
          "RX-STBC-1"
          "BF-ANTENNA-4"
          "VHT160"
          "MAX-MPDU-11454"
          "MAX-A-MPDU-LEN-EXP7"
        ];
      };
      wifi6 = {
        enable = true;
        operatingChannelWidth = "80";
      };
      countryCode = "FR";
      channel = 48;
      band = "5g";
      settings = {
        vht_oper_centr_freq_seg0_idx=42;
        he_oper_centr_freq_seg0_idx=42;
        #he_bss_color=128; # nl80211: kernel reports: integer out of range. Failed to set beacon parameters
        he_spr_sr_control=3;
        he_default_pe_duration=4;
        he_rts_threshold=1023;
        he_mu_edca_qos_info_param_count=0;
        he_mu_edca_qos_info_q_ack=0;
        he_mu_edca_qos_info_queue_request=0;
        he_mu_edca_qos_info_txop_request=0;
        he_mu_edca_ac_be_aifsn=8;
        he_mu_edca_ac_be_aci=0;
        he_mu_edca_ac_be_ecwmin=9;
        he_mu_edca_ac_be_ecwmax=10;
        he_mu_edca_ac_be_timer=255;
        he_mu_edca_ac_bk_aifsn=15;
        he_mu_edca_ac_bk_aci=1;
        he_mu_edca_ac_bk_ecwmin=9;
        he_mu_edca_ac_bk_ecwmax=10;
        he_mu_edca_ac_bk_timer=255;
        he_mu_edca_ac_vi_ecwmin=5;
        he_mu_edca_ac_vi_ecwmax=7;
        he_mu_edca_ac_vi_aifsn=5;
        he_mu_edca_ac_vi_aci=2;
        he_mu_edca_ac_vi_timer=255;
        he_mu_edca_ac_vo_aifsn=5;
        he_mu_edca_ac_vo_aci=3;
        he_mu_edca_ac_vo_ecwmin=5;
        he_mu_edca_ac_vo_ecwmax=7;
        he_mu_edca_ac_vo_timer=255;
      };
      networks.wlp1s0 = {
        ssid = "DelPuppo 5GHz";
        authentication = {
          mode = "wpa3-sae-transition"; # WPA2+3
          wpaPasswordFile = config.sops.secrets."hostapd-password".path; # WPA2 password
          saePasswordsFile = config.sops.secrets."hostapd-password".path; # WPA3 password
          enableRecommendedPairwiseCiphers = true;
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
