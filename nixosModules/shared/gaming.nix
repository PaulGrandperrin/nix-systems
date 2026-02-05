{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    pkgs.unstable.gamescope-wsi
    
    (writeShellApplication {
      name = "steamos-session-select";
      text = ''
        ${steam}/bin/steam -shutdown
      '';
    })
  ];

  programs = {
    steam = {
      enable = true;
      package = pkgs.unstable.steam;
      extraCompatPackages = with pkgs.unstable; [
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
      gamescopeSession = {
        enable = true;
        env = {
          #MESA_VK_WSI_PRESENT_MODE = "immediate";
        };
        args = [
          #"--expose-wayland"
          #"--rt"
          #"--steam"
          #"--mangoapp"
        #  "-O" "DP-2"
          #"--generate-drm-mode" "cvt"
          #"--immediate-flips"
        ];
        steamArgs = [
          #"-steamos3" # needed to have "Switch to Desktop" button launch steamos-session-select # https://github.com/ValveSoftware/steam-for-linux/issues/11241
        ];
      };
    };
    gamemode.enable = true;
    gamescope = {
      enable = true;
      package = pkgs.unstable.gamescope;
      #capSysNice = true;
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


