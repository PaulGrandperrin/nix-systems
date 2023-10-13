{pkgs, inputs, lib, config, system, ...}: lib.mkIf (config.home.username != "root") {
  home = {
    packages = with pkgs; [
      gnome.gnome-tweaks

      #gnomeExtensions.sound-output-device-chooser # incomp
      gnomeExtensions.bluetooth-quick-connect
      #gnomeExtensions.gsconnect
      gnomeExtensions.blur-my-shell
      #gnomeExtensions.pixel-saver # incomp
      #gnomeExtensions.floating-dock # incomp
      gnomeExtensions.emoji-selector
      gnomeExtensions.clipboard-indicator
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
      stable.gnomeExtensions.focus-indicator
      #gnomeExtensions.desktop-cube
      #gnomeExtensions.pop-shell

      unstable.gnomeExtensions.system76-scheduler
      #wintile?

      gnome.dconf-editor
      gnome-console
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
    };
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" "rt-scheduler" ];
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
        "firefox.desktop"
        "terminator.desktop"
        "org.gnome.Nautilus.desktop"
        "code.desktop"
        "signal-desktop.desktop"
      ];
      enabled-extensions = (map (extension: extension.extensionUuid) (builtins.filter (x: x ? extensionUuid) config.home.packages)) ++ [
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "places-menu@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
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
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = {
      package = pkgs.adwaita-qt;
      name = "adwaita";
    };
  };

}

