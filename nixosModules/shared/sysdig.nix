{pkgs, config, lib, ...}: {
  config = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (
    let sysdig = pkgs.unstable.callPackage (import (pkgs.unstable.path + "/pkgs/os-specific/linux/sysdig")) {kernel = config.boot.kernelPackages.kernel;};
  in {
    #programs.sysdig.enable = true;
    environment.systemPackages = [ sysdig ];
    boot.extraModulePackages = [ sysdig ];
  });
}
