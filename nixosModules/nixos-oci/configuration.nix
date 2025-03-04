{ config, pkgs, lib, inputs, ... }: {
  disabledModules = ["services/databases/foundationdb.nix"];
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    ../shared/zfs.nix
    ../shared/containers/web.nix
    ../shared/net.nix
    ../shared/web.nix # for home-assistant forward proxy
    ../shared/wireguard.nix
    ../shared/wg-mounts.nix
    ../shared/auto-upgrade.nix
    ../shared/headless.nix
    ../shared/yuzu.nix
    ../shared/nspawns.nix
    ../shared/foundationdb.nix
    inputs.amadou_server.nixosModules.amadouServer
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
      "nofail"
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

  fileSystems."/var/lib/machines/minecraft" = {
    device = "system/machines/minecraft";
    fsType = "zfs";
    options = [
      "zfsutil"
      "noatime"
      "nodiratime"
    ];
  };

  nix.settings = {
    cores = 4; # max concurrent tasks during one build
    max-jobs = 2; # max concurrent build job
  };

  swapDevices = [ ];


  networking.hostId = "ea026662"; # head -c 8 /etc/machine-id
  networking.hostName = "nixos-oci";
  networking.interfaces.eth0.useDHCP = true;

  boot.kernelParams = [ "net.ifnames=0" ]; # so that network is always eth0

  sops.secrets."yuzu-multiplayer" = {
    restartUnits = [ "yuzu-multiplayer.service" ];
  };

  virtualisation.my-nspawn = {
    enable = true;
    wan-if = "eth0";
    containers = {
      minecraft = {
        id = 1;
        mac = "be:90:a6:62:66:14";
        ports = [
          "222:22"
          "59627:25565"
        ];
        max-mem = "16G";
        os = "debian";
      };
    };
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = ''
      host all all 10.42.0.0/16  trust # trust VPN
      local all all              trust
      host  all all 127.0.0.1/32 trust
      host  all all ::1/128      trust
    '';
    ensureDatabases = [
      "nar-dedup"
    ];
  };

  services.yuzu = {
    #enable = true; # removed from nixpkgs
    #package = pkgs.my-yuzu;
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

  services.ollama = {
    enable = true;
    package = pkgs.unstable.ollama;
    #acceleration = "cuda";
  };

  services.foundationdb = {
    enable = true;
    openFirewall = true;
    traceFormat = "json";
    package = pkgs.foundationdb-bin.override { version = "7.3.59"; };
    publicAddress = "10.42.0.7";
    listenAddress = "public"; # default
  };

  boot.zfs.requestEncryptionCredentials = false; # don't ask for password when the machine is headless

  environment.systemPackages = with pkgs; [
  ];

  sops.secrets."web-amadou.grandperrin.fr" = {
    sopsFile = ../../secrets/nixos-oci.yaml;
    mode = "0440";
    owner = "nginx";
    group = "nginx";
    restartUnits = [ "nginx.service" ];
  };
  services.nginx.virtualHosts = {
    "phil2.grandperrin.fr" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://10.42.0.2:8123/";
        proxyWebsockets = true;
      };
    };
    "paul.grandperrin.fr" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://10.42.0.7:10080/";
        proxyWebsockets = true;
      };
    };
    "amadou.grandperrin.fr" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        basicAuthFile = config.sops.secrets."web-amadou.grandperrin.fr".path;
        proxyPass = "http://10.42.0.7:10080/";
        proxyWebsockets = true;
      };
    };
    "api.amadou.grandperrin.fr" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        #basicAuthFile = config.sops.secrets."web-amadou.grandperrin.fr".path;
        proxyPass = "http://localhost:8080/";
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

  services.amadouServer.enable = true;
}

