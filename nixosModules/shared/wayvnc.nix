{ pkgs, ... }: {
  # Keep paulg's systemd --user services (labwc, wayvnc) running without an active login
  users.users.paulg = {
    linger = true;
    # Grant headless user session access to /dev/dri/renderD* without a physical TTY seat
    extraGroups = [ "render" "video" ];
  };

  # Basic fonts and GPU drivers for headless GUI app rendering
  fonts.enableDefaultPackages = true;
  hardware.graphics.enable = true;

  home-manager.users.paulg = { pkgs, config, ... }: {
    home.packages = with pkgs; [
      wlr-randr
      wl-clipboard
    ];

    wayland.windowManager.labwc = {
      enable = true;
      xwayland.enable = false;
      # Non-empty environment ensures HM writes ~/.config/labwc/environment with WLR_XWAYLAND=
      environment = [
        "XDG_CURRENT_DESKTOP=labwc:wlroots"
      ];
      autostart = [
        "${pkgs.wlr-randr}/bin/wlr-randr --output HEADLESS-1 --custom-mode 1920x1080@60Hz"
      ];
      rc = {
        keyboard.default = true;
        mouse.default = true;
        windowRules.windowRule = {
          "@identifier" = "firefox";
          action."@name" = "Maximize";
        };
      };
      menu = [
        {
          menuId = "root-menu";
          label = "Menu";
          items = [
            {
              label = "Firefox";
              action = {
                name = "Execute";
                command = "${config.programs.firefox.finalPackage}/bin/firefox-release";
              };
            }
            {
              label = "Kitty";
              action = {
                name = "Execute";
                command = "${pkgs.kitty}/bin/kitty";
              };
            }
            {
              label = "Reconfigure";
              action.name = "Reconfigure";
            }
          ];
        }
      ];
    };

    services.wayvnc = {
      enable = true;
      autoStart = true;
      # Bind only to the WireGuard VPN interface
      settings = {
        address = "10.42.0.1";
        port = 5900;
      };
    };

    systemd.user.services.labwc-headless = {
      Unit = {
        Description = "Headless labwc Wayland compositor";
        After = [ "dbus.service" ];
      };
      Service = {
        Type = "simple";
        UnsetEnvironment = [ "WAYLAND_DISPLAY" "DISPLAY" ];
        Environment = [
          "WLR_BACKENDS=headless"
          "WLR_LIBINPUT_NO_DEVICES=1"
        ];
        ExecStart = "${pkgs.labwc}/bin/labwc";
        ExecStopPost = "-${pkgs.systemd}/bin/systemctl --user stop labwc-session.target";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services.wayvnc = {
      # Allow retries at boot until wg0 has its IP assigned
      Unit.StartLimitIntervalSec = 0;
      Service = {
        # Pin to labwc's socket so gnome-headless setting WAYLAND_DISPLAY=gnome-0 doesn't hijack wayvnc
        Environment = [ "WAYLAND_DISPLAY=wayland-0" ];
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
