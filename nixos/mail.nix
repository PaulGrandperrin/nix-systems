{pkgs, config, ...}: {
  environment.systemPackages = with pkgs; [
    mailutils
  ];
  services.opensmtpd = {
    enable = true;
    setSendmail = true;
    serverConfiguration = ''
      #listen on localhost
      table secrets file://etc/nixos/secrets/smtpd
      table aliases { "@" = "paul.grandperrin+${config.networking.hostName}@gmail.com" } # catch all
      action "forward" forward-only virtual <aliases> # forward all local mails
      action "relay" relay host smtp+tls://gmailcreds@smtp.gmail.com:587 auth <secrets> # mail-from "paul.grandperrin@gmail.com"
      match for local action "forward"
      match for any action "relay"
    '';
  };
}
