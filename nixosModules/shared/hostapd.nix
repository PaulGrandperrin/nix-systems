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
    radios."wlp1s0" = { # 5GHz 80MHz BW
      wifi4 = { # HT
        enable = true; # ieee80211n=true
        capabilities = [
          # from https://github.com/openwrt/openwrt/blob/main/package/kernel/mac80211/files/lib/netifd/wireless/mac80211.sh
          "HT40-" # remove if automatic channel selection https://github.com/NixOS/nixpkgs/commit/8a97d662ddc24d839f19c5f4f9dba4ecf46d8f94
          "LDPC"
          "SHORT-GI-20"
          "SHORT-GI-40"
          "TX-STBC"
          #"RX-STBC123" # not supported by driver
          "MAX-AMSDU-7935"
          "DSSS_CCK-40"
        ];
      };
      wifi5 = { # VHT
        enable = true; # ieee80211ac=true
        operatingChannelWidth = "80"; # vht_oper_chwidth
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
      wifi6 = { # HE
        enable = true; # ieee80211ax=true
        operatingChannelWidth = "80"; # he_oper_chwidth
      };
      wifi7 = {}; # EHT
      countryCode = "FR";
      channel = 48; # 0 is automatic
      band = "5g"; # "5g"; # hw_mode: 2g=g 5g=a 6g=a 60g=ad
      settings = {
        vht_oper_centr_freq_seg0_idx=42; # 5Ghz channel between 36 and 48 and BW=80
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
    #radios."wlp1s0" = { # 6Ghz / 160Mhz BW
    #  wifi6 = { # HE
    #    enable = true; # ieee80211ax=true
    #    operatingChannelWidth = "160"; # he_oper_chwidth
    #  };
    #  wifi7 = {}; # EHT
    #  countryCode = "FR";
    #  channel = 37; # 0 is automatic
    #  band = "6g"; # hw_mode: 2g=g 5g=a 6g=a 60g=ad
    #  settings = {
    #    he_oper_centr_freq_seg0_idx=47; # 6Ghz channel between 33 and 61 and BW=160
    #    #op_class = 131; # if 6Ghz and BW=20
    #    #op_class = 132 + 0; # if 6Ghz and BW=40
    #    #op_class = 132 + 1; # if 6Ghz and BW=80
    #    op_class = 132 + 2; # if 6Ghz and BW=160

    #    #he_bss_color=128; # nl80211: kernel reports: integer out of range. Failed to set beacon parameters

    #    #he_spr_sr_control=3;
    #    #he_default_pe_duration=4;
    #    #he_rts_threshold=1023;
    #    #he_mu_edca_qos_info_param_count=0;
    #    #he_mu_edca_qos_info_q_ack=0;
    #    #he_mu_edca_qos_info_queue_request=0;
    #    #he_mu_edca_qos_info_txop_request=0;
    #    #he_mu_edca_ac_be_aifsn=8;
    #    #he_mu_edca_ac_be_aci=0;
    #    #he_mu_edca_ac_be_ecwmin=9;
    #    #he_mu_edca_ac_be_ecwmax=10;
    #    #he_mu_edca_ac_be_timer=255;
    #    #he_mu_edca_ac_bk_aifsn=15;
    #    #he_mu_edca_ac_bk_aci=1;
    #    #he_mu_edca_ac_bk_ecwmin=9;
    #    #he_mu_edca_ac_bk_ecwmax=10;
    #    #he_mu_edca_ac_bk_timer=255;
    #    #he_mu_edca_ac_vi_ecwmin=5;
    #    #he_mu_edca_ac_vi_ecwmax=7;
    #    #he_mu_edca_ac_vi_aifsn=5;
    #    #he_mu_edca_ac_vi_aci=2;
    #    #he_mu_edca_ac_vi_timer=255;
    #    #he_mu_edca_ac_vo_aifsn=5;
    #    #he_mu_edca_ac_vo_aci=3;
    #    #he_mu_edca_ac_vo_ecwmin=5;
    #    #he_mu_edca_ac_vo_ecwmax=7;
    #    #he_mu_edca_ac_vo_timer=255;
    #  };
    #  networks.wlp1s0 = {
    #    ssid = "DelPuppo 6GHz";
    #    authentication = {
    #      mode = "wpa3-sae"; # WPA 3 only 
    #      saePasswordsFile = config.sops.secrets."hostapd-password".path; # WPA3 password
    #      enableRecommendedPairwiseCiphers = true;
    #    };
    #    settings = {
    #      ieee80211w=2; # PMF (Protected Management Frames), required by 6Ghz
    #    };
    #  };
    #};
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
