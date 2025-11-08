{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    ../shared/zfs.nix
    ../shared/net.nix
    ../shared/wireguard.nix
    ../shared/wg-mounts.nix
    ../shared/gnome.nix
    ../shared/cosmic.nix
    ../shared/desktop.nix
    ../shared/desktop-i915.nix
  ];

  home-manager.users = let 
    homeModule = {
      imports = [
        ../../homeModules/shared/core.nix
        ../../homeModules/shared/cmdline-extra.nix
        ../../homeModules/shared/firefox.nix
        ../../homeModules/shared/chromium.nix
        ../../homeModules/shared/desktop-linux.nix
        ../../homeModules/shared/gnome.nix
        #../../homeModules/shared/kodi.nix
        #../../homeModules/shared/rust.nix
        #../../homeModules/shared/wine.nix
      ];
    };
  in {
    root  = homeModule;
    paulg = homeModule;
  };

  fileSystems."/" = {
    device = "zroot/encrypted/nixos";
    fsType = "zfs";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/home" = {
    device = "zroot/encrypted/nixos/home";
    fsType = "zfs";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/BF32-47AA";
    fsType = "vfat";
    options = [
      "noatime"
      "nodiratime"
      "nofail"
    ];
  };

  nix.settings = {
    cores = 2; # max concurrent tasks during one build
    max-jobs = 2; # max concurrent build job
  };

  swapDevices = [ ];

  networking.hostId="3a0da539";
  boot.kernelParams = [ "mitigations=off" ];

  services.my-wg = {
    enable = true;
  };

  networking.hostName = "nixos-asus";
  services.net = {
    enable = true;
    mainInt = "wlp2s0";
  };

}

