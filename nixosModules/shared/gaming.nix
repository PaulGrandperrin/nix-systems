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
    protontricks
    lutris
    stockfish
    dolphin-emu
    pcsx2
    #unstable.yuzu
    perfect_dark

    # gnomeExtensions.gamemode # not anymore in 23.11
  ];
}


