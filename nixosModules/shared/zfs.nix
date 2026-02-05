{ config, pkgs, lib, ... }: {

  # zfs create
  # -o cachefile=none # stores which zpool should be imported, not needed  when the zpool hosts the OS itself
  # # -o ashift=12 # 4k sector size. if nvme lbasize is correctly configured, shouldn't be needed. check with zdb -C zpool | grep ashift
  # -o failmode=continue # allow reads even in case of catastrophic pool failure
  # -o autotrim=on # fine on modern SSDs
  # -O mountpoint=none # don't use ZFS auto mount
  # -O atime=off # avoids writting access time
  # -O compression=zstd-fast # outperforms lz4 in compression and decompression speed and compression ratio
  # -O recordsize=1M # precompression maximum size of a record. default is 128k. 1M: better compression, less fragmentation. For bittorrents, use 16k.
  # -O acltype=posixacl
  # -O xattr=sa # good perf when using posixacl
  # -O dnodesize=auto # good perf when using xattr=sa
  # -O redundant_metadata=most # allows losing more than one record at once in case of corruption, but won't affect multiple files
  # -O sync=disabled # don't respect synchronous writes. allows losing up to 5 sec of data. renders logbios prop meaningless. helps with perf, write amplification and fragmentation
  # -O direct=standard # respect direct IO semantics

  # no utf8only or normalization: might break proton/wine
  # casesensitivity=insensitive: perf boost for proton but breaks unix

  # zfs create zpool/encrypted
  # -o encryption=aes-128-gcm # default is aes256-gcm which is overkill in a pre-quantum world
  # -o keyformat=passphrase
  # -o pbkdf2iters=1000000 # 3 times the 2026 default

  # zfs create zpool/encrypted/nixos
  # zfs create zpool/encrypted/nixos/home

  boot.zfs.devNodes = "/dev/disk/by-path"; # /dev/disk/by-id doesn't get populated with virtio disks. see https://github.com/NixOS/nixpkgs/pull/263662

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

  boot.zfs = {
    #package = pkgs.zfs;
    forceImportRoot = false; # default to true but recommended to disable. if fails to boot, use "zfs_force=1" on kernel cmdline once.
  };
  boot.initrd.systemd = {
    initrdBin = [
      config.boot.zfs.package
    ];
  };

  services.zfs = {
    zed.settings = {
      # enable email notifications
      ZED_EMAIL_ADDR = [ "root" ];
      ZED_NOTIFY_VERBOSE = true;
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

