{pkgs, inputs, lib, config, ...}: lib.mkIf (config.home.username != "root") {
  home = {
    packages = with pkgs; [
      gnome-tweaks
      gnome-extension-manager
      dconf-editor
      gnome-console

      #gnomeExtensions.sound-output-device-chooser # incomp
      gnomeExtensions.bluetooth-quick-connect
      #gnomeExtensions.gsconnect
      gnomeExtensions.blur-my-shell
      #gnomeExtensions.pixel-saver # incomp
      #gnomeExtensions.floating-dock # incomp
      #gnomeExtensions.emoji-selector
      gnomeExtensions.clipboard-indicator #gnomeExtensions.pano
      #gnomeExtensions.drop-down-terminal # incomp
      #gnomeExtensions.ddterm
      #gnomeExtensions.coverflow-alt-tab
      gnomeExtensions.dash-to-dock # well maintained
      #gnomeExtensions.dash-to-panel # unmaintained
      #gnomeExtensions.dock-from-dash # little maintained
      gnomeExtensions.caffeine
      gnomeExtensions.appindicator
      gnomeExtensions.bluetooth-battery
      gnomeExtensions.task-widget
      #gnomeExtensions.focus-indicator # not anymore in 23.11
      #gnomeExtensions.desktop-cube
      #gnomeExtensions.pop-shell
      gnomeExtensions.tiling-shell
      #gnomeExtensions.rectangle
      #wintile?

    ];
  };

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
      enable-hot-corners = true;
    };
    "org/gnome/mutter" = {
      edge-tiling = true;
      dynamic-workspaces = true;
      workspaces-only-on-primary = true;
      check-alive-timeout = 0; # remove those "... is not responding" popups
      experimental-features = [
        "scale-monitor-framebuffer"
        "xwayland-native-scaling"
        "autoclose-xwayland" # closes xwayland when no clients left
        "kms-modifiers" # needed for HW accel on xwayland using nvidia (prob not needed on optimus though)
        "variable-refresh-rate"
        #"rt-scheduler" # NOTE removed, will cause all the other to be ignored
      ];
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
      automount = false;
      automount-open = false;
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      delay = 500;
      repeat-interval = 30;
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "org.wezfurlong.wezterm.desktop"
        "code.desktop"
        "signal-desktop.desktop"
        "discord.desktop"
        "org.telegram.desktop.desktop"
        "gnome-calculator.desktop"
      ];
      enabled-extensions = (map (extension: extension.extensionUuid) (builtins.filter (x: x ? extensionUuid) config.home.packages)) ++ [
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "places-menu@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
      ];
    };
    "org/gnome/shell/app-switcher" = {
        current-workspace-only = true;
    };
    "org/gnome/desktop/calendar" = {
      show-weekdate = true;
    };
    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim = false; # false isn't taken into account...
      idle-brightness = 100; # 100 means that it stay at whatever is was before
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "suspend";
      sleep-inactive-battery-timeout = 300; # time to sleep on battery 
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
    "org/gnome/shell/keybindings" = {
      toggle-message-tray = ["'<Super>m'"]; # by default there's also '<Super>v' which we use to paste
    };
    "org/gnome/shell/extensions/dash-to-dock" = {
      multi-monitor = true;
    };
    "org/gnome/desktop/wm/preferences" = {
      focus-mode = "sloppy"; # focus on hover
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style = {
      package = pkgs.adwaita-qt;
      name = "adwaita";
    };
  };

}

