{ config, pkgs, lib, ... }:
{
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  services.gnome.games.enable = true;

  home-manager.users.paulg.home.packages = with pkgs; [
    # gaming
    protonup-ng
    lutris
    stockfish

    gnomeExtensions.gamemode
  ];
}


