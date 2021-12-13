{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #<nixpkgs/nixos/modules/profiles/hardened.nix>
      ../../common.nix
      ../../net.nix
      ../../laptop.nix
      ../../desktop.nix
      ../../desktop-nvidia-prime.nix
    ];

  networking.hostId="7ee1da4a";

  system.stateVersion = "21.11"; # Did you read the comment?
  
  networking.hostName = "nixos-xps";

  services.net = {
    enable = true;
    mainInt = "wlp2s0";
  }; 
  #


  

}


