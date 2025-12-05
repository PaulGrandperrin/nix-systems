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

    #inputs.nixos-cosmic.nixosModules.default
  ];

  services.desktopManager.cosmic.enable = true;
  services.displayManager = {
    cosmic-greeter.enable = true;
    autoLogin = {
      enable = true;
      user = "paulg";
    };
  };
  services.displayManager.gdm.enable = lib.mkForce false;
  environment.systemPackages = with pkgs; [
    cosmic-reader
    cosmic-ext-ctl
    cosmic-ext-tweaks
    cosmic-ext-calculator
    cosmic-ext-applet-minimon
    cosmic-ext-applet-caffeine
    cosmic-ext-applet-privacy-indicator
    cosmic-ext-applet-external-monitor-brightness
    examine

    # gnome apps filling in gapps in COSMIC env
    loupe
    gnome-boxes
    gnome-calculator
    gnome-calendar
    gnome-clocks
    gnome-color-manager
    gnome-contacts
    gnome-control-center
    gnome-disk-utility

  ];
}


