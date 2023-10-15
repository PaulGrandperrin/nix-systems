{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    ../shared/net.nix
    ../shared/wireguard.nix
    ../shared/desktop.nix
    ../shared/desktop-i915.nix
  ];

  fileSystems."/" =
    { device = "ssd/encrypted/nixos";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "ssd/encrypted/nixos/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F196-D7D2";
      fsType = "vfat";
    };

  swapDevices = [ ];


  networking.hostId="f2b2467d";
  # hardware.facetimehd.enable = true; # FIXME broken
  services.mbpfan.enable = true;

  services.my-wg = {
    enable = true;
  };

  # use stable ZFS from nixos-unstable
  # NOTE: this also pulls the latest ZFS compatible linux from nixos-unstable
  nixpkgs.config.packageOverrides = _pkgs: {
    zfsStable = pkgs.unstable.zfsStable;
  };

  powerManagement = {
    powerDownCommands = lib.mkBefore ''
      modprobe -r thunderbolt # seems to help with resuming faster from S3

      # brcmfmac being loaded during hibernation would not let a successful resume
      # https://bugzilla.kernel.org/show_bug.cgi?id=101681#c116.
      # Also brcmfmac could randomly crash on resume from sleep.
      # And also, brcmfac prevents suspending
      ${pkgs.kmod}/bin/rmmod brcmfmac
      #echo disabled > /sys/bus/pci/devices/0000:03:00.0/power/wakeup # ARPT in /proc/acpi/wakeup, wifi adapter always wakes up the machine, already disabled by rmmod

      # if the LID is open
      if grep open /proc/acpi/button/lid/LID0/state; then
        # disable the open-lid sensor but enable the keyboard (USB) wake up events
        echo enabled > /sys/bus/pci/devices/0000:00:14.0/power/wakeup # XHC1 in /proc/acpi/wakeup, USB controller, sometimes wakes up the machine
        echo disabled > /sys/bus/acpi/devices/PNP0C0D:00/power/wakeup # LID0 in /proc/acpi/wakeup, wakes up the machine when the lid is in open position
      else 
        # enable the open-lid sensor wake events but disable to USB controller to be extra sure
        echo enabled > /sys/bus/acpi/devices/PNP0C0D:00/power/wakeup # LID0 in /proc/acpi/wakeup, wakes up the machine when the lid is in open position
        echo disabled > /sys/bus/pci/devices/0000:00:14.0/power/wakeup # XHC1 in /proc/acpi/wakeup, USB controller, sometimes wakes up the machine
      fi
    '';
    powerUpCommands = lib.mkBefore ''[ "$IN_NIXOS_SYSTEMD_STAGE1" = "true" ] || ${pkgs.kmod}/bin/modprobe brcmfmac''; # must not run in stage1 because module loading is not ready yet
  };

  # USB subsystem wakes up MBP right after suspend unless we disable it.
  #services.udev.extraRules = ''
  #  ### fix suspend on MacBookPro12,1 
  #  # found using:
  #  # cat /proc/acpi/wakeup
  #  # echo $device > /proc/acpi/wakeup # to bruteforce which devices woke up the laptop
  #  # fd $sysfs_node /sys
  #  # udevadm info -a -p $path
  #  #SUBSYSTEM=="pci", KERNEL=="0000:03:00.0", DRIVER=="brcmfmac", ATTR{power/wakeup}="disabled"
  #  #SUBSYSTEM=="acpi", KERNEL=="PNP0C0D:00", DRIVER=="button", ATTR{power/wakeup}="disabled" # LID0 in /proc/acpi/wakeup
  #  SUBSYSTEM=="acpi", KERNEL=="PNP0C0D:00", ATTR{power/wakeup}="disabled" # LID0 in /proc/acpi/wakeup
  #'';
  networking.hostName = "nixos-macbook";
  services.net = {
    enable = true;
    mainInt = "wlp3s0";
  };

}

