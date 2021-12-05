{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      gnome.gnome-tweaks
      glxinfo
      vulkan-tools
      vlc
    ];
    sessionVariables = {
    };

  };

  systemd.user.sessionVariables = {
  };

  programs = {
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
        };
      };

    };
  };

}
