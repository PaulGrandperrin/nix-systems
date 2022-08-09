{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.net;
in {
  options.services.net = {
    enable = mkEnableOption "bridged networking";
    mainInt = mkOption {
      type = types.str;
      default = "eth0";
    };
  };

  config = mkIf cfg.enable {
    networking.interfaces.${cfg.mainInt}.useDHCP = true;
    networking.firewall.allowPing = true;
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
    networking.nat.externalInterface = "${cfg.mainInt}"; # NAT is not enabled here, but if used, it will already be correctly setup
  };
}

