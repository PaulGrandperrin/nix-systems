{ config, pkgs, inputs, ... }:
{
  virtualisation.oci-containers = {
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" ];
      environment.TZ = "Europe/Paris";
      image = "ghcr.io/home-assistant/home-assistant:stable";
      #ports = ["8123"];
      extraOptions = [ 
        "--network=host" 
        "--pull=newer"
        #"--device=/dev/ttyACM0:/dev/ttyACM0"
      ];
    };
  };
  services.nginx.virtualHosts."ha.paulg.fr" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
        proxyPass = "http://localhost:8123/";
        proxyWebsockets = true;
    };
  };
}
