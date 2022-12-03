{ config, pkgs, ... }: {
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  
  services.nginx = {
    enable = true;
  
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
  
      # Enable CSP for your services: to be done per virtualhost
  
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
  
      #add_header Access-Control-Allow-Origin "null" always; # breaks things on mastodon
  
      more_clear_headers Server;
      more_clear_headers X-Powered-By;
  
    '';
  
    clientMaxBodySize = "100m";
   };
  
  }
