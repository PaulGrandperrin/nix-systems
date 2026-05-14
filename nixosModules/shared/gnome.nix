{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  services.displayManager.gdm.enable = lib.mkDefault true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = [
  ];
  services.gvfs.enable = true;

  services.gnome.gnome-browser-connector.enable = true;

  # Gnome shell extensions:
  services.desktopManager.gnome.sessionPath = [];
}


