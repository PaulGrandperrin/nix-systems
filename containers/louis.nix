{ config, pkgs, ... }:
{
  networking.firewall.trustedInterfaces =  [ "ve-louis" ];
  containers.louis = {
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
    config = { config, pkgs, ... }: {
      networking.useDHCP = false;
      networking.useNetworkd = true;
      services.resolved.enable = true;
      networking.useHostResolvConf = false; # must be explicitly disabled because in conflict with resolved
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      #systemd.network.networks.eth0.gateway = ["10.0.0.1"];
      #systemd.network.networks.eth0.address = ["10.0.0.2/24"];
      #systemd.network.networks.eth0.name = "eth0";
      #security.acme.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      security.acme.acceptTerms = true;
      security.acme.certs."louis.paulg.fr".email = "paul.grandperrin@gmail.com";
    
    
      #mail
      services.opensmtpd = {
        enable = true;
        setSendmail = true;
        serverConfiguration = ''
          listen on localhost
          table secrets file://etc/nixos/secrets/smtpd
          action "relay" relay host smtp+tls://gmailcreds@smtp.gmail.com:587 auth <secrets> mail-from "paul.grandperrin@gmail.com"
          match for any action "relay"
        '';
      };
    
      ## test wordpress
      #services.httpd.adminAddr = "root@paulg.fr";
      #services.wordpress."louis.paulg.fr" = {
      #  themes = [responsiveTheme];
      #  virtualHost = {
      #    forceSSL = true;
      #    enableACME = true;
      #  }; 
      #};
      #services.wordpress."louis.paulg.fr".package = pkgs.unstable.wordpress;
    
      services.nginx = {
        enable = true;
    
        additionalModules = [ pkgs.nginxModules.brotli ];
    
        # https://observatory.mozilla.org/
        # https://www.ssllabs.com/ssltest/index.html
        # https://securityheaders.com/
        # https://csp-evaluator.withgoogle.com/
        # https://tls.imirhil.fr/https
    
        # Use recommended settings
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
    
        # Only allow PFS-enabled ciphers with AES256
        #sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
    
        commonHttpConfig = ''
          # Add HSTS header with preloading to HTTPS requests.
          # Adding this header to HTTP requests is discouraged
          map $scheme $hsts_header {
              https   "max-age=15768000; includeSubdomains; preload";
          }
          add_header Strict-Transport-Security $hsts_header;
    
          # Enable CSP for your services.
          add_header Content-Security-Policy "default-src self https://louis.paulg.fr; script-src self https://louis.paulg.fr 'unsafe-inline' 'unsafe-eval'; style-src self https: 'unsafe-inline'; img-src data: https:; font-src data: https:;" always;
    
          # Minimize information leaked to other domains
          add_header 'Referrer-Policy' 'strict-origin-when-cross-origin' always;
    
          # Disable embedding as a frame
          add_header X-Frame-Options SAMEORIGIN always;
    
          # Prevent injection of code in other mime types (XSS Attacks)
          add_header X-Content-Type-Options nosniff always;
    
          # Enable XSS protection of the browser.
          # May be unnecessary when CSP is configured properly (see above)
          add_header X-XSS-Protection "1; mode=block" always;
    
          # This might create errors
          proxy_cookie_path / "/; Secure; HttpOnly; SameSite=strict";
          add_header Set-Cookie "Path=/; Secure; HttpOnly; SameSite=strict" always;
    
          add_header Permissions-Policy "camera=(), microphone=(), display-capture=(), geolocation=(), payment=()" always;
    
          add_header Expect-CT "max-age=86400, enforce" always;
    
          add_header Access-Control-Allow-Origin "null" always;
    
          more_clear_headers Server;
          more_clear_headers X-Powered-By;
    
        '';
    
        clientMaxBodySize = "100m";
        virtualHosts."louis.paulg.fr" = {
          enableACME = true;
          forceSSL = true;
          listen = [
            {
              "addr" = "0.0.0.0";
              "port" = 443;
              "ssl" = true;
            }
            {
              "addr" = "0.0.0.0";
              "port" = 80;
            }
          ];
          root = "/var/www/louis.paulg.fr";
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
      services.phpfpm.pools.mypool = {
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
}

