{
  boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless
  boot.kernelParams = [
    # when there's an issue, we want the server to reboot, not hang
    "panic=10"
    "boot.panic_on_fail"
    "oops=panic"
  ];
}
