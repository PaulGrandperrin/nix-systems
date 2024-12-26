{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = [
  ];
  services.gvfs.enable = true;

  services.gnome.gnome-browser-connector.enable = true;

  # Workaround https://github.com/NixOS/nixpkgs/issues/336723
  systemd = {
     services."gnome-suspend" = {
      description = "suspend gnome shell";
      before = [
        "systemd-suspend.service" 
        "systemd-hibernate.service"
        "nvidia-suspend.service"
        "nvidia-hibernate.service"
      ];
      wantedBy = [
        "systemd-suspend.service"
        "systemd-hibernate.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''${pkgs.procps}/bin/pkill -f -STOP ${pkgs.gnome-shell}/bin/gnome-shell'';
      };
    };
    services."gnome-resume" = {
      description = "resume gnome shell";
      after = [
        "systemd-suspend.service" 
        "systemd-hibernate.service"
        "nvidia-resume.service"
      ];
      wantedBy = [
        "systemd-suspend.service"
        "systemd-hibernate.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''${pkgs.procps}/bin/pkill -f -CONT ${pkgs.gnome-shell}/bin/gnome-shell'';
      };
    };
  };
}


