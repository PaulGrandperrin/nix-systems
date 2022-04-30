{pkgs, inputs, isLinux, ...}: {
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
      gnome.dconf-editor
      helvum
      unstable.gnome-console

      #(callPackage ../pkgs/vcv-rack {})

      # I want protonvpn from unstable but I don't want to pull its dependencies from unstable
      #(callPackage (inputs.nixos-unstable.outPath + "/pkgs/applications/networking/protonvpn-gui") {
      #  python3Packages = ( python3Packages // {protonvpn-nm-lib = python3Packages.callPackage (inputs.nixos-unstable.outPath + "/pkgs/development/python-modules/protonvpn-nm-lib") {};});
      #})
    ];
    sessionVariables = { # only works for interactive shells
    };

  };

  # nixgl or hardware.opengl.setLdLibraryPath = true;

  dconf.settings = {
    "org/gnome/calculator" = {
      button-mode = "programming";
    };
    "org/gnome/desktop/notifications" = {
      show-in-lock-screen = false;
    };
    "org/gnome/desktop/interface" = {
      show-battery-percentage = true;
      clock-show-weekday = true;
    };
    "org/gnome/mutter/experimental-features" = {
      rt-scheduler = true;
    };
    "org/gnome/desktop/privacy" = {
      remember-recent-files = true;
      recent-files-max-age = 7;
      remove-old-trash-files = true;
      remove-old-temp-files = true;
      old-files-age = 30;
    };
    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = true;
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = true;
    };
    "org/gnome/desktop/input-sources" = {
      xkb-options = 
        ["terminate:ctrl_alt_bksp" "compose:ralt" "lv3:switch" "eurosign:e"];
    };
    "org/gnome/desktop/media-handling" = {
      autorun-never = true;
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      delay = 500;
      repeat-interval = 30;
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "terminator.desktop"
        "org.gnome.Nautilus.desktop"
        "code.desktop"
        "signal-desktop.desktop"
      ];
      enabled-extensions = [
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "bluetooth-quick-connect@bjarosze.gmail.com"
        "clipboard-indicator@tudmotu.com"
        "places-menu@gnome-shell-extensions.gcampax.github.com"
        "sound-output-device-chooser@kgshank.net"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        "appindicatorsupport@rgcjonas.gmail.com"
      ];
    };
    "org/gnome/desktop/calendar" = {
      show-weekdate = true;
    };
    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim = false; # false isn't taken into account...
      idle-brightness = 100; # 100 means that it stay at whatever is was before
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "suspend";
      sleep-inactive-battery-timeout = 180; # time to sleep on battery 
      power-saver-profile-on-low-battery = true;
      power-button-action = "suspend";
    };
    "org/gnome/desktop/session" = {
      idle-delay = 120; # time to blank screen
    };
    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = 0;
    };
    "org/gnome/system/location" = {
      enabled = true;
    };
    "org/gnome/shell/weather" = {
      automatic-location = true;
    };
    "org/gnome/desktop/datetime" = {
      automatic-timezone = true;
    };
  };


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
        #matklad.rust-analyzer # already defined in rust module
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
