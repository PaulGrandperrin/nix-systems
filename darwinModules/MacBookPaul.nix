{lib, ...}: {
  imports = [
    ./shared/common.nix
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-darwin";
}
