# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "flash/nixos";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "flash/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "flash/nixstore";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/641A-604D";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/dc8118ad-555c-48dc-96f7-3ce11823b49f"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}