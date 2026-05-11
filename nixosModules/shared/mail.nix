{pkgs, config, lib, ...}: {
  environment.systemPackages = with pkgs; [
    mailutils
  ];
  sops.secrets.smtpd = {
    mode = "0400";
    owner = config.users.users.smtpd.name;
    group = config.users.users.smtpd.group;
    restartUnits = [ "opensmtpd.service" ];
  };
  services.opensmtpd = {
    enable = true;
    setSendmail = true;
    serverConfiguration = ''
      listen on localhost
      table secrets file:/${config.sops.secrets.smtpd.path}
      table aliases { "@" = "paul.grandperrin+${config.networking.hostName}@gmail.com" } # catch all
      action "forward" forward-only virtual <aliases> # forward all local mails
      action "relay" relay host smtp+tls://gmailcreds@smtp.gmail.com:587 auth <secrets> # mail-from "paul.grandperrin@gmail.com"
      match for local action "forward"
      match for any action "relay"
    '';
  };

  systemd.services."service-failure-handler@" = let
    serviceFailureScript = pkgs.writeShellApplication {
      name = "systemd-service-failure-script";
      runtimeInputs = with pkgs; [ systemd hostname mailutils];
      text = ''
        SERVICE_NAME=$1
        HOSTNAME=$(hostname)

        echo "Sending failure alert for $SERVICE_NAME..."

        systemctl status --full "$SERVICE_NAME" | mail -s "[$HOSTNAME] $SERVICE_NAME service failed" root 
      '';
    };
  in {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${serviceFailureScript}/bin/systemd-service-failure-script %i";
      Group = "systemd-journal";
      User = "nobody";
    };
  };

  # we can't use `environment.etc` for those overrides because /etc/systemd/system is a link to units package
  systemd.packages = [
    (pkgs.writeTextDir "etc/systemd/system/service.d/10-failure-notification.conf" ''
      [Unit]
      OnFailure=service-failure-handler@%n.service
    '')

    (pkgs.writeTextDir "etc/systemd/system/service-failure-handler@.service.d/99-disable-loop.conf" ''
      [Unit]
      OnFailure=
    '')
  ];

}
