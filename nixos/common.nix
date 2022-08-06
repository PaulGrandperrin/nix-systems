{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./mail.nix
  ];
  system.stateVersion = "21.11";

  sops = {
    defaultSopsFile = ../secrets/common.yaml;
  };

  # automatically convert the SSH server's private key to an age key for SOPS
  system.activationScripts = {
    ssh-to-age = ''
      ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key -o /root/.config/sops/age/keys.txt 
    '';
  };

  # deploy our github public access token everywhere to avoid API rate limitations
  sops.secrets.github-public-access-token.mode = "0444";
  environment.sessionVariables = {
    NIX_USER_CONF_FILES = "/run/secrets/github-public-access-token"; 
  };

  # Hardening
  # TODO: noexec mounts, tmpfs...
  environment.defaultPackages = lib.mkForce [];
  nix.allowedUsers = [ "@wheel" "nix-serve" ];

  nix.gc = {
    automatic = true;
    persistent = true;
    dates = "05:00:00";
    options = "--delete-older-than 7d";
  };

  nix.autoOptimiseStore = true;
  nix.optimise = {
    automatic = true;
    dates = ["06:00:00"];
  };
  
  #nix.trustedUsers = ["@wheel"];

  security = {
    sudo = {
      enable = true; # TODO: remove when we are sure doas work properly
      execWheelOnly = true;
    };
    doas = {
      enable = true;
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

  # Flakes
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
   };

  hardware.cpu.intel.updateMicrocode = true;
  services.fstrim.enable = true;
  boot.kernelParams = [ "panic=20" "boot.panic_on_fail" "oops=panic" "ipv6.disable=1"];
  networking.enableIPv6 = false;


  #boot.kernelPackages = pkgs.linuxPackages_latest; # breakes ZFS sometimes
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  # boot.forceImportRoot = false; 

  # enabling mails in ZFS enables mails in smartmontools and zed
  nixpkgs.overlays = [(final: prev: { 
    #linuxPackages_5_18 = prev.linuxPackages_5_18.extend (lpself: lpsuper: { # HACK temp fix
    #  zfs = lpsuper.zfs.overrideAttrs (old: {
    #    patches = old.patches ++ [ (pkgs.fetchpatch {
    #      name = "zfs-2.1.5.patch";
    #      url = "https://gist.githubusercontent.com/mpasternacki/819b7ff33c0df3f37b5687cfdeabf954/raw/df9d8c585642bffda7d8e542722b704bd14cfb69/zfs-2.1.5.patch";
    #      hash = "sha256-rGvoUsBZza5p9Zdn8Zq0HRzIhtPiDZfIfyq0T1hozEk=";
    #    })];
    #  });
    #});
    zfs = (prev.zfs.override { 
      enableMail = true;
    });
  })]; 

  services.zfs = {
    zed.settings = {
      ZED_EMAIL_ADDR = [ "root" ];
      ZED_NOTIFY_VERBOSE = true;
    };

    trim = {
      enable = true;
      interval = "daily";
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

  nix.settings = {
    substituters = [
      "http://nas.paulg.fr:5000"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nas.paulg.fr:QwhwNrClkzxCvdA0z3idUyl76Lmho6JTJLWplKtC2ig="
    ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.config.allowUnfree = true;

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
    "kernel.sysrq" = 1;
  };

  programs.sysdig.enable = true;

  programs.fish = {
    enable = true;
    useBabelfish = false;
  };

  users.mutableUsers = false;

  users.users.root = {
    passwordFile = "/etc/nixos/secrets/password-root";
    shell = pkgs.fish;
  };

  users.users.paulg = {
    isNormalUser = true;
    description = "Paul Grandperrin";
    passwordFile = "/etc/nixos/secrets/password-paulg";
    extraGroups = [ "wheel" "video" "netdev" "networkmanager"]; # audio?
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


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    busybox-sandbox-shell
  ];

  zramSwap = {
    enable = true;
    algorithm = "lz4";
    priority = 5;
    memoryPercent = 200;
  };

  # List services that you want to enable:

  services.gpm.enable = false;
  services.thermald.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = lib.mkForce true;
    permitRootLogin = lib.mkForce "yes";
  };

  virtualisation = {
    podman.enable = true;
    docker = {
      enable = true;
      #storageDriver = "overlay2";
      autoPrune = {
        enable = true;
        dates = "04:30:00";
        flags = ["--all" "--filter" "until=${builtins.toString (7*24)}h"];
      };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  systemd.targets.machines.enable = true;
  networking.useNetworkd = true;
  networking.useDHCP = false;

  networking.nameservers = ["9.9.9.11#dns11.quad9.net" "149.112.112.11#dns11.quad9.net" "2620:fe::11#dns11.quad9.net" "2620:fe::fe:11#dns11.quad9.net"]; # Malware blocking, DNSSEC Validation, ECS enabled
  #networking.nameservers = ["9.9.9.9#dns.quad9.net" "149.112.112.112#dns.quad9.net" "2620:fe::fe#dns.quad9.net" "2620:fe::9#dns.quad9.net"]; # Malware Blocking, DNSSEC Validation
  #networking.nameservers = ["9.9.9.10#dns10.quad9.net" "149.112.112.10#dns10.quad9.net" "2620:fe::10#dns10.quad9.net" "2620:fe::fe:10#dns10.quad9.net"]; # No Malware blocking, no DNSSEC validation
  #networking.nameservers = ["1.1.1.1#cloudflare-dns.com" "1.0.0.1#cloudflare-dns.com" "2606:4700:4700::1111#cloudflare-dns.com" "2606:4700:4700::1001#cloudflare-dns.com"];
  #networking.nameservers = ["8.8.8.8#dns.google" "8.8.4.4#dns.google" "2001:4860:4860::8888#dns.google" "2001:4860:4860::8844#dns.google"];
  services.resolved = {
    enable = true;
    dnssec = "false"; # https://github.com/systemd/systemd/issues/10579
    extraConfig = ''
      FallbackDNS=
      DNSOverTLS=true
      MulticastDNS=true
    '';
  };

  systemd.network.networks."10-proton" = {
    matchConfig = {
      "Name" = "proton*";
      "Driver" = "tun";
    };
    networkConfig = {
      "DNSDefaultRoute" = "no";
    };
  };

  systemd.network.networks."10-container-ve" = { # same as original except 2 lines related to link-local address clashs
    matchConfig = {
      "Name" = "ve-*";
      "Driver" = "veth";
    };
    networkConfig = {
      "Address" = "0.0.0.0/28";
      "LinkLocalAddressing" = "no"; # link-local addresses clash with GCP's
      "DHCPServer" = "yes";
      "IPMasquerade" = "ipv4";
      "LLDP" = "yes";
      "EmitLLDP" = "customer-bridge";
    };
    dhcpServerConfig = {
      "DNS" = "8.8.8.8 8.8.4.4"; # don't use GCP's link-local DNS
    };
  };

  services.udisks2.settings = { # fix NTFS mount, from https://wiki.archlinux.org/title/NTFS#udisks_support
    "mount_options.conf" = {
      defaults = {
        ntfs_defaults = "uid=$UID,gid=$GID,noatime,prealloc";
      };
    };
  };
}

