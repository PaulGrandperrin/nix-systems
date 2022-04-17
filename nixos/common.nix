{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./nix-registry.nix
    ./mail.nix
  ];

  # Hardening
  # TODO: noexec mounts, tmpfs...
  environment.defaultPackages = lib.mkForce [];
  nix.allowedUsers = [ "@wheel" ];

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
  boot.kernelParams = [ "panic=20" "boot.panic_on_fail" "oops=panic"];


  #boot.kernelPackages = pkgs.linuxPackages_latest; # breakes ZFS sometimes
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  # boot.forceImportRoot = false; 

  # enabling mails in ZFS enables mails in smartmontools and zed
  nixpkgs.overlays = [(final: prev: { 
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

  nix = {
    binaryCaches = [
      "https://nix-community.cachix.org"
    ];
    binaryCachePublicKeys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
    extraGroups = [ "wheel" "video" ]; # audio?
    uid = 1000;
    useDefaultShell = true;
    createHome = true;
    home = "/home/paulg";
    shell = pkgs.fish;
  };
  # automatically allows my Github's keys
  #users.users.paulg.openssh.authorizedKeys.keyFiles = [ ((builtins.fetchurl "https://github.com/PaulGrandperrin.keys")) ];
  users.users.paulg.openssh.authorizedKeys.keys = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+tckVW3zh58Cr246EuceDY/HdgoJrmSnYTNEv0Y3HW"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVW/7zXgQwIAk46daSBfP5ti7zpADrs1p//f5IyRHJH"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdJ9evK0Ay1KFOBG+EZC7xPOb8udcltjg8rTFpHimz5"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjsf+KqGyIAhHxL54740gfH+qQxQl7K1liLsvaGvlHK"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE" # nixos-gcp
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3KlABFus1z3jTDvylO6e6gSnn7nIqJKZOZJ9di5OW4" # paulg@nixos-xps
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOIxgOXuz4/8JB++umc4fEvFwIlM3eeVadTsvCZCQN2" # root@nixos-xps
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBKbOypMYzisA9fwYtZVWWtcvsOqA294EEBIYN/9YCr" # paulg@MacBookPaul NixOS
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMK/GnaGGlU7pl4po31XP6K5VpodTu67J+D1/3d74R57" # root@MacBookPaul NixOS
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5s0Fe3Y2kX5bxhipkD/OGePPRew40fElqzgacdavuY" # root@nixos-nas
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSJQGYQs+KJX+V/X3KxhyQgahE0g+ITF2jr1wUY1s/3" # paulg@nixos-nas
  ];

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

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = true;
    #permitRootLogin = "yes";
  };

  virtualisation.podman.enable = true;

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
      "IPMasquerade" = "yes";
      "LLDP" = "yes";
      "EmitLLDP" = "customer-bridge";
    };
    dhcpServerConfig = {
      "DNS" = "8.8.8.8 8.8.4.4"; # don't use GCP's link-local DNS
    };
  };
}

