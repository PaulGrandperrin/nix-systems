{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #<nixpkgs/nixos/modules/profiles/hardened.nix>
      ./common.nix
    ];

  networking.hostId="51079489";

  system.stateVersion = "21.05"; # Did you read the comment?
  
  networking.hostName = "nixos-nas";

  services.resolved.enable = true;
 
  networking.useNetworkd = true;
  networking.useDHCP = false;
 
  systemd.targets.machines.enable = true;

  networking.interfaces.enp3s0.useDHCP = true;
  
  networking.bridges.br0.interfaces = [];
  networking.interfaces.br0.ipv4.addresses = [{ address = "10.0.0.1"; prefixLength = 24; }];
  #boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "br0" ];
  networking.nat.externalInterface = "enp3s0";

}

