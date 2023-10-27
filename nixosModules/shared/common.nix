{ config, pkgs, lib, inputs, home-manager-flake, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    home-manager-flake.nixosModules.home-manager
    inputs.dwarffs.nixosModules.dwarffs
    ./mail.nix
  ];
  system.stateVersion = "22.05";

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
  
  # always keep a reference to the source flake that generated each generations
  environment.etc."source-flake".source = ../.;

  boot.zfs.devNodes = "/dev/disk/by-uuid"; # /dev/disk/by-id doesn't get populated with virtio disks. see https://github.com/NixOS/nixpkgs/pull/263662
  boot.initrd.systemd.emergencyAccess = lib.mkDefault true;

  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "exfat"
    "ntfs"
  ];

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
  };

  # Hardening
  # TODO: noexec mounts, tmpfs...
  environment.defaultPackages = lib.mkForce [];

  security.acme.acceptTerms = true;
  #security.acme.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
  security.acme.defaults.email = "paul.grandperrin@gmail.com";

  nix = {
    settings = import ../../nix/nix.nix;
    gc = {
      automatic = true;
      persistent = true;
      dates = "05:00:00";
      options = "--delete-older-than 7d";
    };
  };

  nix.optimise = {
    automatic = true;
    dates = ["06:00:00"];
  };
  
  security = {
    sudo = {
      enable = true; # TODO: remove when we are sure doas work properly
      execWheelOnly = true;
    };
    doas = {
      enable = false;
      extraRules = [{
        groups = ["wheel"];
        persist = true;
        setEnv = with lib; let # because of https://github.com/Duncaen/OpenDoas/issues/2 we need to add here all variables that should have been read from PAM_env
          # code inspired from https://github.com/NixOS/nixpkgs/blob/nixos-21.11/nixos/modules/config/system-environment.nix#L69
          suffixedVariables = 
            flip mapAttrs config.environment.profileRelativeSessionVariables (envVar: suffixes:
              flip concatMap config.environment.profiles (profile:
                map (suffix: "${profile}${suffix}") suffixes
              )
            );
          suffixedVariablesWithWrappers = (zipAttrsWith (n: concatLists)
            [
              # Make sure security wrappers are prioritized without polluting
              # shell environments with an extra entry. Sessions which depend on
              # pam for its environment will otherwise have eg. broken sudo. In
              # particular Gnome Shell sometimes fails to source a proper
              # environment from a shell.
              { PATH = [ config.security.wrapperDir ]; }
              
              (mapAttrs (n: toList) config.environment.sessionVariables)
              suffixedVariables
            ]
            );
          replaceEnvVars = replaceStrings ["$HOME" "$USER"] ["/root" "root"];
          doasVariable = k: v: ''${k}=${concatStringsSep ":" (map replaceEnvVars (toList v))}'';

        in mapAttrsToList doasVariable suffixedVariablesWithWrappers;
      }];
    };
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

  boot.binfmt.registrations.appimage = { # make appImage work seamlessly
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  services.envfs.enable = true; # populate /usr/bin for non-nix binaries
  programs.nix-ld = { # create a link-loader for non-nix binaries
    enable = true;
    libraries = with pkgs; [
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
  ];

  #boot.kernelPackages = pkgs.linuxPackages_latest; # breakes ZFS sometimes # nix eval --raw n#linuxPackages.kernel.version
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages; # nix eval --raw n#zfs.latestCompatibleLinuxPackages.kernel.version
  # boot.forceImportRoot = false; 

  # NOTE: not needed, just keeping for futur inspiration
  #nixpkgs.overlays = [(final: prev: { 
  #  linuxPackages_5_18 = prev.linuxPackages_5_18.extend (lpself: lpsuper: { # HACK temp fix
  #    zfs = lpsuper.zfs.overrideAttrs (old: {
  #      patches = old.patches ++ [ (pkgs.fetchpatch {
  #        name = "zfs-2.1.5.patch";
  #        url = "https://gist.githubusercontent.com/mpasternacki/819b7ff33c0df3f37b5687cfdeabf954/raw/df9d8c585642bffda7d8e542722b704bd14cfb69/zfs-2.1.5.patch";
  #        hash = "sha256-rGvoUsBZza5p9Zdn8Zq0HRzIhtPiDZfIfyq0T1hozEk=";
  #      })];
  #    });
  #  });
  #})]; 

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

  # use stable ZFS from nixos-unstable
  # NOTE: this also pulls the latest ZFS compatible linux from nixos-unstable
  #nixpkgs.config.packageOverrides = _pkgs: {
  #  zfsStable = pkgs.unstable.zfsStable;
  #};

  services.zfs = {
    zed.settings = {
      # enable email notifications
      ZED_EMAIL_ADDR = [ "root" ];
      ZED_NOTIFY_VERBOSE = true;
      ZED_EMAIL_PROG = "${pkgs.mailutils}/bin/mail";
    };

    trim = {
      enable = true;
      interval = "07:00:00";
    };
    autoScrub = {
      enable = true;
      interval = "Wed *-*-1..7 12:00:00"; # first Wednesday of the month at noon
    };
    autoSnapshot = {
      enable = true;
      flags = "-p -u";
      frequent = 2;
      hourly = 2;
      daily = 2;
      weekly = 0;
      monthly = 0;
    };
  };

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
  boot.initrd.systemd.enable = true;

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
   "vm.swappiness" = 30; # default 60, between 0 to 100. 10 means try to not swap
   "vm.vfs_cache_pressure" = 200; # default 100, recommended between 50 to 500. 500 means less file cache for less swapping
   "vm.dirty_background_ratio" = 10; # default 10, start writting dirty pages at this ratio
   "vm.dirty_ratio" = 40; # default 20, maximum ratio, block process when reached
  };

  services.irqbalance.enable = true;

  programs.sysdig.enable = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") true;

  programs.fish = {
    enable = true;
    useBabelfish = false;
  };

  programs.command-not-found.enable = false; # disable because it uses channels and we use nix-index instead

  users.mutableUsers = false;

  sops.secrets.password-root.neededForUsers = true;
  sops.secrets.password-paulg.neededForUsers = true;

  users.users.root = {
    passwordFile = config.sops.secrets.password-root.path;
    shell = pkgs.fish;
  };

  users.users.paulg = {
    isNormalUser = true;
    description = "Paul Grandperrin";
    passwordFile = config.sops.secrets.password-paulg.path;
    extraGroups = [
      "wheel"
      "networkmanager" # no need for password
      "audio" # used by JACK for realtime, otherwise not needed on systemd
      #"kvm" # access to /dev/kvm but doesn't seem to be needed. thanks to uaccess? 
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
        ${wakelan}/bin/wakelan -p9 -b nas.paulg.fr -m "$(cat ${config.sops.secrets.hwmac-nas.path})"
        # also send locally because sending on the internet from the same network doesn't work
        ${wakelan}/bin/wakelan -p9 -m "$(cat ${config.sops.secrets.hwmac-nas.path})"
      '';
    })
  ];

  zramSwap = {
    enable = true;
    algorithm = "lzo-rle";
    priority = 5;
    memoryPercent = 200;
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
      enable = true;
      autoPrune = {
        enable = true;
        dates = "04:30:00";
        flags = ["--all" "--filter" "until=${builtins.toString (7*24)}h"];
      };
      dockerCompat = true;
      #defaultNetwork.settings = { dns_enabled = true; };
      #enableNvidia = true;
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

  services.udisks2.settings = { # fix NTFS mount, from https://wiki.archlinux.org/title/NTFS#udisks_support
    "mount_options.conf" = {
      defaults = {
        ntfs_defaults = "uid=$UID,gid=$GID,noatime,prealloc";
      };
    };
  };

}

