{ config, pkgs, lib, ... }:

{

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      #customRC = builtins.readFile ./config/init.vim;
      packages.nix = with pkgs.vimPlugins; {
        start = [
          vim-surround # Shortcuts for setting () {} etc.
          vim-nix # nix highlight
          neovim-fuzzy # fuzzy finder through vim
          vim-lastplace # restore cursor position
        ];
        opt = [];
      };
    };
  };

  # Hardening
  # TODO: noexec mounts, tmpfs...
  environment.defaultPackages = lib.mkForce [];
  security.sudo.execWheelOnly = true;
  nix.allowedUsers = [ "@wheel" ];

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
  # for nixos-unstable
  #boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackges;
  
  ## way too long to build
  #boot.kernelPatches = [{
  #  name = "custom";
  #  patch = null;
  #  extraConfig = ''
  #    PANIC_ON_OOPS y
  #    FORTIFY_SOURCE y
  #  '';
  #}];

  system.autoUpgrade.enable = true;
  system.autoUpgrade.flake = "git@github.com:PaulGrandperrin/nixos-conf.git";
  system.autoUpgrade.flags = [ "--update-input" "nixpkgs" "--commit-lock-file" ];
  system.autoUpgrade.allowReboot = true;

  #nixpkgs.config = {
  #  #allowUnfree = true;
  #  packageOverrides = pkgs: {
  #    unstable = import <nixos-unstable> {
  #      config = config.nixpkgs.config;
  #    };
  #  };
  #};
  
  services.zfs.trim.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  programs.fish = {
    enable = true;
    shellAbbrs = {
    
    };
  };

  users.defaultUserShell = pkgs.fish;

  users.mutableUsers = false;

  users.users.root = {
    passwordFile = "/etc/nixos/secrets/password-root";
  };

  users.users.paulg = {
    isNormalUser = true;
    description = "Paul Grandperrin";
    passwordFile = "/etc/nixos/secrets/password-paulg";
    extraGroups = [ "wheel" ];
    uid = 1000;
    useDefaultShell = true;
    createHome = true;
    home = "/home/paulg";
  };
  # automatically allows my Github's keys
  #users.users.paulg.openssh.authorizedKeys.keyFiles = [ ((builtins.fetchurl "https://github.com/PaulGrandperrin.keys")) ];
  users.users.paulg.openssh.authorizedKeys.keys = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+tckVW3zh58Cr246EuceDY/HdgoJrmSnYTNEv0Y3HW"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVW/7zXgQwIAk46daSBfP5ti7zpADrs1p//f5IyRHJH"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdJ9evK0Ay1KFOBG+EZC7xPOb8udcltjg8rTFpHimz5"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjsf+KqGyIAhHxL54740gfH+qQxQl7K1liLsvaGvlHK"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSJQGYQs+KJX+V/X3KxhyQgahE0g+ITF2jr1wUY1s/3"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE"
  ];


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    htop ncdu tmux
    topgrade
    git
    bridge-utils
    ripgrep

    gnumake
    clang_12
    emscripten
    (rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
      #extensions = [ "rust-src" ];
      targets = [ "wasm32-unknown-emscripten" "wasm32-unknown-unknown"];
    }))
    #(input.nixpkgs.rust-bin.stable.latest.default.override {
    #  #extensions = ["rust-src"];
    #  #targets = ["wasm32-unknown-emscripten"];
    #})
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

