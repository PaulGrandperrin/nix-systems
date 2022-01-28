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
      easyeffects
      signal-desktop
      discord
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
      deluge
      rawtherapee
      libreoffice
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
    vscode = with pkgs; { # better than plain package which can't install extensions from internet
      enable = true;
      package = vscode-fhs; # vscodium version can't use synchronization. FHS version works better with internet's extensions
      userSettings = {
        "editor.bracketPairColorization.enabled" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.fontFamily" =  "'FiraCode Nerd Font Mono', 'Droid Sans Mono', 'monospace', monospace, 'Droid Sans Fallback'";
        "terminal.integrated.fontFamily" = "'FiraCode Nerd Font Mono'";
      };
      extensions = with vscode-extensions; [
        matklad.rust-analyzer
        tamasfe.even-better-toml
        serayuzgur.crates
        vadimcn.vscode-lldb
        #jscearcy.rust-doc-viewer
        usernamehw.errorlens
        eamodio.gitlens
        #swellaby.vscode-rust-test-adapter
        #sidp.strict-whitespace
      ];
    };
    terminator = {
      enable = true;
      config = {};
    };
  };

  fonts.fontconfig.enable = true;
}
