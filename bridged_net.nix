{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.bridged_net;
in {
  options.services.bridged_net = {
    enable = mkEnableOption "bridged networking";
    mainInt = mkOption {
      type = types.str;
      default = "eth0";
    };
  };

  config = mkIf cfg.enable {
    networking.interfaces.${cfg.mainInt}.useDHCP = true;
    
    networking.bridges.br0.interfaces = [];
    networking.interfaces.br0.ipv4.addresses = [{ address = "10.0.0.1"; prefixLength = 24; }];
    #boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    networking.nat.enable = true;
    networking.nat.internalInterfaces = [ "br0" ];
    networking.nat.externalInterface = "${cfg.mainInt}";
  };
}

