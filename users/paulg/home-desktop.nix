{pkgs, ...}: {
  targets.genericLinux.enable = true;
  home = {
    packages = with pkgs; [
      gnome.gnome-tweaks
      glxinfo
      vulkan-tools
      vlc
      waydroid
      kate
    ];
    sessionVariables = {
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
          "gfx.webrender.compositor.force-enabled" = true;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "network.IDN_show_punycode" = true;
        };
      };

    };
  };

}
