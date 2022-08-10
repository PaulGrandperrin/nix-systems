{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config;
  peers = [
    {
      hostname = "nixos-nas";
      publicKey = "naS+n7Tj8/Oq+svcRqw71ZQrXjC93byT3poFeLB2t3E=";
      ip = "10.0.0.100";
      endPoint.host = "nas.paulg.fr";
      endPoint.port = 51820;
    } {
      hostname = "nixos-macmini";
      publicKey = "mcM+NQQuwuTlKAMxrxZnyZxHMXa5RHENq1pDAIw49zQ=";
      ip = "10.0.0.1";
      endPoint.host = "nas.paulg.fr";
      endPoint.port = 51821;
    } {
      hostname = "nixos-gcp";
      publicKey = "GCp+nDutIu0Ei+f1j1ZB5Opr50S3DiN/wY4usMC08zM=";
      ip = "10.0.0.2";
    } {
      hostname = "nixos-xps";
      publicKey = "xPs+nrka9e2qA8OmoNFEjLmyVvdb/8HkTBIwpxLNc1s=";
      ip = "10.0.0.3";
    } {
      hostname = "nixos-macbook";
      publicKey = "mcb+N3JPq2qKCpAv9V2wWCFerk36DzLvbMS7ByEuIXc=";
      ip = "10.0.0.4";
    } {
      hostname = "pixel6pro";
      publicKey = "P6p+aJrLSBYFsw5f9q+b9sOgA9HnKh2UWz+uwGjnLEE=";
      ip = "10.0.0.5";
    }
  ];
in {
  options.services.my-wg = {
    enable = mkEnableOption "My Wireguard";
  };

  config = let
    is_server = builtins.any (e: e.hostname == cfg.networking.hostName && e ? endPoint) peers;
    port = mkIf is_server (head (builtins.filter (e: e.hostname == cfg.networking.hostName) peers)).endPoint.port;
  in mkIf cfg.services.my-wg.enable {
    
    # install
    environment.systemPackages = [ pkgs.wireguard-tools ];
    boot.extraModulePackages = optional (versionOlder cfg.boot.kernelPackages.kernel.version "5.6") cfg.boot.kernelPackages.wireguard;

    # boot.kernel.sysctl."net.ipv4.conf.wg0.forwarding" = mkIf is_server 1; # already done in systemd-network config

    # open port in firewall
    networking.firewall.allowedUDPPorts = mkIf is_server [ port ];

    ## enable NAT
    networking.nat.enable = mkIf is_server true;
    # the externalInterface is already setup in net.nix
    networking.nat.internalInterfaces = mkIf is_server [ "wg0" ];

    # setup private key
    sops.secrets."wg-private-key" = {
      sopsFile = ../secrets/${cfg.networking.hostName}.yaml;
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
            ListenPort = port;
          };

          wireguardPeers = (if is_server then
            map (e: {
              wireguardPeerConfig = {
                PublicKey = e.publicKey;
                AllowedIPs = if e ? endPoint then "${e.ip}/32, 10.0.0.0/24" else "${e.ip}/32";
                Endpoint = mkIf (e ? endPoint) "${e.endPoint.host}:${toString e.endPoint.port}";
              };
            }) (builtins.filter (e: e.hostname != cfg.networking.hostName) peers)
          else
            map (e: {
              wireguardPeerConfig = {
                PublicKey = e.publicKey;
                AllowedIPs = "${e.ip}/32, 10.0.0.0/24";
                Endpoint = "${e.endPoint.host}:${toString e.endPoint.port}";
                PersistentKeepalive = 25; # to keep NAT connections open
              };
            }) (builtins.filter (e: e.hostname != cfg.networking.hostName && e ? endPoint) peers)
          );
        };
      };
      networks = {
        "40-wg0" = {
          matchConfig.Name = "wg0";
          networkConfig = {
            Address = "${toString (head (builtins.filter (e: e.hostname == cfg.networking.hostName) peers)).ip}/24"; 
            IPForward = mkIf is_server "ipv4";
          };
        };
      };
    };

  };
}

