{ config, pkgs, inputs, ... }: let
  my-yuzu = (pkgs.callPackage (pkgs.unstable.path + "/pkgs/applications/emulators/yuzu") {}).mainline.overrideAttrs (_: {
    meta.platforms = pkgs.lib.platforms.linux;
  });
in {
  environment.systemPackages = with pkgs; [
    my-yuzu
  ];
  networking.firewall.allowedUDPPorts = [ 5000 ];

  sops.secrets."yuzu-multiplayer" = {
    restartUnits = [ "yuzu-multiplayer.service" ];
  };

  systemd.services.yuzu-multiplayer = {
    description = "Yuzu multiplayer server";
    wantedBy = ["multi-user.target"];
    after = [ "network.target" ];

    serviceConfig = {
      Restart = "always";
      DynamicUser = true;
      EnvironmentFile = config.sops.secrets."yuzu-multiplayer".path;
      ExecStart = toString [
        "${my-yuzu}/bin/yuzu-room"
        "--room-name" "\"A la Bonne Auberge\""
        #"--room-description" ""
        "--preferred-game" "\"Candy Crush\""
        #"--preferred-game-id" "<INSERT TITLE ID HERE>"
        "--port" "5000"
        "--max_members" "16"
        "--token" "\"$TOKEN\""
        #"--enable-yuzu-mods"
        "--web-api-url" "\"https://api.yuzu-emu.org\""
        "--password" "\"$PASSWORD\""
      ];

      # Sandboxing
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
      RestrictRealtime = true;
      RestrictNamespaces = true;
      MemoryDenyWriteExecute = true;

    };
  };
}
