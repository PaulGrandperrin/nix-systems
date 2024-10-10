{ config, pkgs, lib, ... }:
{
  imports = [
    ./web.nix
  ];

  services.thelounge = {
    enable = true;
    extraConfig = {
      reverseProxy = true;
      defaults = {
        nick = "paulgdpr";
        username = "paulgdpr";
        realname = "Paul Grandperrin";
        join = "";
      };
    };
  };

  services.nginx.virtualHosts."thelounge.grandperrin.fr" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
        proxyPass = "http://localhost:${toString config.services.thelounge.port}/";
        proxyWebsockets = true;
    };
  };
}
