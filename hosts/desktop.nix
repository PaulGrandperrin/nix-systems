{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    
  ];

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


  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    media-session.enable = true;
  };



  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
}


