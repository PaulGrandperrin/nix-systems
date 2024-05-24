{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./desktop.nix
    inputs.nixos-cosmic.nixosModules.default
  ];

  services.desktopManager.cosmic.enable = true;
}


