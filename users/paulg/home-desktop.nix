{pkgs, ...}: {
  targets.genericLinux.enable = true;
  home = {
    packages = with pkgs; [
      gnome.gnome-tweaks
      glxinfo
      vulkan-tools
      libva-utils # vainfo
      vdpauinfo
      ffmpeg
      mpv
      vlc
      waydroid
      gimp
    ];
    sessionVariables = { # only works for interactive shells
    };

  };

  # nixgl or hardware.opengl.setLdLibraryPath = true;


  systemd.user.sessionVariables = {
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = {
      package = pkgs.adwaita-qt;
      name = "adwaita";
    };
  };

  services = {
    #flameshot.enable = true; #TODO
  };

  programs = {
    foot.enable = true;
    kitty.enable = true; 
    alacritty.enable = true;
    mangohud.enable = true;
    vscode = {
      enable = true;
      extensions = [];
    };
    terminator = {
      enable = true;
      config = {};
    };
    chromium = {
      enable = true;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      ];
    };
    firefox = {
      enable = true;
      package = pkgs.firefox-wayland.override {
        # See nixpkgs' firefox/wrapper.nix to check which options you can use
        cfg = {
          # Gnome shell native connector
          enableGnomeExtensions = true;
        };
      };
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
