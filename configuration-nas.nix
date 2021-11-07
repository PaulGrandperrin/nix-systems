{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #<nixpkgs/nixos/modules/profiles/hardened.nix>
      ./common.nix
      ./nspawns/debian.nix
      ./net.nix
    ];

  networking.hostId="51079489";

  system.stateVersion = "21.05"; # Did you read the comment?
  
  networking.hostName = "nixos-nas";

  services.bridged_net = {
    enable = true;
    mainInt = "enp3s0";
  }; 

}

