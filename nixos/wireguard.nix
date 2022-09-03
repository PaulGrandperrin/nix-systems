{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config;
  peers = [
    # each peer get assigned an IP on the VPN's network (10.0.0.$id) and a network (10.0.$id.0/24)
    {
      id = 1;
      hostname = "nixos-nas";
      publicKey = "naS+n7Tj8/Oq+svcRqw71ZQrXjC93byT3poFeLB2t3E=";
      endPoint.host = "nas.paulg.fr";
      endPoint.port = 51820;
      natToInternet = true;
      forwardToAll = true; # Only one
    } {
      id = 2;
      hostname = "nixos-macmini";
      publicKey = "mcM+NQQuwuTlKAMxrxZnyZxHMXa5RHENq1pDAIw49zQ=";
      endPoint.host = "nas.paulg.fr";
      endPoint.port = 51821;
      natToInternet = true;
    } {
      id = 3;
      hostname = "nixos-gcp";
      publicKey = "GCp+nDutIu0Ei+f1j1ZB5Opr50S3DiN/wY4usMC08zM=";
      endPoint.host = "paulg.fr";
      endPoint.port = 51820;
      natToInternet = true;
    } {
      id = 4;
      hostname = "nixos-xps";
      publicKey = "xPs+nrka9e2qA8OmoNFEjLmyVvdb/8HkTBIwpxLNc1s=";
    } {
      id = 5;
      hostname = "nixos-macbook";
      publicKey = "mcb+N3JPq2qKCpAv9V2wWCFerk36DzLvbMS7ByEuIXc=";
    } {
      id = 6;
      hostname = "pixel6pro";
      publicKey = "P6p+aJrLSBYFsw5f9q+b9sOgA9HnKh2UWz+uwGjnLEE=";
    }
  ];
in {
  options.services.my-wg = {
    enable = mkEnableOption "My Wireguard";
  };

  config = let
    my_hostname = cfg.networking.hostName;
    my_conf = head (builtins.filter (e: e.hostname == my_hostname) peers);
  in mkIf cfg.services.my-wg.enable {
    # add domains in /etc/hosts
    networking.extraHosts = concatStringsSep "\n" (map (p: "10.0.0.${toString p.id} ${p.hostname}.wg") peers);

    # allow all connections on this trusted interface
    networking.firewall.trustedInterfaces = [ "wg0" ];
    
    # install
    environment.systemPackages = [ pkgs.wireguard-tools ];
    boot.extraModulePackages = optional (versionOlder cfg.boot.kernelPackages.kernel.version "5.6") cfg.boot.kernelPackages.wireguard;

    # boot.kernel.sysctl."net.ipv4.conf.wg0.forwarding" = mkIf (my_conf.forwardToAll or false) 1; # already done in systemd-network config

    # open port in firewall if we expose an endPoint
    networking.firewall.allowedUDPPorts = mkIf (my_conf ? endPoint) [ my_conf.endPoint.port ];

    # setup private key
    sops.secrets."wg-private-key" = {
      sopsFile = ../secrets/${my_hostname}.yaml;
      group = "systemd-network";
      mode = "0640";
      restartUnits = [ "systemd-networkd.service" ];
    };

    systemd.network = {
      enable = true;
      netdevs = {
        "10-wg0" = {
          netdevConfig = {
            Name = "wg0";
            Kind = "wireguard";
          };
          wireguardConfig = { 
            PrivateKeyFile = cfg.sops.secrets.wg-private-key.path;
            ListenPort = mkIf (my_conf ? endPoint) my_conf.endPoint.port; # if we are an endPoint
          };

          wireguardPeers =
            map (e: {
              wireguardPeerConfig = {
                PublicKey = e.publicKey;
                AllowedIPs = if (e.forwardToAll or false) then [ "10.0.0.0/16" ] else [ "10.0.0.${toString e.id}/32" "10.0.${toString e.id}.0/24" ];
                Endpoint = mkIf (e ? endPoint) "${e.endPoint.host}:${toString e.endPoint.port}";
                PersistentKeepalive = mkIf (! my_conf ? endPoint) 25; # to keep NAT connections open if I'm not an endPoint
              };
            }) (builtins.filter (e: e.hostname != my_hostname && (my_conf ? endPoint || e ? endPoint)) peers) # filter peers that are not myself and where one of us is not an endPoint
          ;
        };
      };
      networks = {
        "40-wg0" = {
          matchConfig.Name = "wg0";
          networkConfig = {
            Address = "10.0.0.${toString my_conf.id}/24"; # dont set /16 here because then IPMasquerade would be enabled for all those addresses, i.e. including those on the 10.0.X.0/24 networks.
            IPForward = mkIf (my_conf.forwardToAll or false) "ipv4";
            IPMasquerade = mkIf (my_conf.natToInternet or false) "ipv4";
          };
          routes = [{
            routeConfig = {
              Destination = "10.0.0.0/16";
            };
          }];
        };
      };
    };

  };
}

