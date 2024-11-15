{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.my-wg;
  outside-config = config;
  peers = [
    # each peer get assigned an IP on the VPN's network (10.42.0.$id) and a network (10.42.$id.0/24)
    {
      id = 1;
      hostname = "nixos-nas";
      publicKey = "naS+n7Tj8/Oq+svcRqw71ZQrXjC93byT3poFeLB2t3E=";
      endPoint.host = "nas.grandperrin.fr";
      endPoint.port = 51820;
      natToInternet = true;
    } {
      id = 2;
      hostname = "nixos-macmini";
      publicKey = "mcM+NQQuwuTlKAMxrxZnyZxHMXa5RHENq1pDAIw49zQ=";
      endPoint.port = 51820;
      natToInternet = true;
    } {
      id = 3;
      hostname = "nixos-gcp";
      publicKey = "GCp+nDutIu0Ei+f1j1ZB5Opr50S3DiN/wY4usMC08zM=";
      endPoint.host = "gcp.grandperrin.fr";
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
    } {
      id = 7;
      hostname = "nixos-oci";
      publicKey = "Oci+nA4cbcCjmK5sfG413Jh+wUqBuK4qHnLdvghsGy0=";
      endPoint.host = "oci.grandperrin.fr";
      endPoint.port = 51820;
      natToInternet = true;
      forwardToAll = true; # Only one
    }
  ];
in {
  options.services.my-wg = {
    enable = mkEnableOption "My Wireguard";
  };

  config = let
    my_hostname = config.networking.hostName;
    my_conf = head (builtins.filter (e: e.hostname == my_hostname) peers);
  in mkIf cfg.enable {
    environment.systemPackages = [
      # install
      pkgs.wireguard-tools

      # small script to route all traffic through node
      (pkgs.writeShellApplication {
        name = "my-vpn";
        runtimeInputs = with pkgs; [
          iproute2
          jq
          systemd
          wireguard-tools
          ripgrep
        ];
        text = ''
          set -e

          test $# -eq 1 || (echo "missing argument" ; exit 1)

          HOST=$1.grandperrin.fr
          WG_DEV=wg0

          DEFAULT_GW=$(ip -json route show to default | jq .[0].gateway -r)
          DEFAULT_DEV=$(ip -json route show to default | jq .[0].dev -r)
          SERVER_IP=$(resolvectl query "$HOST" |head -n1|cut -d' ' -f2) #https://github.com/systemd/systemd/issues/29755
          WG_PEER_PK=$(wg showconf "$WG_DEV"|rg -B3 "Endpoint = $SERVER_IP"|rg "PublicKey ="|sed 's/PublicKey = //')
          WG_PEER_AL_IP=$(wg showconf "$WG_DEV"|rg -B3 "Endpoint = $SERVER_IP"|rg "AllowedIPs ="|sed 's/AllowedIPs = //'|tr -d ' ')

          function connect() {
            echo "connecting..."
            ip route add "$SERVER_IP" via "$DEFAULT_GW" dev "$DEFAULT_DEV" proto static
            ip route add default dev "$WG_DEV" proto static
            wg set wg0 peer "$WG_PEER_PK" allowed-ips 0.0.0.0/0
            echo "VPN connected"
          }

          function disconnect() {
            echo "disconnecting..."
            set +e
            wg set wg0 peer "$WG_PEER_PK" allowed-ips "$WG_PEER_AL_IP"
            ip route del default dev "$WG_DEV" proto static
            ip route del "$SERVER_IP" via "$DEFAULT_GW" dev "$DEFAULT_DEV" proto static
            echo "VPN disconnected"
          }

          trap disconnect EXIT
          connect

          echo "press enter to disconnect"
          read -r

          # triggers the trap to disconnect on exiting
        '';
      })
    ];

    # add domains in /etc/hosts
    networking.extraHosts = concatStringsSep "\n" (map (p: "10.42.0.${toString p.id} ${p.hostname}.wg") peers);

    # allow all connections on this trusted interface
    networking.firewall.trustedInterfaces = [ "wg0" ];
    
    boot.extraModulePackages = optional (versionOlder outside-config.boot.kernelPackages.kernel.version "5.6") outside-config.boot.kernelPackages.wireguard;

    # boot.kernel.sysctl."net.ipv4.conf.wg0.forwarding" = mkIf (my_conf.forwardToAll or false) 1; # already done in systemd-network config

    # open port in firewall if we expose an endPoint
    networking.firewall.allowedUDPPorts = mkIf (my_conf ? endPoint.port) [ my_conf.endPoint.port ];

    # setup private key
    sops.secrets."wg-private-key" = {
      sopsFile = ../../secrets/${my_hostname}.yaml;
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
            PrivateKeyFile = outside-config.sops.secrets.wg-private-key.path;
            ListenPort = mkIf (my_conf ? endPoint.port) my_conf.endPoint.port; # if we are an endPoint
          };

          wireguardPeers =
            map (e: {
              wireguardPeerConfig = {
                PublicKey = e.publicKey;
                AllowedIPs = if (e.forwardToAll or false) then [ "10.42.0.0/16" ] else [ "10.42.0.${toString e.id}/32" "10.42.${toString e.id}.0/24" ];
                Endpoint = mkIf (e ? endPoint.host) "${e.endPoint.host}:${toString e.endPoint.port}";
                PersistentKeepalive = mkIf (! my_conf ? endPoint.host) 25; # to keep NAT connections open if I'm not an endPoint
              };
            }) (builtins.filter (e: e.hostname != my_hostname && (my_conf ? endPoint || e ? endPoint)) peers) # filter peers that are not myself and where one of us is not an endPoint
          ;
        };
      };
      networks = {
        "40-wg0" = {
          matchConfig.Name = "wg0";
          networkConfig = {
            Address = "10.42.0.${toString my_conf.id}/24"; # dont set /16 here because then IPMasquerade would be enabled for all those addresses, i.e. including those on the 10.42.X.0/24 networks.
            IPForward = mkIf (my_conf.forwardToAll or false) "ipv4";
            IPMasquerade = mkIf (my_conf.natToInternet or false) "ipv4";
          };
          linkConfig = {
            "ActivationPolicy" = "up";
            "RequiredForOnline" = "no";
          };
          routes = [{
            routeConfig = {
              Destination = "10.42.0.0/16";
              Source = "10.42.0.${toString my_conf.id}";
            };
          }];
        };
      };
    };

  };
}

