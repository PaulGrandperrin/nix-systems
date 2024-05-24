{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;
  programs.dconf.enable = true;
  networking.networkmanager.enable = true;
}


