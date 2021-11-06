{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [
      ./google-compute-config.nix 
      ./hardware-configuration.nix
      ./common.nix
    ];

  networking.hostId = "1c734661"; # for ZFS

  system.stateVersion = "21.05"; # Did you read the comment?
}
