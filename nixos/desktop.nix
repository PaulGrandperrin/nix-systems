{ config, pkgs, system, inputs, ... }:
{

  #nixpkgs.overlays = [
  #  (self: super: {
  #    gnome = super.gnome.overrideScope' (gself: gsuper: {
  #      mutter = gsuper.mutter.overrideAttrs (old: rec {
  #        version = "41.99";
  #        src = super.fetchFromGitHub {
  #          owner = "GNOME";
  #          repo = "mutter";
  #          rev = "75d8fedcf5cac169af1a8912819672c94083831b";
  #          sha256 = "9nw0kJxlsTGPKl30FoYnnlVTTO1BXLS9hHQj8+40Qkg=";
  #          #sha256 = super.lib.fakeSha256;
  #        };
  #      });
  #    });
  #  })
  #];

  environment.systemPackages = with pkgs; [
    solaar
    gnomeExtensions.sound-output-device-chooser
    #gnomeExtensions.bluetooth-battery # incompatible with 41
    gnomeExtensions.bluetooth-quick-connect
    gnomeExtensions.gsconnect
    gnomeExtensions.blur-my-shell
    gnomeExtensions.pixel-saver
    gnomeExtensions.floating-dock
    gnomeExtensions.emoji-selector
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.drop-down-terminal
    gnomeExtensions.ddterm
    gnomeExtensions.coverflow-alt-tab
    gnomeExtensions.dash-to-dock
    gnomeExtensions.dash-to-panel
    inputs.nixos-unstable.legacyPackages.${system}.gnomeExtensions.desktop-cube
    #wintile?
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

  fonts = {
    fontDir.enable = true;
    enableDefaultFonts = true;
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
    ];

    fontconfig = {
      enable = true;
      defaultFonts.monospace = [ "FiraCode Nerd Font Mono" ];
    };
  };



  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
}


