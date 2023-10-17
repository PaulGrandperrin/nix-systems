{lib, ...}: {
  imports = [
    ./shared/common.nix
  ];
  nixpkgs.hostPlatform = lib.default "x86_64-linux";
}
