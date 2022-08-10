{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config;
  peers = [
    {
      hostname = "nixos-nas";
      publicKey = "naS+n7Tj8/Oq+svcRqw71ZQrXjC93byT3poFeLB2t3E=";
      ip = "10.0.0.1";
      endPoint.host = "nas.paulg.fr";
      endPoint.port = 51820;
      natToInternet = true;
      forwardToAll = true; # Only one
    } {
      hostname = "nixos-macmini";
      publicKey = "mcM+NQQuwuTlKAMxrxZnyZxHMXa5RHENq1pDAIw49zQ=";
      ip = "10.0.0.2";
      endPoint.host = "nas.paulg.fr";
      endPoint.port = 51821;
      natToInternet = true;
    } {
      hostname = "nixos-gcp";
      publicKey = "GCp+nDutIu0Ei+f1j1ZB5Opr50S3DiN/wY4usMC08zM=";
      ip = "10.0.0.3";
      endPoint.host = "paulg.fr";
      endPoint.port = 51820;
      natToInternet = true;
    } {
      hostname = "nixos-xps";
      publicKey = "xPs+nrka9e2qA8OmoNFEjLmyVvdb/8HkTBIwpxLNc1s=";
      ip = "10.0.0.4";
    } {
      hostname = "nixos-macbook";
      publicKey = "mcb+N3JPq2qKCpAv9V2wWCFerk36DzLvbMS7ByEuIXc=";
      ip = "10.0.0.5";
    } {
      hostname = "pixel6pro";
      publicKey = "P6p+aJrLSBYFsw5f9q+b9sOgA9HnKh2UWz+uwGjnLEE=";
      ip = "10.0.0.6";
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
    
    # install
    environment.systemPackages = [ pkgs.wireguard-tools ];
    boot.extraModulePackages = optional (versionOlder cfg.boot.kernelPackages.kernel.version "5.6") cfg.boot.kernelPackages.wireguard;

    # boot.kernel.sysctl."net.ipv4.conf.wg0.forwarding" = mkIf (my_conf.forwardToAll or false) 1; # already done in systemd-network config

    # open port in firewall if we expose an endPoint
    networking.firewall.allowedUDPPorts = mkIf (my_conf ? endPoint) [ my_conf.endPoint.port ];

    ## enable NAT if our conf says so
    networking.nat.enable = mkIf (my_conf.natToInternet or false) true;
    # the externalInterface is already setup in net.nix
    networking.nat.internalInterfaces = mkIf (my_conf.natToInternet or false) [ "wg0" ];

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
                AllowedIPs = if (e.forwardToAll or false) then "10.0.0.0/24" else "${e.ip}/32";
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
            Address = "${toString my_conf.ip}/24"; 
            IPForward = mkIf (my_conf.forwardToAll or false) "ipv4";
          };
        };
      };
    };

  };
}

