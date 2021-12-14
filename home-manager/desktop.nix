{pkgs, installDesktopApp ? true, ...}: {

  programs = {
    chromium = {
      enable = true;
      package = if installDesktopApp then pkgs.chromium else pkgs.emptyDirectory;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      ];
    };
    firefox = {
      enable = true;
      package = if installDesktopApp then pkgs.firefox-wayland.override {
        # See nixpkgs' firefox/wrapper.nix to check which options you can use
        cfg = {
          # Gnome shell native connector
          enableGnomeExtensions = true;
        };
      } else pkgs.emptyDirectory;

      profiles."paulgrandperrin@gmail.com" = {
        id = 0;
        settings = { # user.js
          "services.sync.username" = "paulgrandperrin@gmail.com";
          "browser.search.region" = "US";
          #"identity.fxaccounts.account.device.name" = "${networking.hostName}";
          "fission.autostart" = true;

          "apz.overscroll.enabled" = true;

          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "network.IDN_show_punycode" = true;

          "gfx.webrender.all" = true;
          "gfx.webrender.compositor" = true;
          "gfx.webrender.compositor.force-enabled" = true;

          "media.hardware-video-decoding.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;
          #"media.ffmpeg.vaapi.enabled" = true;
          #"media.ffvpx.enabled" = false;
          #"media.navigator.mediadatadecoder_vpx_enabled" = true;
          #"media.rdd-vpx.enabled" = false;
          #"media.rdd-ffvpx.enabled" = false;
          #"media.rdd-process.enabled" = false;
        };
      };

    };
  };

}
