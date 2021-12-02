{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #<nixpkgs/nixos/modules/profiles/hardened.nix>
      ../../common.nix
      ../../net.nix
    ];

  networking.hostId="7ee1da4a";

  system.stateVersion = "21.11"; # Did you read the comment?
  
  networking.hostName = "nixos-xps";

  services.net = {
    enable = true;
    mainInt = "wlp2s0";
  }; 
  #
  # Enable the X11 windowing system.
  services.xserver.enable = true;


  # Enable the GNOME Desktop Environment.
  #services.xserver.displayManager.sddm.enable = true;
  #services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

   environment.systemPackages = with pkgs; [
     
   ];

}


