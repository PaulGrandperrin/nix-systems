{ pkgs, lib, ... }: {
  users.users.paulg = {
    linger = true;
    extraGroups = [ "render" "video" ];
  };

  fonts.enableDefaultPackages = true;
  hardware.graphics.enable = true;

  # Enables pipewire, polkit, dbus packages, and installs grdctl/gnome-remote-desktop
  services.gnome.gnome-remote-desktop.enable = true;
  services.pipewire.pulse.enable = true;
  services.gnome.gnome-settings-daemon.enable = true;
  services.gvfs.enable = true;
  programs.dconf.enable = true;
  security.rtkit.enable = true;

  xdg.mime.enable = true;
  xdg.icons.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.common.default = lib.mkDefault "gnome";
  };

  services.udev.packages = [ pkgs.mutter ];
  environment.pathsToLink = [ "/share" ];
  environment.systemPackages = with pkgs; [
    gnome-shell
    gnome-control-center
    gnome-backgrounds
    adwaita-icon-theme
  ];

  home-manager.users.paulg = { pkgs, ... }: let
    setupScript = pkgs.writeShellScript "gnome-rdp-setup" ''
      dir="$HOME/.local/share/gnome-remote-desktop"
      mkdir -p "$dir"
      if [ ! -s "$dir/rdp-tls.key" ] || [ ! -s "$dir/rdp-tls.crt" ]; then
        ${pkgs.openssl}/bin/openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
          -subj "/CN=nixos-nas.wg" \
          -keyout "$dir/rdp-tls.key" \
          -out "$dir/rdp-tls.crt"
        chmod 600 "$dir/rdp-tls.key"
      fi

      grdctl="${pkgs.gnome-remote-desktop}/bin/grdctl --headless"
      # Port 3390 avoids colliding with weston-rdp on 3389
      $grdctl rdp set-port 3390
      $grdctl rdp disable-port-negotiation
      $grdctl rdp disable-view-only
      $grdctl rdp set-tls-cert "$dir/rdp-tls.crt"
      $grdctl rdp set-tls-key "$dir/rdp-tls.key"
      $grdctl rdp set-auth-methods credentials
      $grdctl rdp enable
    '';
  in {
    systemd.user.services.gnome-headless = {
      Unit = {
        Description = "Headless GNOME Shell Wayland compositor";
        After = [ "dbus.service" "pipewire.service" "wireplumber.service" ];
      };
      Service = {
        Type = "simple";
        UnsetEnvironment = [ "WAYLAND_DISPLAY" "DISPLAY" ];
        Environment = [
          "XDG_SESSION_TYPE=wayland"
          "XDG_CURRENT_DESKTOP=GNOME"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.gnome-shell}/bin/gnome-shell"
          "--headless"
          "--no-x11"
          "--wayland-display=gnome-0"
        ];
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services.gnome-remote-desktop-headless = {
      Unit = {
        Description = "GNOME Remote Desktop (headless)";
        After = [ "gnome-headless.service" "pipewire.service" "wireplumber.service" ];
        Requires = [ "gnome-headless.service" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.gnome.RemoteDesktop.Headless";
        ExecStartPre = "${setupScript}";
        ExecStart = "${pkgs.gnome-remote-desktop}/libexec/gnome-remote-desktop-daemon --headless";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
