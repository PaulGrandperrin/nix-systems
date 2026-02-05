{pkgs, ...}: {
  environment.systemPackages = [ pkgs.modprobed-db ];

  systemd.services.modprobed-db = {
    description = "modprobed-db scan and store new modules";
    path = with pkgs; [
      gawk
      getent
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.modprobed-db}/bin/modprobed-db storesilent";
    };
  };

  systemd.timers.modprobed-db = {
    description = "Check for new modules";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1h";
    };
  };
}

