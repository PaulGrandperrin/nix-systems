{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.net;
in {
  options.services.net = {
    enable = mkEnableOption "bridged networking";
    mainInt = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    networking.interfaces.${cfg.mainInt}.useDHCP = true; # TODO use networkd
    networking.firewall.allowPing = true;
    networking.enableIPv6 = false; # TODO later? never?

    systemd.network.links."10-wol" = {
      enable = true;
      matchConfig = {
        Type = "ether";
        Driver = "!veth";
        Virtualization = "false";
      };
      linkConfig = {
        WakeOnLan = "magic";

        # we need to copy what was at /run/current-system/systemd/lib/systemd/network/99-default.link because only one file can match at a time
        NamePolicy = "keep kernel database onboard slot path";
        AlternativeNamesPolicy = "database onboard slot path";
        MACAddressPolicy = "persistent";
      };

    };

    networking.useNetworkd = true;
    networking.useDHCP = false; # TODO use networkd

    networking.nameservers = ["9.9.9.11#dns11.quad9.net" "149.112.112.11#dns11.quad9.net" "2620:fe::11#dns11.quad9.net" "2620:fe::fe:11#dns11.quad9.net"]; # Malware blocking, DNSSEC Validation, ECS enabled
    #networking.nameservers = ["9.9.9.9#dns.quad9.net" "149.112.112.112#dns.quad9.net" "2620:fe::fe#dns.quad9.net" "2620:fe::9#dns.quad9.net"]; # Malware Blocking, DNSSEC Validation
    #networking.nameservers = ["9.9.9.10#dns10.quad9.net" "149.112.112.10#dns10.quad9.net" "2620:fe::10#dns10.quad9.net" "2620:fe::fe:10#dns10.quad9.net"]; # No Malware blocking, no DNSSEC validation
    #networking.nameservers = ["1.1.1.1#cloudflare-dns.com" "1.0.0.1#cloudflare-dns.com" "2606:4700:4700::1111#cloudflare-dns.com" "2606:4700:4700::1001#cloudflare-dns.com"];
    #networking.nameservers = ["8.8.8.8#dns.google" "8.8.4.4#dns.google" "2001:4860:4860::8888#dns.google" "2001:4860:4860::8844#dns.google"];

    services.resolved = {
      enable = true;
      dnssec = "false"; # https://github.com/systemd/systemd/issues/10579
      domains = [
        "~."
        "grandperrin.fr"
        "paulg.fr"
      ];
      extraConfig = ''
        FallbackDNS=
        DNSOverTLS=true
        MulticastDNS=true
      '';
    };

    systemd.network.networks."10-proton" = {
      matchConfig = {
        "Name" = "proton*";
        "Driver" = "tun";
      };
      networkConfig = {
        "DNSDefaultRoute" = "no";
      };
    };

    systemd.network.networks."10-container-ve" = { # same as original except 2 lines related to link-local address clashs
      matchConfig = {
        "Name" = "ve-*";
        "Driver" = "veth";
      };
      networkConfig = {
        "Address" = "0.0.0.0/28";
        "LinkLocalAddressing" = "no"; # link-local addresses clash with GCP's
        "DHCPServer" = "yes";
        "IPMasquerade" = "ipv4";
        "LLDP" = "yes";
        "EmitLLDP" = "customer-bridge";
      };
      dhcpServerConfig = {
        "DNS" = "9.9.9.11 149.112.112.11"; # don't use GCP's link-local DNS
      };
    };

  
    systemd.network.networks."40-${cfg.mainInt}" = { # merge in mDNS conf into already existing network file (instead of replacing it)
      matchConfig.Name = cfg.mainInt;
      networkConfig= {
        MulticastDNS = true; # mDNS and DNS-SD 
      };
    };

     networking.firewall.allowedUDPPorts = [
       5353 # mdns
     ];


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
    #  address = ["10.42.0.1/24"];
    #};


    #networking.bridges.br0.interfaces = [  ];
    #networking.interfaces.br0.ipv4.addresses = [{ address = "10.42.0.1"; prefixLength = 24; }];
    #boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  };
}

