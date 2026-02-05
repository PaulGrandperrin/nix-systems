args @ {pkgs, inputs, lib, config, is_nixos, ...}: lib.mkIf (config.home.username != "root") { 
  programs =
    let profiles =  {
      "paulgrandperrin@gmail.com" = {
        id = 0;
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          bitwarden
          buster-captcha-solver
          #bypass-paywalls-clean # FIXME
          #clearurls
          darkreader
          gesturefy
          i-dont-care-about-cookies
          languagetool
          #netflix-1080p # FIXME
          no-pdf-download
          octolinker
          old-reddit-redirect
          reddit-comment-collapser
          reddit-enhancement-suite
          refined-github
          rust-search-extension
          save-page-we
          sponsorblock
          stylus
          terms-of-service-didnt-read
          #translate-web-pages
          #tree-style-tab # fails
          ublock-origin
          unpaywall
          videospeed
          xbrowsersync
          zoom-page-we
        ];
        settings = { # user.js
          "services.sync.username" = "paulgrandperrin@gmail.com";
          "browser.search.region" = "US";
          "browser.aboutConfig.showWarning" = false;
          #"identity.fxaccounts.account.device.name" = "${networking.hostName}";
          "fission.autostart" = true;
          "browser.tabs.insertAfterCurrent" = true;

          "apz.overscroll.enabled" = true;
          #"apz.gtk.kinetic_scroll.enabled" = false;
          "widget.disable-swipe-tracker" = false; # scroll sideways in history
          "widget.swipe.whole-page-pixel-size" = 2000; # scroll sideway sensitivity
          "general.smoothScroll.msdPhysics.enabled" = true; # better mouse wheel scroll
          "apz.fling_friction" = "0.006";
          "apz.gtk.pangesture.delta_mode" = 2;
          "apz.gtk.pangesture.pixel_delta_mode_multiplier" = 25;
          "general.autoScroll" = true; # scroll with middle click
          "toolkit.tabbox.switchByScrolling" = true; # scroll to switch tabs

          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "extensions.pocket.enabled" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "network.IDN_show_punycode" = true;

          "gfx.webrender.all" = true;
          "gfx.webrender.compositor" = true;
          "gfx.webrender.compositor.force-enabled" = false; # NOTE render bugs

          # All of this should not be needed anymore
          #"media.hardware-video-decoding.enabled" = true;
          #"media.hardware-video-decoding.force-enabled" = true;
          #"media.ffmpeg.vaapi.enabled" = true;
          #"media.ffvpx.enabled" = false;
          #"media.navigator.mediadatadecoder_vpx_enabled" = true;
          #"media.rdd-vpx.enabled" = false;
          #"media.rdd-ffvpx.enabled" = false;
          #"media.rdd-process.enabled" = false;

          "network.trr.mode" = 3;
          "network.trr.uri" = "https://dns11.quad9.net/dns-query";
          #"network.trr.uri" = "https://dns.quad9.net/dns-query";
          #"network.trr.uri" = "https://dns10.quad9.net/dns-query";
          #"network.trr.uri" = "https://mozilla.cloudflare-dns.com/dns-query";
          #"network.trr.uri" = "https://dns.google/dns-query ";

          "network.dns.echconfig.enabled" = true;
          "network.dns.http3_echconfig.enabled" = true;
        };
      };
    };
  in {
    librewolf = {
      #enable = true; # currently unmaintained
      #package = pkgs.unstable.librewolf-bin.override {
      #  librewolf-bin-unwrapped = pkgs.unstable.librewolf-bin-unwrapped.overrideAttrs (oldAttrs: {
      #    meta = oldAttrs.meta // {
      #      knownVulnerabilities = [];
      #    };
      #  });
      #};
      inherit profiles;
    };
    firefox = {
      enable = true;
      package = pkgs.emptyDirectory // { override = _: # ugly trick to make things work in HM
        if (args ? nixosConfig) then pkgs.unstable.firefox-bin else pkgs.emptyDirectory; # trick to allow using HM config without installing nix version of Firefox
      };
      inherit profiles;
    };
  };

}
