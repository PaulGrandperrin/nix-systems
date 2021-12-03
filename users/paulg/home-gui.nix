{pkgs, ...}: {
  home = {
    stateVersion = "21.11";
    packages = with pkgs; [
      terminator
      glxinfo
      vulkan-tools
    ];
    sessionVariables = {
    };

  };

  systemd.user.sessionVariables = {
  };

  programs = {
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
