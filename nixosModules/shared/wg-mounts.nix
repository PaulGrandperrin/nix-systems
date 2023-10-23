{...}: {
  fileSystems."/mnt/nixos-nas/public" = {
    device = "10.42.0.1:/export/public";
    fsType = "nfs";
    #options = [ "nfsvers=4.2" ];
    options = [
      "proto=tcp"
      "mountproto=tcp" # NFSv3 only
      "soft" # return errors to client when access is lost, instead of waiting indefinitely
      "softreval" # use cache even when access is lost
      "timeo=100"
      "noatime"
      "nodiratime"
      "noauto" # don't mount until needed
      #"x-systemd.requires=example.service"
      "x-systemd.automount" # mount when accessed
      "_netdev" # wait for network
      "x-systemd.mount-timeout=5"
      "x-systemd.idle-timeout=3600"
    ];
  };
  fileSystems."/mnt/nixos-nas/encrypted" = {
    device = "10.42.0.1:/export/encrypted";
    fsType = "nfs";
    #options = [ "nfsvers=4.2" ];
    options = [
      "proto=tcp"
      "mountproto=tcp" # NFSv3 only
      "soft" # return errors to client when access is lost, instead of waiting indefinitely
      "softreval" # use cache even when access is lost
      "timeo=100"
      "noatime"
      "nodiratime"
      "noauto" # don't mount until needed
      #"x-systemd.requires=example.service"
      "x-systemd.automount" # mount when accessed
      "_netdev" # wait for network
      "x-systemd.mount-timeout=5"
      "x-systemd.idle-timeout=3600"
    ];
  };
}
