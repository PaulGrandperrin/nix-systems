{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../shared/common.nix
    ../shared/net.nix
    ../shared/auto-upgrade.nix
    ../shared/headless.nix
    #../shared/home-assistant.nix
  ];

  home-manager.users = let 
    homeModule = {
      imports = [
        ../../homeModules/shared/core.nix
        #../../homeModules/shared/cmdline-extra.nix
      ];
    };
  in {
    root  = homeModule;
    paulg = homeModule;
  };

  networking.hostId="562a7fab";
  networking.hostName = "nixos-chromebox";
  #services.net = {
  #  enable = true;
  #  mainInt = "enp3s0";
  #}; 

  #services.my-wg = {
  #  enable = true;
  #};
}

