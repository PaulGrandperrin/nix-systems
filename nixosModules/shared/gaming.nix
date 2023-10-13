{ config, pkgs, lib, ... }:
{
  programs = {
    steam = {
      enable = true;
      dedicatedServer.openFirewall = true;
      remotePlay.openFirewall = true;
    };
    gamemode.enable = true;
    gamescope = {
      enable = true;
      capSysNice = true;
    };
  };
  services.gnome.games.enable = true;

  home-manager.users.paulg.home.packages = with pkgs; [
    # gaming
    protonup-ng
    lutris
    stockfish

    gnomeExtensions.gamemode
  ];
}


