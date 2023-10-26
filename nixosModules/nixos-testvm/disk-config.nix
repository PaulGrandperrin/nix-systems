{ disks ? ["/dev/vda"], ...}: {
  disko.devices = {
    disk.disk1 = {
      device = "/dev/vda"; # builtins.elemAt disks 0;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          #boot = {
          #  name = "boot";
          #  size = "1M";
          #  type = "EF02";
          #};
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
          swap = {
            size = "1G";
            content = {
              type = "swap";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "btrfs";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
