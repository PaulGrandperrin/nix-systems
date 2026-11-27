{...}: {
  fileSystems."/mnt/nixos-nas/public" = {
    device = "10.42.0.1:/public";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "proto=tcp"
      "hard" # retry indefinitely on timeout; "soft" causes silent data corruption on rw mounts
      "softreval" # fall back to cached attributes if server is unreachable (safe with hard)
      "retry=0"
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
    device = "10.42.0.1:/encrypted";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "proto=tcp"
      "hard" # retry indefinitely on timeout; "soft" causes silent data corruption on rw mounts
      "softreval" # fall back to cached attributes if server is unreachable (safe with hard)
      "retry=0"
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
