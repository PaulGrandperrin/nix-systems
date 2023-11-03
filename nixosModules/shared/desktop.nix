{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./xremap.nix
  ];

  # don't waste time typing password when the user rights already make it possible to read my password manager's memory
  security.sudo.wheelNeedsPassword = false;
  security.please.wheelNeedsPassword = false;
  nix.settings.trusted-users = ["@wheel"];

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

  boot.kernelParams = [
    "quiet"
    #"loglevel=3"
    #"rd.udev.log_level=3"
    #"systemd.show_status=auto"
    #"vga=current"
    #"vt.global_cursor_default=0" 
    #"fbcon.nodefer" # don't use vendor logo
  ];
  boot.plymouth.enable = true;
  boot.plymouth.theme = "spinner";

  time.timeZone = lib.mkForce null; # allow TZ to be set by desktop user

  services.thermald.enable = false; # should be disabled when power-profile-daemon (GNOME or KDE)


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

    # desynchronize mouse mouvement from desktop composition
    # MUTTER_DEBUG_FORCE_KMS_MODE = "simple";

    # sacrifice a few milliseconds latency in order to gain a smoother frame rate
    #CLUTTER_PAINT = "disable-dynamic-max-render-time";
  };

  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = [
  ];
  services.gvfs.enable = true;

  services.flatpak.enable = true;
  systemd.services.flatpak-remote-add-flathub = {
    requires = ["network-online.target"];
    after = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    description = "Install Flatpak Remote Flathub";
    script = ''
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };

  services.system76-scheduler = {
    enable = true;
  };

  # android
  programs.adb.enable = true;
  users.users.paulg.extraGroups = ["adbusers"];

  hardware.logitech.wireless.enable = true; # includes ltunify
  hardware.logitech.wireless.enableGraphical = true; # includes solaar

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true; # to make realtime scheduling possible in gnome-shell
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

  # should be moved to HM
  sops.secrets."rclone.conf" = {
    sopsFile = ../../secrets/other.yaml;
    restartUnits = [ "home-manager-paulg.service" ];
    path = "/home/paulg/.config/rclone/rclone.conf";
    owner = "paulg";
  };

  sops.secrets."DelPuppo.nmconnection" = {
    restartUnits = [ "NetworkManager.service" ];
    path = "/etc/NetworkManager/system-connections/DelPuppo.nmconnection";
  };

  sops.secrets."Pixel 6 Pro.nmconnection" = {
    restartUnits = [ "NetworkManager.service" ];
    path = "/etc/NetworkManager/system-connections/Pixel 6 Pro.nmconnection";
  };

  sops.secrets."Eero.nmconnection" = {
    restartUnits = [ "NetworkManager.service" ];
    path = "/etc/NetworkManager/system-connections/Eero.nmconnection";
  };

  networking.networkmanager = {
    wifi.scanRandMacAddress = true; # default is true
    wifi.macAddress = "stable"; # default is "preverve"
    ethernet.macAddress = "stable"; # default is "preserve"
    extraConfig = ''
      [connectivity]
      uri=http://nmcheck.gnome.org/check_network_status.txt
    '';
  };

  systemd.network.wait-online = {
    timeout = 5; # waiting 30 seconds is wayyy too long
    #anyInterface = true;
    #extraArgs = ["-i" "wlp2s0"]; # was needed at some point 
  };

  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false; # I just can't deal with this anymore... I don't even understand WHY!?

  #networking.wireless.iwd.enable = true;
  #networking.networkmanager.wifi.backend = "iwd";

  specialisation = {
    "Mitigations_Off" = {
      inheritParentConfig = true; # defaults to true
      configuration = {
        system.nixos.tags = [ "mitigations_off" ];
        boot.kernelParams = [ "mitigations=off" ];
      };
    };
  };

  
}


