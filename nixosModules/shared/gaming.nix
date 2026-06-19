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
      package = pkgs.unstable.steam.override {
        extraEnv = {
          #MANGOHUD = true;
        };
        extraPkgs = p: with p; [
        ];
        extraLibraries = p: with p; [
          #SDL SDL2 sdl3 # steam-run quake4
        ];
      };
      extraCompatPackages = with pkgs; [
        unstable.steam-play-none # run linux game as is, even if valve recommends proton
        #unstable.proton-ge-bin # from nixpkgs
        proton-ge-custom # from chaotic
        proton-cachyos_x86_64_v3 # from chaotic
      ];
      extraPackages = with pkgs; [
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
    # lutris # fails to build because of openldap !
    stockfish
    dolphin-emu
    pcsx2
    #unstable.yuzu
    unstable.perfect_dark
    #unstable.banjorecomp

    # gnomeExtensions.gamemode # not anymore in 23.11
  ];

  boot.kernelModules = [
    "ntsync"
  ];

}


