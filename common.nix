{ config, pkgs, ... }:

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

  hardware.cpu.intel.updateMicrocode = true;
  services.fstrim.enable = true;
  boot.kernelParams = [ "panic=20" "boot.panic_on_fail" "oops=panic"];

  boot.kernelPackages = pkgs.linuxPackages_latest;
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

  programs.fish.enable = true;
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


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    htop ncdu tmux
    topgrade
    git
  ];

  zramSwap = {
    enable = true;
    algorithm = "lz4";
    priority = 5;
    memoryPercent = 200;
  };
  

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  systemd.targets.machines.enable = true;
  networking.useNetworkd = true;
  services.resolved.enable = true;
  networking.useDHCP = false;

}

