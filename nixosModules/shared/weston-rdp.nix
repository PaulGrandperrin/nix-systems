{ pkgs, lib, ... }: {
  # Keep paulg's systemd --user service running without an active login
  users.users.paulg = {
    linger = true;
    extraGroups = [ "render" "video" ];
  };

  fonts.enableDefaultPackages = true;
  hardware.graphics.enable = true;

  home-manager.users.paulg = { pkgs, config, ... }: let
    certScript = pkgs.writeShellScript "weston-rdp-cert" ''
      dir="$HOME/.local/share/weston-rdp"
      mkdir -p "$dir"
      if [ ! -s "$dir/tls.key" ] || [ ! -s "$dir/tls.crt" ]; then
        ${pkgs.openssl}/bin/openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
          -subj "/CN=nixos-nas.wg" \
          -keyout "$dir/tls.key" \
          -out "$dir/tls.crt"
        chmod 600 "$dir/tls.key"
      fi
    '';
  in {
    xdg.configFile."weston-rdp.ini".text = ''
      [core]
      idle-time=0

      [shell]
      background-color=0xff282c34
      locking=false

      [launcher]
      icon=${pkgs.weston}/share/weston/icon_window.png
      displayname=Firefox
      path=${config.programs.firefox.finalPackage}/bin/firefox

      [launcher]
      icon=${pkgs.weston}/share/weston/icon_terminal.png
      displayname=Kitty
      path=${pkgs.kitty}/bin/kitty
    '';

    systemd.user.services.weston-rdp = {
      Unit = {
        Description = "Headless Weston RDP Wayland compositor";
        After = [ "dbus.service" ];
        # Allow retries at boot until wg0 has 10.42.0.1 assigned
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "simple";
        ExecStartPre = "${certScript}";
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.weston}/bin/weston"
          "--backend=rdp"
          "--socket=weston-0"
          "--address=10.42.0.1"
          "--port=3389"
          "--width=1920"
          "--height=1080"
          "--idle-time=0"
          "--config=%h/.config/weston-rdp.ini"
          "--rdp-tls-cert=%h/.local/share/weston-rdp/tls.crt"
          "--rdp-tls-key=%h/.local/share/weston-rdp/tls.key"
        ];
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
