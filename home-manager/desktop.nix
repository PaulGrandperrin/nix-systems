{pkgs, inputs, system, lib, config, is_nixos, ...}: lib.mkIf (config.home.username != "root") { 

  programs = {
    chromium = {
      enable = true;
      package = if is_nixos then pkgs.chromium else pkgs.emptyDirectory;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "fihnjjcciajhdojfnbdddfaoknhalnja"; } # I don't care about cookies
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      ];
    };
    firefox = {
      enable = true;
      package = let 

        # build firefox-bin version from nixos-unstable but with current dependencies
        path = inputs.nixos-unstable-small.outPath;
        firefox-bin-unwrapped = pkgs.callPackage ( # taken from pkgs/top-level/all-packages.nix
          path + "/pkgs/applications/networking/browsers/firefox-bin"
        ) {
          inherit (pkgs.gnome) adwaita-icon-theme;
          channel = "release";
          generated = import ( path + "/pkgs/applications/networking/browsers/firefox-bin/release_sources.nix");
        };
        firefox-bin = pkgs.wrapFirefox firefox-bin-unwrapped { # taken from pkgs/top-level/all-packages.nix
          applicationName = "firefox";
          pname = "firefox-bin";
          desktopName = "Firefox";
        };

        # wrap it to run with Wayland
        firefox-bin-wayland = (pkgs.symlinkJoin {
          name = "firefox-bin-wayland";
          paths = [ firefox-bin ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/firefox \
              --set-default "MOZ_ENABLE_WAYLAND" "1"
          '';
        });
      in
      pkgs.emptyDirectory // { override = _: # ugly trick to make things work in HM
        if is_nixos then firefox-bin-wayland else pkgs.emptyDirectory; # trick to allow using HM config without installing nix version of Firefox
      };

      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        bitwarden
        buster-captcha-solver
        bypass-paywalls-clean
        clearurls
        darkreader
        gesturefy
        i-dont-care-about-cookies
        languagetool
        netflix-1080p
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
        translate-web-pages
        tree-style-tab
        ublock-origin
        unpaywall
        videospeed
        xbrowsersync
        zoom-page-we
      ];

      profiles."paulgrandperrin@gmail.com" = {
        id = 0;
        settings = { # user.js
          "services.sync.username" = "paulgrandperrin@gmail.com";
          "browser.search.region" = "US";
          "browser.aboutConfig.showWarning" = false;
          #"identity.fxaccounts.account.device.name" = "${networking.hostName}";
          "fission.autostart" = true;

          "apz.overscroll.enabled" = true;
          "apz.gtk.kinetic_scroll.enabled" = false;

          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "extensions.pocket.enabled" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "network.IDN_show_punycode" = true;

          "gfx.webrender.all" = true;
          "gfx.webrender.compositor" = true;
          "gfx.webrender.compositor.force-enabled" = false; # NOTE render bugs

          "media.hardware-video-decoding.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;
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
  };

}
