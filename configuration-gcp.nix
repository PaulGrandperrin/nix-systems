{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [
      (modulesPath + "/profiles/headless.nix")
      ./google-compute-config.nix 
      ./hardware-configuration.nix
      ./common.nix
    ];

  networking.hostId = "1c734661"; # for ZFS

  system.stateVersion = "21.05"; # Did you read the comment?
}
