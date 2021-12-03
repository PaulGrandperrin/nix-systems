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

  # HACK fixes autologin https://github.com/NixOS/nixpkgs/issues/103746
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.xserver.displayManager = {
    gdm = {
      enable = true;
      wayland = true;
      #debug = true;
      #nvidiaWayland = true; 
    };
    #lightdm = {
    #  enable = true;
    #};
    autoLogin = { # boot is already protected by ZFS encryption
      enable = true;
      user = "paulg";
    };
    defaultSession = "gnome"; # means gnome-wayland
  };

  #environment.sessionVariables = {
  #  "XDG_SESSION_TYPE" = "wayland";
  #};

  services.xserver.desktopManager.gnome.enable = true;
  services.gnome.chrome-gnome-shell.enable = true; # BUG: not working...
  services.gnome.experimental-features.realtime-scheduling = true; # breaks some environment vars

  #services.xserver.videoDrivers = [ "nvidia" ]; # alone, breaks everything
  #hardware.nvidia = { # alone, doesn't prevent wayland
  #  #powerManagement.enable = true;
  #  #modesetting.enable = true;
  #  #nvidiaPersistenced.enable = false;
  #  prime = {
  #    offload.enable = true;
  #    intelBusId = "PCI:0:2:0";
  #    nvidiaBusId = "PCI:1:0:0";
  #  };
  #};

   environment.systemPackages = with pkgs; [
     # nvidia-offload
     (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec -a "$0" "$@"
    '')
   ];

  

}


