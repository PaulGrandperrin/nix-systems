{ config, pkgs, lib, inputs, ... }:
{
  # sync registry with our flakes. better for consistency, space, and `nix run/shell` execution time (thanks to caching)
  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
    nixos.flake = inputs.nixos;
    nixos-unstable.flake = inputs.nixos-unstable;
    nur.flake = inputs.nur;
    flake-utils.flake = inputs.flake-utils;
    rust-overlay.flake = inputs.rust-overlay;
    home-manager.flake = inputs.home-manager;
  };
}
