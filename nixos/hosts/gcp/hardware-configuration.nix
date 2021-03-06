# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "virtio_scsi" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

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

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/17E7-9B0C";
      fsType = "vfat";
    };

  fileSystems."/var/lib/machines/ubuntu" =
    { device = "nixos/ubuntu";
      fsType = "zfs";
    };

  swapDevices = [ ];

}
