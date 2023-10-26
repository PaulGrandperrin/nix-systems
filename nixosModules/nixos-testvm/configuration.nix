{ config, pkgs, lib, inputs, modulesPath, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disk-config.nix
    ../shared/common.nix
    #../shared/net.nix
  ];

  home-manager.users = let
    homeModule = {
      imports = [
        ../../homeModules/shared/core.nix
      ];
    };
  in {
    root  = homeModule;
    paulg = homeModule;
  };

  networking.hostName = "nixos-testvm";
  networking.hostId = "333b699e";

  #services.net = {
  #  enable = true;
  #  mainInt = "enp0s3";
  #}; 
}

