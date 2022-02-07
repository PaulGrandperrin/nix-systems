{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./nix-registry.nix
  ];

  # Hardening
  # TODO: noexec mounts, tmpfs...
  environment.defaultPackages = lib.mkForce [];
  nix.allowedUsers = [ "@wheel" ];

  nix.gc = {
    automatic = true;
    persistent = true;
    dates = "05:00:00";
    options = "--delete-older-than 2d";
  };

  nix.autoOptimiseStore = true;
  nix.optimise = {
    automatic = true;
    dates = ["06:00:00"];
  };
  
  #nix.trustedUsers = ["@wheel"];

  security = {
    sudo = {
      enable = false;
      execWheelOnly = true;
    };
    doas = {
      enable = true;
      extraRules = [{
        groups = ["wheel"];
        persist = true;
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


  #boot.kernelPackages = pkgs.linuxPackages_latest; # brakes ZFS sometimes
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  
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

  services.zfs.trim.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSJQGYQs+KJX+V/X3KxhyQgahE0g+ITF2jr1wUY1s/3"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE" # nixos-gcp
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3KlABFus1z3jTDvylO6e6gSnn7nIqJKZOZJ9di5OW4" # paulg@nixos-xps
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOIxgOXuz4/8JB++umc4fEvFwIlM3eeVadTsvCZCQN2" # root@nixos-xps
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBKbOypMYzisA9fwYtZVWWtcvsOqA294EEBIYN/9YCr" # MacBookPaul NixOS
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
  };

  virtualisation.podman.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  systemd.targets.machines.enable = true;
  networking.useNetworkd = true;
  services.resolved.enable = true;
  networking.useDHCP = false;

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

