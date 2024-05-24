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
}


