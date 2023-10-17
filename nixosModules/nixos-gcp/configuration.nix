{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    #../shared/auto-upgrade.nix # 1G of memory is not enough to evaluate the system's derivation, even with zram...
    ../shared/google-compute-config.nix
    ../shared/common.nix
    ../shared/net.nix
    ../shared/wireguard.nix
    ../shared/thelounge.nix
    ../shared/headless.nix
  ];

  home-manager.users.root  = ../../homeModules/nixos-gcp.nix;
  home-manager.users.paulg = ../../homeModules/nixos-gcp.nix;

  fileSystems."/" =
    { device = "nixos";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "nixos/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "nixos/home";
      fsType = "zfs";
    };

  fileSystems."/var/lib/machines/ubuntu" =
    { device = "nixos/ubuntu";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/17E7-9B0C";
      fsType = "vfat";
    };

  swapDevices = [ ];


  networking.hostId = "1c734661"; # for ZFS
  networking.hostName = "nixos-gcp";
  networking.interfaces.eth0.useDHCP = true;

  services.net = {
    enable = true;
    mainInt = "eth0";
  }; 

  services.my-wg = {
    enable = true;
  };

  boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless
  
  # useful to build and deploy closures from nixos-nas which a lot beefier than nixos-gcp
  users.users.root.openssh.authorizedKeys.keys = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5s0Fe3Y2kX5bxhipkD/OGePPRew40fElqzgacdavuY" # root@nixos-nas
  ];
  
  services.smartd.enable = lib.mkForce false;
  
  environment.systemPackages = with pkgs; [
    google-cloud-sdk-gce
  ];
}

