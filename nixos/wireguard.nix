{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config;
in {
  options.services.my-wg = {
    enable = mkEnableOption "My Wireguard";
    mainInt = mkOption {
      type = types.str;
    };
    ip-number = mkOption {
      type = types.ints.u8;
    };
    is-server = mkOption {
      type = types.bool;
    };
  };

  config = mkIf cfg.services.my-wg.enable {
    
    # install
    environment.systemPackages = [ pkgs.wireguard-tools ];
    boot.extraModulePackages = optional (versionOlder cfg.boot.kernelPackages.kernel.version "5.6") cfg.boot.kernelPackages.wireguard;

    # boot.kernel.sysctl."net.ipv4.conf.wg0.forwarding" = mkIf cfg.services.my-wg.is-server 1; # already done in systemd-network config

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

          wireguardPeers = (if cfg.services.my-wg.is-server then [
            {
              wireguardPeerConfig = {
                PublicKey = "9Y2LfXGKytyWaXHTVxLhXHQHKuI3J+UwjSmf7/Rcnic="; # nixos-macbook
                AllowedIPs = "10.0.0.3/32";
                #PersistentKeepalive = 25;
              };
            }
            {
              wireguardPeerConfig = {
                PublicKey = "mKW+Ctr8OfmbRPTjTK7vct93eWUilPBovTHSxaLQQkI="; # nixos-xps
                AllowedIPs = "10.0.0.2/32";
                #PersistentKeepalive = 25;
              };
            }
            {
              wireguardPeerConfig = {
                PublicKey = "V6eHfEsJa+42VKn/1QLgQgtK9Ja/U0o8F11e5Ph0nSU="; # nixos-macmini
                AllowedIPs = "10.0.0.4/32";
                #PersistentKeepalive = 25;
              };
            }
            {
              wireguardPeerConfig = {
                PublicKey = "bHTo1rMQiWGxV1EoCRxkazFB9XSxi6NNmlg25+6kmlk="; # nixos-gcp
                AllowedIPs = "10.0.0.5/32";
                #PersistentKeepalive = 25;
              };
            }
            {
              wireguardPeerConfig = {
                PublicKey = "2ZJnuMeA+vQsB7tXpJT98554xB0J6JSVRqihV35MkCQ="; # pixel6pro
                AllowedIPs = "10.0.0.6/32";
                #PersistentKeepalive = 25;
              };
            }
          ] else [
            {
              wireguardPeerConfig = {
                PublicKey = "q716Jlq2QEvISYecCRWY/TrBjxP3t586eV9sz+yUHCM="; # nixos-nas
                AllowedIPs = "10.0.0.0/24";
                Endpoint = "nas.paulg.fr:51820";
                #PersistentKeepalive = 25;
              };
            }
          ]);
        };
      };
      networks = {
        "40-wg0" = {
          matchConfig.Name = "wg0";
          networkConfig = {
            Address = "10.0.0.${toString cfg.services.my-wg.ip-number}/24"; 
            IPForward = mkIf cfg.services.my-wg.is-server "ipv4";
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

