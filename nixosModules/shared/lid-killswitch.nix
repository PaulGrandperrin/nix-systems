{ config, pkgs, ... }:

let
  lid-killswitch-script = pkgs.writeShellScript "lid-killswitch" ''
    CLOSED_COUNT=0
    LID_PATH="/proc/acpi/button/lid/LID/state"

    while true; do
      if [ -f "$LID_PATH" ] && ${pkgs.gnugrep}/bin/grep -q "closed" "$LID_PATH"; then
        CLOSED_COUNT=$((CLOSED_COUNT + 10))
      else
        CLOSED_COUNT=0
      fi

      if [ "$CLOSED_COUNT" -ge 30 ]; then
        echo "LID CLOSED FOR 30s: Initiating emergency poweroff." >&2
        
        systemctl poweroff &

        sleep 10

        systemctl poweroff -f &

        sleep 5

        systemctl poweroff -ff &

        sleep 5
        
        echo 1 > /proc/sys/kernel/sysrq # enables all sysrq commands
        echo s > /proc/sysrq-trigger # sync
        sleep 5
        echo u > /proc/sysrq-trigger # remount read only
        sleep 5
        echo o > /proc/sysrq-trigger # shut system off
      fi

      sleep 10
    done
  '';
  lid-killswitch-service = {
    description = "Lid Monitor Poweroff";
    wantedBy = [ "sysinit.target"];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      ExecStart = "${lid-killswitch-script}";
      Restart = "always";
      Type = "exec";

      SurviveFinalKillSignal = "yes";
      KillSignal = "SIGCONT";
      SendSIGKILL = false;
      DefaultDependencies = false; # don't conflict with shutdown.target
      OOMScoreAdjust = -1000;
    };
  };
in
{
  #boot.kernelParams = [
  #  "systemd.log_level=debug"
  #  "systemd.log_target=kmsg"
  #  "log_buf_len=1M"
  #  "printk.devkmsg=on"
  #  "rd.rescue"
  #  "systemd.debug_shell"
  #];

  systemd.services.lid-killswitch = lid-killswitch-service;

  boot.initrd = {
    kernelModules = ["button"];
    systemd = {
      enable = true;
      storePaths = [
        pkgs.gnugrep
        lid-killswitch-script
      ];
      services.lid-killswitch-initrd = lid-killswitch-service;
    };
  };

}

