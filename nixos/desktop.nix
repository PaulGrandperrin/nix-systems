{ config, pkgs, lib, system, inputs, ... }:
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

  time.timeZone = lib.mkForce null; # allow TZ to be set by desktop user

  environment.systemPackages = with pkgs; [
    stockfish
    solaar
    gnomeExtensions.sound-output-device-chooser
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
    gnomeExtensions.appindicator
    gnomeExtensions.bluetooth-battery
    gnomeExtensions.desktop-cube
    gnomeExtensions.pop-shell
    gnomeExtensions.system76-scheduler
    #wintile?
  ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # HACK fixes autologin when on wayland https://github.com/NixOS/nixpkgs/issues/103746
  #systemd.services."getty@tty1".enable = false;
  #systemd.services."autovt@tty1".enable = false;

  services.xserver.displayManager = {
    gdm = { # impossible to make it work with prime.sync, use lightdm for that
      enable = true;
      wayland = true;
      #debug = true;
    };
    #lightdm = { # does not work with gnome-shell's lock screen but works with prime.sync
    #  enable = true;
    #};
    #autoLogin = { # when using wayland, needs the tty disabling hack
    #  enable = true;
    #  user = "paulg";
    #};
    #defaultSession = "gnome"; # gnome (gnome-wayland) or gnome-xorg
  };


  environment.sessionVariables = {
    #XDG_SESSION_TYPE = "wayland"; # absolutly force wayland
    #QT_QPA_PLATFORM = "wayland";
  };

  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = [
  ];
  services.gnome.games.enable = true;
  services.gvfs.enable = true;

  # android
  programs.adb.enable = true;
  users.users.paulg.extraGroups = ["adbusers"];

  programs.steam.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  systemd.user.services.pipewire-pulse.path = [ pkgs.pulseaudio ]; # HACK waiting for #165125

  hardware.bluetooth.package = pkgs.bluez5-experimental;


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


  networking.firewall.allowedUDPPorts = [
    6970 # RTP for VLC
  ];

  home-manager.users.paulg.home.file.".config/vlc/vlcrc".text = ''
    [core]
    metadata-network-access=1

    [qt]
    qt-privacy-ask=0

    [live555] # RTP/RTSP/SDP demuxer (using Live555)
    # Client port (integer)
    rtp-client-port=6970
  '';


  #networking.wireless.iwd.enable = true;
  #networking.networkmanager.wifi.backend = "iwd";

  # printing
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      gutenprintBin
      hplip
      samsung-unified-linux-driver
      splix
      brlaser
      brgenml1lpr
      brgenml1cupswrapper
      cnijfilter2
    ];
  };

  sops.secrets."DelPuppo.nmconnection" = {
    restartUnits = [ "NetworkManager.service" ];
    path = "/etc/NetworkManager/system-connections/DelPuppo.nmconnection";
  };

  sops.secrets."Pixel 6 Pro.nmconnection" = {
    restartUnits = [ "NetworkManager.service" ];
    path = "/etc/NetworkManager/system-connections/Pixel 6 Pro.nmconnection";
  };
  
}


