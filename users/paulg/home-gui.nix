{pkgs, ...}: {
  home = {
    stateVersion = "21.11";
    packages = with pkgs; [
      terminator
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

    };
  };

}
