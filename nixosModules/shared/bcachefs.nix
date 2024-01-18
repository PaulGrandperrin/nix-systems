{ config, pkgs, lib, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_latest; # breakes ZFS sometimes # nix eval --raw n#linuxPackages.kernel.version

  environment.systemPackages = [ pkgs.bcachefs-tools ];
}

