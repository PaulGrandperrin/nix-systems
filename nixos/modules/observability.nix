{ config, pkgs, system, inputs, ... }:
let
  pkgs-unstable = inputs.nixos-unstable.legacyPackages.${system};
in
{

  services = {
    prometheus = {
      enable = true;
      package = pkgs-unstable.prometheus;

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
        };
      };

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [{
            targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
          }];
        }
        {
          job_name = "loki";
          static_configs = [{
            targets = [ "localhost:${toString config.services.loki.configuration.server.http_listen_port}" ];
          }];
        }
      ];
    };

    promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };
        clients = [
          {
            url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
          }
        ];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = "${config.networking.hostName}";
              };
            };
            relabel_configs = [
              {
                source_labels = ["__journal__systemd_unit"];
                target_label = "unit";
              }
            ];
          }
        ];
      };
    };

    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_port = 3100;
        };
        ingester = {
          lifecycler = {
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
            final_sleep = "0s";
          };
        };
        schema_config = {
          configs = [
            {
              #from = "2020-05-15";
              store = "boltdb";
              object_store = "filesystem";
              schema = "v11";
              index = {
                prefix = "index_";
                period = "168h";
              };
            }
          ];
        };
        storage_config = {
          boltdb.directory = "/var/lib/loki/index";
          filesystem.directory = "/var/lib/loki/chunks";
        };
        limits_config = {
          enforce_metric_name = false;
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };
      };
    };

    grafana = {
      enable = true;
      addr = "0.0.0.0";
      package = pkgs-unstable.grafana;

      smtp = {
        enable = true;
      };

      provision = {
        enable = false;
        datasources = [
          {
            #uid = "metrics"; # in 22.11
            name = "Metrics";
            type = "prometheus";
            url = "http://localhost:${toString config.services.prometheus.port}";
            isDefault = true;
          }
          {
            #uid = "logs"; # in 22.11
            name = "Logs";
            type = "loki";
            url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
          }
        ];
      };
    };

    #nginx.virtualHosts."observability.cachou.org" = {
    #  addSSL = true;
    #  enableACME = true;
    #  locations."/grafana/" = {
    #      proxyPass = "http://localhost:${toString config.services.grafana.port}";
    #      proxyWebsockets = true;
    #  };
    #};

  };


}


