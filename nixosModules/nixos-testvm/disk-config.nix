{ disks ? ["/dev/vda"], ...}: {
  disko.devices = {
    disk.disk1 = {
      device = "/dev/vda"; # builtins.elemAt disks 0;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            #name = "ESP";
            size = "500M";
            type = "EF00"; # maybe not mandatory
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "zroot";
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        options = { # -o
          ashift = "12";
        };
        rootFsOptions = { # -O
          compression = "lz4"; # adapt
          mountpoint = "none";
          atime = "off";
          acltype = "posixacl"; # check compat with podman
          xattr = "sa"; # check compat with podman
          dnodesize = "auto"; # default is "legacy" to be compatible with ZFS without large_dnode feature
          "com.sun:auto-snapshot" = "false";
        };
        datasets = {
          "nixos" = {
            type = "zfs_fs";
            mountpoint = "/";
            mountOptions = ["noatime" "nodiratime"];
            options = {
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };
          "nixos/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            mountOptions = ["noatime" "nodiratime"];
            options = {
              mountpoint = "legacy";
            };
          };
          "nixos/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            mountOptions = ["noatime" "nodiratime"];
            options = {
              mountpoint = "legacy";
            };
          };

        };
      };
    };
  };
}
