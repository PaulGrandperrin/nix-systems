{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./xremap.nix
  ];

  # don't waste time typing password when the user rights already make it possible to read my password manager's memory
  security.sudo.wheelNeedsPassword = false;
  security.sudo-rs.wheelNeedsPassword = false;
  security.please.wheelNeedsPassword = false;
  nix.settings.trusted-users = ["@wheel"];

  #nixpkgs.overlays = [
  #  (self: super: {
  #    gnome = super.gnome.overrideScope (gself: gsuper: {
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

  boot.consoleLogLevel = 2;
  boot.kernelParams = [
    "quiet"
    "vga=current" # might help to get a silent boot
    #"console=tty12" # don't show kernel text
    #"rd.udev.log_level=3" # disable systemd printing its version number
    #"systemd.show_status=auto" # only show errors
    #"systemd.loglevel=0"
    #"vt.global_cursor_default=0" # remove console cursor blinking
    #"fbcon.nodefer" # don't use vendor logo
  ];
  boot.plymouth.enable = true;
  boot.plymouth.theme = "spinner";
  boot.loader.timeout = 0; # hides menu but can be shown by pressing and hilding key at boot

  time.timeZone = lib.mkForce null; # allow TZ to be set by desktop user

  services.thermald.enable = false; # should be disabled when power-profile-daemon (GNOME or KDE)

  # HACK fixes autologin when on wayland https://github.com/NixOS/nixpkgs/issues/103746
  #systemd.services."getty@tty1".enable = false;
  #systemd.services."autovt@tty1".enable = false;

  # one must be choosen otherwise we get a conflict of default vealues when selecting multiple desktops
  programs.ssh.askPassword = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";

  services.systemd-lock-handler.enable = true; # TODO maybe run some housekeeping tasks

  services.xserver.displayManager = {
    gdm = { # gdm, ssdm, lightdm, cosmic-greeter
      enable = true;
      wayland = true;
      #wayland.enable = true;
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

  services.flatpak.enable = true;
  xdg.portal = {
    enable = true; # required for flatpak
    #extraPortals = with pkgs; [
    #  xdg-desktop-portal-gtk
    #];
  };
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
    exceptions = [
      "include descends=\"schedtool\""
      "schedtool"
    ];
    assignments = {
      nix-builds = {
        nice = 15;
        class = "batch";
        ioClass = "idle";
        matchers = [
          "nix-daemon"
        ];
      };
    };
  };

  # android
  programs.adb.enable = true;
  users.users.paulg.extraGroups = ["adbusers"];

  hardware.logitech.wireless.enable = true; # includes ltunify
  hardware.logitech.wireless.enableGraphical = true; # includes solaar
  services.ratbagd.enable = true; # gaming mouse
  environment.systemPackages = with pkgs; [
    piper # gtk interface to ratbagd
  ];

  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # to make realtime scheduling possible in gnome-shell
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
  };

  hardware.bluetooth.package = pkgs.bluez-experimental; # enables experimental features, not experimental version


  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.fira-code
    ];

    fontconfig = {
      enable = true;
      defaultFonts.monospace = [ "FiraCode Nerd Font Mono" ];
    };
  };

  networking.firewall.allowedUDPPorts = [
    6970 # RTP for VLC
  ];

  home-manager.users.paulg.xdg.configFile."vlc/vlcrc".text = ''
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
      #samsung-unified-linux-driver #  2024-11 fails to build
      splix
      brlaser
      brgenml1lpr
      brgenml1cupswrapper
      cnijfilter2
    ];
  };

  sops.secrets."rclone.conf" = {
    sopsFile = ../../secrets/other.yaml;
    restartUnits = [ "home-manager-paulg.service" ];
    owner = "paulg";
    # we don't define the final path here because if the parent directory doesn't exist yet ($HOME/.config), it'll create it with root ownership, breaking the session.
  };
  # HM will create $HOME.config with the correct owner
  home-manager.users.paulg.xdg.configFile."rclone/rclone.conf".source = config.home-manager.users.paulg.lib.file.mkOutOfStoreSymlink config.sops.secrets."rclone.conf".path;

  sops.secrets."DelPuppo Guest.nmconnection" = {
    restartUnits = [ "NetworkManager.service" ];
    path = "/etc/NetworkManager/system-connections/DelPuppo Guest.nmconnection";
  };

  sops.secrets."DelPuppo Private.nmconnection" = {
    restartUnits = [ "NetworkManager.service" ];
    path = "/etc/NetworkManager/system-connections/DelPuppo Private.nmconnection";
  };

  sops.secrets."DelPuppo 5GHz.nmconnection" = {
    restartUnits = [ "NetworkManager.service" ];
    path = "/etc/NetworkManager/system-connections/DelPuppo 5GHz.nmconnection";
  };

  sops.secrets."Pixel 7 Pro.nmconnection" = {
    restartUnits = [ "NetworkManager.service" ];
    path = "/etc/NetworkManager/system-connections/Pixel 7 Pro.nmconnection";
  };

  sops.secrets."Eero.nmconnection" = {
    restartUnits = [ "NetworkManager.service" ];
    path = "/etc/NetworkManager/system-connections/Eero.nmconnection";
  };

  networking.networkmanager = {
    wifi.scanRandMacAddress = true; # default is true
    wifi.macAddress = "stable"; # default is "preverve"
    ethernet.macAddress = "stable"; # default is "preserve"
    settings.connectivity.uri = "http://nmcheck.gnome.org/check_network_status.txt";
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


