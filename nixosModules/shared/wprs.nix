{ pkgs, ... }: {
  # Keep paulg's systemd --user services (wprsd + remote apps) running without an active login
  users.users.paulg.linger = true;

  # Basic fonts for headless GUI app rendering
  fonts.enableDefaultPackages = true;

  # Expose wprs in /run/current-system/sw/bin for non-interactive SSH sessions
  environment.systemPackages = [ pkgs.wprs ];

  home-manager.users.paulg = { pkgs, ... }: {
    systemd.user.services.wprsd = {
      Unit = {
        Description = "wprsd persistent headless Wayland compositor";
        After = [ "dbus.service" ];
      };
      Service = {
        Type = "simple";
        # Disable XWayland (pure Wayland); enabling it requires pkgs.xwayland in PATH.
        ExecStart = "${pkgs.wprs}/bin/wprsd --enable-xwayland=false";
        Environment = [
          "RUST_BACKTRACE=1"
        ];
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
