{ config, pkgs, lib, inputs, ... }:
{
  # sync registry with our flakes. better for consistency, space, and `nix run/shell` execution time (thanks to caching)
  nix.registry = {
    nixos.flake = inputs.nixos;
    nixos-small.flake = inputs.nixos-small;
    nixos-unstable.flake = inputs.nixos-unstable;
    nixpkgs-darwin.flake = inputs.nixpkgs-darwin;
    nixpkgs-master.flake = inputs.nixpkgs-master;
    nur.flake = inputs.nur;
    flake-utils.flake = inputs.flake-utils;
    rust-overlay.flake = inputs.rust-overlay;
    home-manager.flake = inputs.home-manager;
  };
}
