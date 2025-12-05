{ config, pkgs, lib, inputs, home-manager-flake, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    #(inputs.nixos-unstable + "/nixos/modules/programs/nh.nix")
    home-manager-flake.nixosModules.home-manager
    #inputs.dwarffs.nixosModules.dwarffs # broken..
    ./mail.nix
    ./sysdig.nix
  ];
  system.stateVersion = "25.05";

  #systemd.enableStrictShellChecks = true; # TODO

  nixpkgs = {
    config = import ../../nixpkgs/config.nix;
    overlays = [
      (import ../../overlays.nix inputs).default
    ];
  };

  home-manager = {
    useGlobalPkgs = true; # means that pkgs are taken from the nixosSystem and not from home-manager.inputs.nixpkgs
    useUserPackages = true; # means that pkgs are installed at /etc/profiles instead of $HOME/.nix-profile
    extraSpecialArgs = config._module.specialArgs;
  };
  
  environment.etc = {
    "nix/source-flake".source = ../../.; # always keep a reference to the source flake that generated each generations
  } // (lib.mapAttrs' # keep inputs too, from flake-utils-plus
    (name: value: { name = "nix/inputs/${name}"; value = { source = value.outPath; }; })
    inputs
  );


  boot.supportedFilesystems = {
    ext4 = true;
    btrfs = true;
    exfat = true;
    ntfs = true;
  };

  sops = {
    defaultSopsFile = ../../secrets/common.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]; # default
    gnupg.sshKeyPaths = []; # we don't use it and if the file doesn't exist, the whole process fails: https://github.com/Mic92/sops-nix/issues/427
  };

  # deploy our github public access token everywhere to avoid API rate limitations
  sops.secrets.github-public-access-token = {
    mode = "0440";
    owner = "root";
    group = "wheel";
    restartUnits = [ "nix-daemon.service" ];
  };
  environment.sessionVariables = {
    NIX_USER_CONF_FILES = config.sops.secrets.github-public-access-token.path; 
    ENVFS_RESOLVE_ALWAYS = "1";
    NH_OS_FLAKE = "/etc/nixos";
  };

  security.pam.loginLimits = [{ # equivalent to ulimit -Hn 10485760
    domain = "*";
    type = "hard";
    item = "nofile";
    value = 10485760;
  }];

  # Hardening
  # TODO: noexec mounts, tmpfs...
  environment.defaultPackages = lib.mkForce [];

  security.acme.acceptTerms = true;
  #security.acme.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
  security.acme.defaults.email = "paul.grandperrin@gmail.com";

  nix = {
    settings = import ../../nix/nix.nix;
    package = pkgs.lix;
    channel.enable = false;
    #gc = {
    #  automatic = true;
    #  persistent = true;
    #  dates = "05:00:00";
    #  options = "--delete-older-than 7d";
    #};
  };

  programs.nh = {
    enable = true;
    package = pkgs.unstable.nh;
    flake = "/etc/nixos/";
    clean = {
      enable = true;
      dates = "05:00:00";
      extraArgs = "--keep-since 3d --keep 2 --nogcroots";
    };
  };

  nix.optimise = {
    automatic = true;
    dates = ["06:00:00"];
  };
  
  security = {
    sudo = {
      enable = false;
      execWheelOnly = true;
    };
    sudo-rs = {
      enable = true;
      execWheelOnly = true;
    };
    please = {
      #enable = true;
    };

    wrappers.su.source = lib.mkForce "${pkgs.sudo-rs}/bin/su";
  };

  hardware.enableAllFirmware = true;
  services.fwupd.enable = true;

  documentation = {
    man = {
      man-db.enable = false;
      mandoc.enable = true;
    };
    dev.enable = true;
    #nixos.includeAllModules = true;
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  services.envfs.enable = true; # populate /usr/bin for non-nix binaries
  programs.nix-ld = { # create a link-loader for non-nix binaries
    enable = true;
    libraries = with pkgs; [
      libpng libbsd # android emulator
      libsForQt5.qt5.qtbase # switch emulator

      # from https://github.com/Mic92/dotfiles/blob/main/nixos/modules/nix-ld.nix
      stdenv.cc.cc
      fuse3
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      curl
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libGL
      libappindicator-gtk3
      libdrm
      libnotify
      libpulseaudio
      libuuid
      libusb1
      xorg.libxcb
      libxkbcommon
      mesa
      nspr
      nss
      pango
      pipewire
      systemd
      icu
      openssl
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      xorg.libxkbfile
      xorg.libxshmfence
      zlib
    ];
  };

  # those machines can easily deploy closures to all nixos machines
  users.users.root.openssh.authorizedKeys.keys = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOIxgOXuz4/8JB++umc4fEvFwIlM3eeVadTsvCZCQN2" # root@nixos-xps
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMK/GnaGGlU7pl4po31XP6K5VpodTu67J+D1/3d74R57" # root@nixos-macbook
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB6gqM1jzgCAtgFYK9nRteimmbulWMuWlW0WvdJK52uy" # root@nixos-asus
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") true;
  services.fstrim = {
    enable = true;
    interval = "07:00:00";
  };
  boot.kernelParams = [
    #"ipv6.disable=1"
    "nosgx"
    #"iommu=pt"
    "intel_iommu=on"
    "amd_iommu=on"
    "efi=disable_early_pci_dma"
    #"init_on_alloc=1"
    #"init_on_free=1"
    #"page_alloc.shuffle=1"
    "systemd.gpt_auto=no" # fails on OCI otherwise
    "sysrq_always_enabled=1" # works even in the initramfs
  ];

  # to bisect kernel
  #boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_6_1.override { # (#4)
  #  argsOverride = rec {
  #    src = pkgs.fetchFromGitHub {
  #      owner = "gregkh";
  #      repo = "linux";
  #      # (#1) -> put the bisect revision here
  #      rev = "f11a26633eb6d3bb24a10b1bacc4e4a9b0c6389f";
  #      # (#2) -> clear the sha; run a build, get the sha, populate the sha
  #      sha256 = "sha256-7Ep9/ScE+Ix8DRAjUiIUuBFKIuBlmBkDXP8EA9cNFmQ=";
  #    };
  #    dontStrip = true;
  #    # (#3) `head Makefile` from the kernel and put the right version numbers here
  #    version = "6.1.45";
  #    modDirVersion = "6.1.45";
  #  };
  #});
  

  # tried to use ccache
  #programs.ccache.enable = false;
  #programs.ccache.cacheDir = "/opt/ccache";
  #programs.ccache.packageNames = [ "linuxPackages_6_1.kernel" ];
  #nix.settings.extra-sandbox-paths = [ "/opt/ccache" ];
  #
  #nixpkgs.overlays = [
  #  (self: prev: {
  #    kernel_cache = (prev.linuxPackages_6_1.kernel.override {
  #      stdenv = self.ccacheStdenv;
  #      buildPackages = prev.buildPackages // {
  #        stdenv = self.ccacheStdenv;
  #      };
  #    }).overrideDerivation (attrs: {
  #      preConfigure = ''
  #        export NIX_CFLAGS_COMPILE="$(echo "$NIX_CFLAGS_COMPILE" | sed -e "s/-frandom-seed=[^-]*//")"
  #      '';
  #    });
  #  })
  #];

  services.smartd = {
    enable = true;
    extraOptions = [ "-q errors,nodev0" ]; # Exit sucessfully if there are no devices to monitor and unsucessfully if any errors are found in the configuration file
    notifications.mail.enable = true;
    defaults.monitored = 
        "-a " # monitor all attributes
      + "-o on " # enable automatic offline data collection
      + "-S on " # enable automatic attribute autosave
      + "-n standby,q " # do not check if disk is in standby, and suppress log message to that effect so as not to cause a write to disk
      + "-s (S/../.././02|L/../0[1-7]/4/02) " # schedule short self-test every day at 2AM, long self-test every months the first thursday at 2AM
      + "-W 4,50,55 " # monitor temperature, 4C Diff, 35 Info, 40 Crit
      ;
  };

  ## way too long to build
  #boot.kernelPatches = [{
  #  name = "custom";
  #  patch = null;
  #  extraConfig = ''
  #    PANIC_ON_OOPS y
  #    FORTIFY_SOURCE y
  #  '';
  #}];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd = {
    enable = true;
    emergencyAccess = lib.mkDefault true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_DK.UTF-8"; # means ISO-8601
      LC_MEASUREMENT = "en_DK.UTF-8"; # means metric
      LC_MONETARY = "fr_FR.UTF-8"; # means Euro
    };
  };

  boot.kernel.sysctl = {
   "kernel.sysrq" = 1; # magic keyboard shortcuts
   "vm.nr_hugepages" = lib.mkDefault "0"; # disabled is better for DBs
   #"vm.overcommit_memory" = "1";
   "fs.inotify.max_user_watches" = 2000000; # https://code.visualstudio.com/docs/setup/linux#_visual-studio-code-is-unable-to-watch-for-file-changes-in-this-large-workspace-error-enospc

   # game fix: https://www.phoronix.com/news/Fedora-39-VM-Max-Map-Count
   "vm.max_map_count" = 2147483642;

   # Fix unresponsive IO on slow devices: https://lwn.net/Articles/572911/
   "vm.dirty_bytes" = 268435456;
   "vm.dirty_background_bytes" = 134217728;

   # values for zwap inspired by arch and popos
   "vm.swappiness" = 180; # default 60, between 0 to 100. 0 means try to not swap
   "vm.watermark_boost_factor" = 0;
   "vm.watermark_scale_factor" = 125;
   "vm.page-cluster" = 1; # 0 for zstd, 1 for speedier algos

   "vm.vfs_cache_pressure" = 500; # default 100, recommended between 50 to 500. This variable controls the tendency of the kernel to reclaim the memory which is used for caching of VFS caches, versus pagecache and swap. Increasing this value increases the rate at which VFS caches are reclaimed.
  };

  boot.tmp.cleanOnBoot = true;



  services.irqbalance.enable = true;

  programs.fish = {
    enable = true;
    useBabelfish = false;
  };

  programs.command-not-found.enable = false; # disable because it uses channels and we use nix-index instead

  users.mutableUsers = false;

  sops.secrets.password-root.neededForUsers = true;
  sops.secrets.password-paulg.neededForUsers = true;

  users.users.root = {
    hashedPasswordFile = config.sops.secrets.password-root.path;
    shell = pkgs.fish;
  };

  users.users.paulg = {
    isNormalUser = true;
    description = "Paul Grandperrin";
    hashedPasswordFile = config.sops.secrets.password-paulg.path;
    extraGroups = [
      "wheel"
      "networkmanager" # no need for password
      #"audio" # used by JACK for realtime, otherwise not needed on systemd. Not recommended https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture#User_privileges
      "input" # manage controllers
      "kvm" # access to /dev/kvm but doesn't seem to be needed. thanks to uaccess? but maybe it's need for android emulator
      "podman" # allow access to docker socket
      # "libvirtd" # doesn't seem to be necessary
    ];
    uid = 1000;
    useDefaultShell = true;
    createHome = true;
    home = "/home/paulg";
    shell = pkgs.fish;
  };

  #nix.buildMachines = [{
  #  hostName = "builder";
  #  systems = ["x86_64-linux" "x86_64-darwin"];
  #  maxJobs = 1;
  #  speedFactor = 2;
  #  supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  #  mandatoryFeatures = [ ];
  #}];
  #nix.distributedBuilds = true;
  ## optional, useful when the builder has a faster internet connection than yours
  ##nix.extraOptions = ''
  ##  builders-use-substitutes = true
  ##'';

  # expose HW MAC addresses for WOL
  sops.secrets.hwmac-nas = {};

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    busybox-sandbox-shell
    (writeShellApplication {
      name = "wakelan-nas";
      text = ''
        ${wakelan}/bin/wakelan -p9 -b nas.grandperrin.fr -m "$(cat ${config.sops.secrets.hwmac-nas.path})"
        # also send locally because sending on the internet from the same network doesn't work
        ${wakelan}/bin/wakelan -p9 -m "$(cat ${config.sops.secrets.hwmac-nas.path})"
      '';
    })
  ];

  zramSwap = {
    enable = true;
    algorithm = "lz4"; # https://www.reddit.com/r/Fedora/comments/mzun99/comment/h1cnvv3/?utm_source=share&utm_medium=web2x&context=3
    priority = 5;
    memoryPercent = 100;
  };

  systemd.oomd = {
    enable = true;
    enableRootSlice = false;
    enableSystemSlice = false;
    enableUserSlices = true;
    settings = {
      OOM.DefaultMemoryPressureDurationSec = "5s";
    };
  };

  # List services that you want to enable:

  services.gpm.enable = false;
  services.thermald.enable = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (lib.mkDefault true); # should be disabled when power-profile-daemon (GNOME or KDE) or throttled is enabled

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkForce true;
      PermitRootLogin = lib.mkForce "yes";
    };
  };

  # give nix-daemon the lowest priority 
  nix = {
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedPriority = 7; # only used by "best-effort"
  };

  virtualisation = {
    #libvirtd.enable = true;
    oci-containers.backend = "podman";
    podman = {
      #enable = true;
      autoPrune = {
        enable = true;
        dates = "04:30:00";
        flags = ["--all" "--filter" "until=${builtins.toString (7*24)}h"];
      };
      dockerCompat = true;
      dockerSocket.enable = true;
      #defaultNetwork.settings = { dns_enabled = true; };
    };
    docker = {
      #enable = true;
      #storageDriver = "overlay2";
      autoPrune = {
        enable = true;
        dates = "04:30:00";
        flags = ["--all" "--filter" "until=${builtins.toString (7*24)}h"];
      };
    };
  };

  boot.binfmt.emulatedSystems = [] # using box64 in place of qemu would be great, but it doesn't work so well at the moment: https://github.com/NixOS/nixpkgs/issues/213197
    ++ lib.optionals ( pkgs.stdenv.hostPlatform.system != "x86_64-linux" ) [ "x86_64-linux" ]
    ++ lib.optionals ( pkgs.stdenv.hostPlatform.system != "aarch64-linux" ) [ "aarch64-linux" ]
  ;

  systemd.targets.machines.enable = true;

  # systemd.sysusers.enable = true; # experimental in 24.05
  # systemd.etc.overlay.enable = true; # experimental in 24.05

  services.udisks2.settings = { # fix NTFS mount, from https://wiki.archlinux.org/title/NTFS#udisks_support
    "mount_options.conf" = {
      defaults = {
        ntfs_defaults = "uid=$UID,gid=$GID,noatime,prealloc";
      };
    };
  };

  # I hate to wait 1m30s. If something doesn't work in 15s,
  # it's never going to work later
  systemd = {
    settings.Manager = {
      ShutdownWatchdogSec = "30s";
      RebootWatchdogSec = "30s";
      KExecWatchdogSec = "30s";
      RuntimeWatchdogSec = "30s";
      DefaultTimeoutStopSec = "15s";
      DefaultTimeoutStartSec = "15s";
      DefaultTimeoutAbortSec = "15s";
    };

    user.extraConfig = ''
      DefaultTimeoutStopSec=15s
      DefaultTimeoutStartSec=15s
      DefaultTimeoutAbortSec=15s
    '';
  };

}

