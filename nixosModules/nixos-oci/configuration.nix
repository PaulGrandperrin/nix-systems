{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    ../shared/containers/web.nix
    ../shared/net.nix
    ../shared/wireguard.nix
    ../shared/auto-upgrade.nix
    ../shared/headless.nix
  ];

  home-manager.users = let 
    homeModule = {
      imports = [
        ../../homeModules/shared/core.nix
      ];
    };
  in {
    root  = homeModule;
    paulg = homeModule;
  };

  fileSystems."/" =
    { device = "system/nixos";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "system/nixos/nix";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F6D1-7CDB";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "system/nixos/home";
      fsType = "zfs";
    };

  swapDevices = [ ];


  networking.hostId = "ea026662"; # head -c 8 /etc/machine-id
  networking.hostName = "nixos-oci";
  networking.interfaces.eth0.useDHCP = true;

  boot.kernelParams = [ "net.ifnames=0" ]; # so that network is always eth0

  services.net = {
    enable = true;
    mainInt = "eth0";
  }; 

  services.my-wg = {
    enable = true;
  };

  boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless

  services.smartd.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
  ];
}

