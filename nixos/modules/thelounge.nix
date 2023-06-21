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
        host = "localhost";
      };
    };
  };

  services.nginx.virtualHosts."thelounge.paulg.fr" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
        proxyPass = "http://localhost:${toString config.services.thelounge.port}/";
        proxyWebsockets = true;
    };
  };
}
