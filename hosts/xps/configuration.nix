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

  # HACK fixes autologin when on wayland https://github.com/NixOS/nixpkgs/issues/103746
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.xserver.displayManager = {
    gdm = { # impossible to make it work with prime.sync, use lightdm for that
      enable = true;
      wayland = true;
      #debug = true;
      nvidiaWayland = true; # remove the udev rules which disables wayland when the nvidia driver is loaded
    };
    #lightdm = { # does not work with gnome-shell's lock screen but works with prime.sync
    #  enable = true;
    #};
    autoLogin = { # when using wayland, needs the tty disabling hack
      enable = true;
      user = "paulg";
    };
    #defaultSession = "gnome"; # gnome (gnome-wayland) or gnome-xorg
  };


  environment.sessionVariables = {
    #"XDG_SESSION_TYPE" = "wayland"; # absolutly force wayland
  };

  services.xserver.desktopManager.gnome.enable = true;
  services.gnome.chrome-gnome-shell.enable = true; # BUG: not working...
  services.gnome.experimental-features.realtime-scheduling = true; # breaks some environment vars

  services.xserver.videoDrivers = ["nvidia" ]; # TODO try alone, without hardware.nvidia
  hardware.nvidia = { # TODO try alone
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    modesetting.enable = true; # prime.offload already does it and prime.sync needs it
    nvidiaPersistenced = true; # ensures /sys/class/drm/card0 is nvidia card, and so /dev/nvidia0 is created
    prime = {
      offload.enable = true; # enables nvidia-drm.modeset just like modesetting.enable
      #sync.enable = true; #  needs modesetting.enable
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

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


