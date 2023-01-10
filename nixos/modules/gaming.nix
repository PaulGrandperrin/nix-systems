{ config, pkgs, lib, ... }:
{
  #home-manager.users.paulg.home.file.".config/vlc/vlcrc".text = ;
  programs.steam.enable = true;
  services.gnome.games.enable = true;

  environment.systemPackages = with pkgs; [
    # gaming
    protonup-ng
    lutris
    stockfish

    gamemode
    gnomeExtensions.gamemode
  ];
}


