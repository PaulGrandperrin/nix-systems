{ config, pkgs, lib, inputs, ... }: {
  imports = [
    #./shared/auto-upgrade.nix # 1G of memory is not enough to evaluate the system's derivation, even with zram...
    ./hosts/gcp/hardware-configuration.nix
    ./shared/google-compute-config.nix
    ./shared/common.nix
    ./shared/net.nix
    ./shared/wireguard.nix
    ./shared/thelounge.nix
    ./shared/headless.nix
  ];

  # colmena options
  deployment = {
    allowLocalDeployment = false;
    buildOnTarget = false;
    tags = ["nixos" "server" "headless" "web"];
    targetHost = "${config.networking.hostName}.wg";
  };

  networking.hostId = "1c734661"; # for ZFS
  networking.hostName = "nixos-gcp";
  networking.interfaces.eth0.useDHCP = true;

  services.net = {
    enable = true;
    mainInt = "eth0";
  }; 

  services.my-wg = {
    enable = true;
  };

  boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless
  
  # useful to build and deploy closures from nixos-nas which a lot beefier than nixos-gcp
  users.users.root.openssh.authorizedKeys.keys = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5s0Fe3Y2kX5bxhipkD/OGePPRew40fElqzgacdavuY" # root@nixos-nas
  ];
  
  services.smartd.enable = lib.mkForce false;
  
  environment.systemPackages = with pkgs; [
    google-cloud-sdk-gce
  ];
}

