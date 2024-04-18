{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.net;
  finalMainInt = if cfg.bridged then "br0" else cfg.mainInt;
in {
  options.services.net = {
    enable = mkEnableOption "networking";
    mainInt = mkOption {
      type = types.str;
    };
    bridged = mkEnableOption "bridged networking";
    extraBridgesInterfaces = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    networking.interfaces.${finalMainInt}.useDHCP = true;
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
    networking.useDHCP = false;

    #systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false; # I just can't deal with this anymore... I don't even understand WHY!?
    systemd.network.wait-online.enable = false;

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
  

    networking = {
      firewall = {
        enable =  true;
        allowPing = true;
        allowedUDPPorts = [
          5353 # mdns
        ];
      };
      nftables = {
        enable = true;
      };
    };
    
    systemd.network.networks."40-${finalMainInt}" = { # allows networkd to configure bridge even without a carrier
      name = finalMainInt;
      networkConfig = {
        "ConfigureWithoutCarrier"= "yes";
        MulticastDNS = true; # mDNS and DNS-SD 
      };
    };

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


    networking.bridges.br0 = mkIf cfg.bridged { interfaces = [ cfg.mainInt ] ++ cfg.extraBridgesInterfaces;};
    #boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  };
}

