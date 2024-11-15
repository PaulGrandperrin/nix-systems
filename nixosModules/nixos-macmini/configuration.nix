{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    ../shared/zfs.nix
    ../shared/net.nix
    ../shared/nspawns.nix
    ../shared/wireguard.nix
    ../shared/wg-mounts.nix
    ../shared/web.nix
    #../shared/auto-upgrade.nix
    ../shared/headless.nix
    ../shared/home-assistant.nix
  ];

  home-manager.users = let 
    homeModule = {
      imports = [
        ../../homeModules/shared/core.nix
        ../../homeModules/shared/cmdline-extra.nix
      ];
    };
  in {
    root  = homeModule;
    paulg = homeModule;
  };

  fileSystems."/" = {
    device = "zpool/nixos";
    fsType = "zfs";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/home" = {
    device = "zpool/nixos/home";
    fsType = "zfs";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/nix" = {
    device = "zpool/nixos/nix";
    fsType = "zfs";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A01A-DC7D";
    fsType = "vfat";
    options = [
      "noatime"
      "nodiratime"
      "nofail"
    ];
  };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/3574e8dd-b51d-4b2f-9e94-6bb389fd7959"; }
    ];


  networking.hostId="aedc67f9";
  networking.hostName = "nixos-macmini";
  services.net = {
    enable = true;
    mainInt = "enp3s0f0";
  }; 
  powerManagement.cpuFreqGovernor = "schedutil";

  services.my-wg = {
    enable = true;
  };

  sops.secrets."duckdns-token" = {
    sopsFile = ../../secrets/nixos-macmini.yaml;
    mode = "0440";
    owner = "inadyn";
    group = "inadyn";
    restartUnits = [ "inadyn.service" ]; # not really useful because triggered by timer
  };

  services.inadyn = {
    enable = true;
    settings.provider."default@duckdns.org" = {
      hostname = "philgdpr.duckdns.org";
      include = config.sops.secrets."duckdns-token".path;
    };
  };

  services.nginx.virtualHosts = {
    "phil.grandperrin.fr" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:8123/";
        proxyWebsockets = true;
      };
    };
    "philgdpr.duckdns.org" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:8123/";
        proxyWebsockets = true;
      };
    };
  };

  #services.my-nspawn = {
  #  enable = true;
  #  name = "tidb-macmini";
  #  net-id = 2;
  #  id = 1;
  #};

  boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless


  # broadcom_sta fails to build on linux 5.18: https://github.com/NixOS/nixpkgs/issues/177798
  #boot.kernelPackages = lib.mkForce pkgs.linuxPackages; # use stable kernel where broadcom_sta build
}

