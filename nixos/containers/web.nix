{ config, pkgs, ... }: {
  imports = [
    ../mail.nix
  ];

  networking.firewall.trustedInterfaces =  [ "ve-web" ];
  containers.web = {
    autoStart = true;
    privateNetwork = true;
    extraFlags = [ "-U" "--no-new-privileges=true" "--network-veth"];
    forwardPorts = [
      {
        containerPort = 80;
        hostPort = 80;
        protocol = "tcp";
      }
      {
        containerPort = 443;
        hostPort = 443;
        protocol = "tcp";
      }
    ];
    #bindMounts = {
    #  "/test" = {
    #    hostPath = "/test";
    #    isReadOnly = true;
    #  };
    #};
    config = let hostConfig = config; in { config, pkgs, ... }: {
      imports = [ ../modules/web.nix ];
      system.stateVersion = "22.05";

      networking.useDHCP = false;
      networking.useNetworkd = true;
      networking.enableIPv6 = hostConfig.networking.enableIPv6;
      services.resolved.enable = true;
      networking.useHostResolvConf = false; # must be explicitly disabled because in conflict with resolved
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      #systemd.network.networks.eth0.gateway = ["10.0.0.1"];
      #systemd.network.networks.eth0.address = ["10.0.0.2/24"];
      #systemd.network.networks.eth0.name = "eth0";
    
      ## test wordpress
      #services.httpd.adminAddr = "paul.grandperrin@gmail.com";
      #services.wordpress."louis.grandperrin.fr" = {
      #  themes = [responsiveTheme];
      #  virtualHost = {
      #    forceSSL = true;
      #    enableACME = true;
      #  }; 
      #};
      #services.wordpress."louis.grandperrin.fr".package = pkgs.unstable.wordpress;
    
      services.nginx = {
        additionalModules = [ pkgs.nginxModules.brotli ];
        virtualHosts."paulg.fr" = {
          enableACME = true;
          forceSSL = true;
          default = true;
          root = "/var/www/paulg.fr";
          locations."/" = {
            index = "index.html";
          };
         };
        virtualHosts."louis.grandperrin.fr" = {
          enableACME = true;
          forceSSL = true;
          #extraConfig = ''
          #  # Enable CSP for your services.
          #  add_header Content-Security-Policy "default-src 'none'; connect-src 'self'; font-src 'self' data: https://*.wp.com https://fonts.gstatic.com; form-action 'self'; frame-src 'self' https://louis.grandperrin.fr https://*.wp.com https://wp-themes.com https://www.youtube.com; img-src 'self' data: https://*.wp.com https://*.w.org https://secure.gravatar.com; script-src 'self' 'unsafe-eval' 'unsafe-inline' https://*.wp.com; style-src 'self' 'unsafe-inline' https://code.jquery.com https://fonts.googleapis.com https://*.wp.com;" always;
          #'';
          root = "/var/www/louis.grandperrin.fr";
          locations."/" = {
            tryFiles = "$uri $uri/ /index.php?$args";
            index = "index.php";
          };
          locations."~ \.php$" = {
            extraConfig = ''
              fastcgi_index index.php;
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:${config.services.phpfpm.pools.mypool.socket};
              fastcgi_intercept_errors on;
              include ${pkgs.nginx}/conf/fastcgi_params;
              include ${pkgs.nginx}/conf/fastcgi.conf;
            '';
           };
         };
    
      };
      services.mysql = {
        enable = true;
        package = pkgs.mariadb;
      };
      services.phpfpm = {
        phpOptions = ''
          extension=${pkgs.phpExtensions.imagick}/lib/php/extensions/imagick.so
        '';
        pools.mypool = {
          user = "nobody";
          phpOptions = ''
            upload_max_filesize = 100M
            post_max_size = 100M
          '';
          settings = {
            pm = "dynamic";
            "listen.owner" = config.services.nginx.user;
            "pm.max_children" = 5;
            "pm.start_servers" = 2;
            "pm.min_spare_servers" = 1;
            "pm.max_spare_servers" = 3;
            "pm.max_requests" = 500;
          };
        };
      };
    };
  };
}

