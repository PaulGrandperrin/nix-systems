{ config, pkgs, lib, ... }:
{
  programs = {
    steam = {
      enable = true;
      extraCompatPackages = with pkgs; [
        steam-play-none
        proton-ge-bin
      ];
      #dedicatedServer.openFirewall = true;
      #localNetworkGameTransfers.openFirewall = true;
      #remotePlay.openFirewall = true;
      protontricks = {
        enable = true;
        package = pkgs.protontricks;
      };
      gamescopeSession.enable = true;
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
    protonplus
    protontricks
    lutris
    stockfish
    dolphin-emu
    pcsx2
    #unstable.yuzu
    unstable.perfect_dark

    # gnomeExtensions.gamemode # not anymore in 23.11
  ];

  boot.kernelModules = [
    "ntsync"
  ];

}


