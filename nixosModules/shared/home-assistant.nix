{ config, pkgs, inputs, ... }:
{

  # add to /var/lib/containers/storage/volumes/home-assistant/_data/configuration.yaml
  # http:
  #   use_x_forwarded_for: true
  #   trusted_proxies:
  #     - 127.0.0.1
  #     - 10.88.0.1

  imports = [
    ./web.nix
  ];

  virtualisation.oci-containers = {
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" ];
      environment.TZ = "Europe/Paris";
      image = "ghcr.io/home-assistant/home-assistant:stable";
      #ports = ["8123"];
      extraOptions = [ 
        "--network=host" 
        "--pull=newer"
        "--device=/dev/ttyACM0:/dev/ttyACM0"
      ];
    };
  };
  services.nginx.virtualHosts."phil.grandperrin.fr" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
        proxyPass = "http://localhost:8123/";
        proxyWebsockets = true;
    };
  };
}
