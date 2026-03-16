{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  #services.displayManager.plasma-login-manager.enable = lib.mkDefault true; # TODO not available on 25.11 yet
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;
  programs.dconf.enable = true;
  networking.networkmanager.enable = true;
}


