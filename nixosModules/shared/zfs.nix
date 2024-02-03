{ config, pkgs, lib, ... }:
{
  boot.zfs.devNodes = "/dev/disk/by-path"; # /dev/disk/by-id doesn't get populated with virtio disks. see https://github.com/NixOS/nixpkgs/pull/263662

  #boot.kernelPackages = pkgs.linuxPackages_latest; # breakes ZFS sometimes # nix eval --raw n#linuxPackages.kernel.version
  boot.kernelPackages = (pkgs.zfs.override { # nix eval --raw n#zfs.latestCompatibleLinuxPackages.kernel.version
    removeLinuxDRM = pkgs.hostPlatform.isAarch64;
  }).latestCompatibleLinuxPackages;

  boot.zfs.removeLinuxDRM = true; # mandatory for ZFS on aarch64

  # boot.forceImportRoot = false; 

  # NOTE: not needed, just keeping for futur inspiration
  #nixpkgs.overlays = [(final: prev: { 
  #  linuxPackages_5_18 = prev.linuxPackages_5_18.extend (lpself: lpsuper: { # HACK temp fix
  #    zfs = lpsuper.zfs.overrideAttrs (old: {
  #      patches = old.patches ++ [ (pkgs.fetchpatch {
  #        name = "zfs-2.1.5.patch";
  #        url = "https://gist.githubusercontent.com/mpasternacki/819b7ff33c0df3f37b5687cfdeabf954/raw/df9d8c585642bffda7d8e542722b704bd14cfb69/zfs-2.1.5.patch";
  #        hash = "sha256-rGvoUsBZza5p9Zdn8Zq0HRzIhtPiDZfIfyq0T1hozEk=";
  #      })];
  #    });
  #  });
  #})]; 

  # use stable ZFS from nixos-unstable
  # NOTE: this also pulls the latest ZFS compatible linux from nixos-unstable
  #nixpkgs.config.packageOverrides = _pkgs: {
  #  zfsStable = pkgs.unstable.zfsStable;
  #};

  services.zfs = {
    zed.settings = {
      # enable email notifications
      ZED_EMAIL_ADDR = [ "root" ];
      ZED_NOTIFY_VERBOSE = true;
      ZED_EMAIL_PROG = "${pkgs.mailutils}/bin/mail";
    };

    trim = {
      enable = true;
      interval = "07:00:00";
    };
    autoScrub = {
      enable = true;
      interval = "Wed *-*-1..7 12:00:00"; # first Wednesday of the month at noon
    };
    autoSnapshot = {
      enable = true;
      flags = "-p -u";
      frequent = 2;
      hourly = 2;
      daily = 2;
      weekly = 0;
      monthly = 0;
    };
  };


}

