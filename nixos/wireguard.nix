{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config;
  server = {
    hostname = "nixos-nas";
    publicKey = "naS+n7Tj8/Oq+svcRqw71ZQrXjC93byT3poFeLB2t3E=";
    ip = "10.0.0.100";
    domain = "nas.paulg.fr";
  };
  clients = {
    "nixos-macmini" = {
      publicKey = "mcM+NQQuwuTlKAMxrxZnyZxHMXa5RHENq1pDAIw49zQ=";
      ip = "10.0.0.1";
    };
    "nixos-gcp" = {
      publicKey = "GCp+nDutIu0Ei+f1j1ZB5Opr50S3DiN/wY4usMC08zM=";
      ip = "10.0.0.2";
    };
    "nixos-xps" = {
      publicKey = "xPs+nrka9e2qA8OmoNFEjLmyVvdb/8HkTBIwpxLNc1s=";
      ip = "10.0.0.3";
    };
    "nixos-macbook" = {
      publicKey = "mcb+N3JPq2qKCpAv9V2wWCFerk36DzLvbMS7ByEuIXc=";
      ip = "10.0.0.4";
    };
    "pixel6pro" = {
      publicKey = "P6p+aJrLSBYFsw5f9q+b9sOgA9HnKh2UWz+uwGjnLEE=";
      ip = "10.0.0.5";
    };
  };
in {
  options.services.my-wg = {
    enable = mkEnableOption "My Wireguard";
    mainInt = mkOption {
      type = types.str;
    };
  };

  config = let
    is_server = cfg.networking.hostName == server.hostname;
  in mkIf cfg.services.my-wg.enable {
    
    # install
    environment.systemPackages = [ pkgs.wireguard-tools ];
    boot.extraModulePackages = optional (versionOlder cfg.boot.kernelPackages.kernel.version "5.6") cfg.boot.kernelPackages.wireguard;

    # boot.kernel.sysctl."net.ipv4.conf.wg0.forwarding" = mkIf is_server 1; # already done in systemd-network config

    # open port in firewall
    networking.firewall.allowedUDPPorts = [ 51820 ];

    ## enable NAT
    #networking.nat.enable = true;
    #networking.nat.externalInterface = cfg.mainInt;
    #networking.nat.internalInterfaces = [ "wg0" ];

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
            ListenPort = 51820;
          };

          wireguardPeers = (if is_server then
            map (e: {
              wireguardPeerConfig = {
                PublicKey = e.publicKey;
                AllowedIPs = "${e.ip}/32";
                #PersistentKeepalive = 25;
              };
            }) (lib.attrValues clients)
          else [
            {
              wireguardPeerConfig = {
                PublicKey = server.publicKey;
                AllowedIPs = "10.0.0.0/24";
                Endpoint = "${server.domain}:51820";
                PersistentKeepalive = 25;
              };
            }
          ]);
        };
      };
      networks = {
        "40-wg0" = {
          matchConfig.Name = "wg0";
          networkConfig = if is_server then {
            Address = "${toString server.ip}/24"; 
            IPForward = "ipv4";
          } else {
            Address = "${toString clients.${cfg.networking.hostName}.ip}/24"; 
          };
        };
      };
    };


    # --------------------

    #networking.firewall.enable =  false;
    
    #systemd.network.networks."40-br0" = { # allows networkd to configure bridge even without a carrier
    #  name = "br0";
    #  networkConfig = {
    #    "ConfigureWithoutCarrier"= "yes";
    #  };
    #};

    #systemd.network.networks."10-zone" = {
    #  name = "vz-nat";
    #  networkConfig = {
    #    "DHCPServer"= "yes";
    #  };
    #  #dhcpServerConfig = {
    #  #  
    #  #};
    #  address = ["10.0.0.1/24"];
    #};


    #networking.bridges.br0.interfaces = [  ];
    #networking.interfaces.br0.ipv4.addresses = [{ address = "10.0.0.1"; prefixLength = 24; }];

    #networking.nat.enable = true;
    #networking.nat.internalInterfaces = [ "vz-nat" ];
    #networking.nat.externalInterface = "${cfg.mainInt}";
  };
}

