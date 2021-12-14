{pkgs, isLinux, ...}: {
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
  };

}
