{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #<nixpkgs/nixos/modules/profiles/hardened.nix>
      ../../common.nix
      ../nspawns/debian.nix
      ../containers/web.nix
      ../../net.nix
    ];

  networking.hostId="51079489";

  system.stateVersion = "21.05"; # Did you read the comment?
  
  networking.hostName = "nixos-nas";

  services.net = {
    enable = true;
    mainInt = "enp3s0";
  }; 

}

