{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    ../shared/containers/web.nix
    ../shared/net.nix
    ../shared/web.nix # for home-assistant forward proxy
    ../shared/wireguard.nix
    ../shared/wg-mounts.nix
    ../shared/auto-upgrade.nix
    ../shared/headless.nix
    ../shared/yuzu.nix
  ];

  home-manager.users = let 
    homeModule = {
      imports = [
        ../../homeModules/shared/core.nix
        ../../homeModules/shared/cmdline-extra.nix
      ];
    };
  in {
    root  = homeModule;
    paulg = homeModule;
  };

  fileSystems."/" = {
    device = "system/nixos";
    fsType = "zfs";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/nix" = {
    device = "system/nixos/nix";
    fsType = "zfs";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F6D1-7CDB";
    fsType = "vfat";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/home" = {
    device = "system/nixos/home";
    fsType = "zfs";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  swapDevices = [ ];


  networking.hostId = "ea026662"; # head -c 8 /etc/machine-id
  networking.hostName = "nixos-oci";
  networking.interfaces.eth0.useDHCP = true;

  boot.kernelParams = [ "net.ifnames=0" ]; # so that network is always eth0

  sops.secrets."yuzu-multiplayer" = {
    restartUnits = [ "yuzu-multiplayer.service" ];
  };

  services.yuzu = {
    enable = true;
    package = pkgs.my-yuzu;
    openFirewall = true;
    secretsFile = config.sops.secrets."yuzu-multiplayer".path;
    settings = {
      roomName = "A la Bonne Auberge de Paris";
      preferredGame = "Candy Crush";
    };
  };

  services.net = {
    enable = true;
    mainInt = "eth0";
  }; 

  services.my-wg = {
    enable = true;
  };

  boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless

  environment.systemPackages = with pkgs; [
  ];

  services.nginx.virtualHosts = {
    "phil.grandperrin.fr" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
          proxyPass = "http://10.42.0.2:8123/";
          proxyWebsockets = true;
      };
    };
    "paulg.fr" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
          proxyPass = "http://10.42.0.7:10080/";
          proxyWebsockets = true;
      };
    };
    "louis.grandperrin.fr" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        proxy_redirect off;
      '';
      locations."/" = {
          proxyPass = "http://10.42.0.7:10080/";
          proxyWebsockets = true;
          extraConfig = ''
            #proxy_set_header Host $host:$server_port;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
      };
    };
  };
}

