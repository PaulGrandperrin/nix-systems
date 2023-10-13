{ config, pkgs, lib, inputs, system, ... }: {
  imports = [
    ./hosts/nixos-oci/hardware-configuration.nix
    ./shared/common.nix
    ./containers/web.nix
    ./shared/net.nix
    ./shared/wireguard.nix
    ./shared/auto-upgrade.nix
    ./shared/headless.nix
  ];

  # colmena options
  deployment = {
    allowLocalDeployment = true;
    buildOnTarget = true;
    tags = ["nixos" "server" "headless" "web"];
    targetHost = "${config.networking.hostName}.wg";
  };

  networking.hostId = "ea026662"; # head -c 8 /etc/machine-id
  networking.hostName = "nixos-oci";
  networking.interfaces.eth0.useDHCP = true;

  boot.kernelParams = [ "net.ifnames=0" ]; # so that network is always eth0

  services.net = {
    enable = true;
    mainInt = "eth0";
  }; 

  services.my-wg = {
    enable = true;
  };

  boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless

  services.smartd.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
  ];
}

