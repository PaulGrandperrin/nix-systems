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
    sopsFile = mkOption {
      type = types.path;
    };
  };

  config = mkIf cfg.services.my-wg.enable {

    ## enable NAT
    #networking.nat.enable = true;
    #networking.nat.externalInterface = cfg.mainInt;
    #networking.nat.internalInterfaces = [ "wg0" ];

    environment.systemPackages = [ pkgs.wireguard-tools ];
    boot.extraModulePackages = optional (versionOlder cfg.boot.kernelPackages.kernel.version "5.6") cfg.boot.kernelPackages.wireguard;

    networking.firewall = {
      allowedUDPPorts = [ 51820 ];
    };

    sops.secrets."wg-private-key" = {
      sopsFile = cfg.services.my-wg.sopsFile;
      group = "systemd-network";
      mode = "0640";
      restartUnits = [ "systemd-networkd.service" ]; # FIXME overkill ?
    };

    systemd.network = {
      enable = true;
      netdevs = {
        "10-wg0" = {
          netdevConfig = {
            Name = "wg0";
            Kind = "wireguard";
            MTUBytes = "1300"; # FIXME needed?
          };
          wireguardConfig = { 
            PrivateKeyFile = cfg.sops.secrets.wg-private-key.path;
            ListenPort = 51820;
          };

          wireguardPeers = [
            {
              wireguardPeerConfig = {
                PublicKey = "q716Jlq2QEvISYecCRWY/TrBjxP3t586eV9sz+yUHCM="; # nixos-nas
                AllowedIPs = "0.0.0.0/0";
                Endpoint = "nas.paulg.fr:51820";
              };
            }
            {
              wireguardPeerConfig = {
                PublicKey = "9Y2LfXGKytyWaXHTVxLhXHQHKuI3J+UwjSmf7/Rcnic="; # nixos-macbook
                AllowedIPs = "0.0.0.0/0";
              };
            }
            {
              wireguardPeerConfig = {
                PublicKey = "mKW+Ctr8OfmbRPTjTK7vct93eWUilPBovTHSxaLQQkI="; # nixos-xps
                AllowedIPs = "0.0.0.0/0";
              };
            }
          ];
        };
      };
      #networks = {
      #  # See also man systemd.network
      #  "40-wg0".extraConfig = ''
      #    [Match]
      #    Name=wg0
  
      #    [Network]
      #    DHCP=none
      #    IPv6AcceptRA=false
      #    Gateway=fc00::1
      #    Gateway=10.100.0.1
      #    DNS=fc00::53
      #    NTP=fc00::123
  
      #    # IP addresses the client interface will have
      #    [Address]
      #    Address=fe80::3/64
      #    [Address]
      #    Address=fc00::3/120
      #    [Address]
      #    Address=10.100.0.2/24
      #  '';
      #};
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
    #boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    #networking.nat.enable = true;
    #networking.nat.internalInterfaces = [ "vz-nat" ];
    #networking.nat.externalInterface = "${cfg.mainInt}";
  };
}

