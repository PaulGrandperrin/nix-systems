{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hosts/nixos-macmini/hardware-configuration.nix
    ./shared/common.nix
    ./shared/net.nix
    ./shared/nspawns.nix
    ./shared/wireguard.nix
    ./shared/auto-upgrade.nix
    ./shared/headless.nix
  ];

  # colmena options
  deployment = {
    allowLocalDeployment = true;
    buildOnTarget = true;
    tags = ["nixos" "server" "headless" "deploy"];
    targetHost = "${config.networking.hostName}.wg";
  };

  networking.hostId="aedc67f9";
  networking.hostName = "nixos-macmini";
  services.net = {
    enable = true;
    mainInt = "enp3s0f0";
  }; 
  powerManagement.cpuFreqGovernor = "schedutil";

  services.my-wg = {
    enable = true;
  };

  services.my-nspawn = {
    enable = true;
    name = "tidb-macmini";
    net-id = 2;
    id = 1;
  };

  boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless


  # broadcom_sta fails to build on linux 5.18: https://github.com/NixOS/nixpkgs/issues/177798
  #boot.kernelPackages = lib.mkForce pkgs.linuxPackages; # use stable kernel where broadcom_sta build
}

