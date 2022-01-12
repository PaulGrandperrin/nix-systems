{pkgs, inputs, system, installDesktopApp ? true, ...}: {

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
      package = let 

        # build firefox-bin version from nixpkgs-master but with current dependencies
        masterPath = inputs.nixpkgs-master.outPath;
        firefox-bin-unwrapped = pkgs.callPackage (
          masterPath + "/pkgs/applications/networking/browsers/firefox-bin"
        ) {
          inherit (pkgs.gnome) adwaita-icon-theme;
          channel = "release";
          generated = import ( masterPath + "/pkgs/applications/networking/browsers/firefox-bin/release_sources.nix");
        };
        firefox-bin = pkgs.wrapFirefox firefox-bin-unwrapped {
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
        if installDesktopApp then
        ( pkgs.emptyDirectory // { override = _: firefox-bin-wayland ;} )
      else ( pkgs.emptyDirectory // { override = _: pkgs.emptyDirectory;} );

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
        wayback-machine
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

          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "extensions.pocket.enabled" = false;
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
