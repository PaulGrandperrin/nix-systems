{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    inputs.xremap-flake.nixosModules.default
  ];
  services.xremap = {
    serviceMode = "user";
    userName = "paulg";
    withGnome = true;
    watch = true;
    config = {
      keymap = [
        {
          name = "Terminals";
          application = {
            only = ["org.gnome.Console" "terminator" "kitty" "org.wezfurlong.wezterm" "com.system76.CosmicTerm"]; # busctl --user call org.gnome.Shell /com/k0kubun/Xremap com.k0kubun.Xremap WMClasses
          };
          remap = {
            Super-t = "C-Shift-t"; # new tab
            Super-w = "C-Shift-w"; # close tab
            Super-Tab = "C-Shift-Tab"; # next tab
            Super-Shift-Tab = "C-Shift-Tab"; # previous tab
            Super-f = "C-Shift-f"; # search
            Super-x = "C-Shift-x"; # cut
            Super-c = "C-Shift-c"; # copy
            Super-v = "C-Shift-v"; # paste
          };
        }
        {
          name = "Default";
          remap = {
            Super-t = "C-t";
            Super-w = "C-w";
            Super-f = "C-f";
            Super-x = "C-x";
            Super-c = "C-c";
            Super-v = "C-v";
          };
        }
      ];
    };
  };
  home-manager.users.paulg.home.packages = with pkgs; [
    gnomeExtensions.xremap
  ];
}
