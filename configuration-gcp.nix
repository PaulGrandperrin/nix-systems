{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [
      ./google-compute-config.nix 
      ./hardware-configuration.nix
      ./common.nix
    ];

  networking.hostId = "1c734661"; # for ZFS
  networking.hostName = "nixos-gcp";
  networking.interfaces.eth0.useDHCP = true;
  

  system.stateVersion = "21.05"; # Did you read the comment?

  environment.systemPackages = with pkgs; [
    google-cloud-sdk-gce
  ];
}
