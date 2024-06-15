{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./desktop.nix
    #(import "${pkgs.applyPatches {
    #  src = inputs.nixos-cosmic.outPath;
    #  patches = [
    #  ];

    #}}/flake.nix").nixosModules.default 
    #((import "${inputs.nixos-cosmic.outPath}/flake.nix").nixosModules.default)

    #(let f = import "${inputs.nixos-cosmic.outPath}/flake.nix"; in
    #  f.outputs (inputs.nixos-cosmic.inputs // {self = f.outputs;})
    #).nixosModules.default

    inputs.nixos-cosmic.nixosModules.default
  ];

  services.desktopManager.cosmic.enable = true;
}


