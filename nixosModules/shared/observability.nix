# We use the Grafana stack, but Uptrace, SigNoz and Jaeger are also interested but not well integrated in NixOS

{ config, pkgs, inputs, ... }:
let
  #pkgs-unstable = inputs.nixos-unstable.legacyPackages.${pkgs.system};
in
{
  #disabledModules = [
  #  "services/monitoring/grafana.nix"
  #  "services/monitoring/grafana-image-renderer.nix"
  #  "services/monitoring/prometheus/default.nix"
  #  "services/logging/promtail.nix"
  #  "services/monitoring/loki.nix"
  #];

  imports = [
    ./web.nix
    #"${inputs.nixos-unstable.outPath}/nixos/modules/services/tracing/tempo.nix"
    #"${inputs.nixos-unstable.outPath}/nixos/modules/services/monitoring/grafana.nix"
    #"${inputs.nixos-unstable.outPath}/nixos/modules/services/monitoring/grafana-image-renderer.nix"
    #"${inputs.nixos-unstable.outPath}/nixos/modules/services/monitoring/prometheus/default.nix"
    #"${inputs.nixos-unstable.outPath}/nixos/modules/services/logging/promtail.nix"
    #"${inputs.nixos-unstable.outPath}/nixos/modules/services/monitoring/loki.nix"
  ];

  #nixpkgs.overlays = [(final: prev: { 
  #  tempo = pkgs-unstable.tempo;
  #  promtail = pkgs-unstable.promtail;
  #  prometheus = pkgs-unstable.prometheus;
  #  grafana-loki = pkgs-unstable.grafana-loki;
  #  grafana = pkgs-unstable.grafana;
  #})]; 

  services = {
    prometheus = {
      enable = true;
      port = 9090; # default

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
        };
        #sql = {
        #  enable = true;
        #  configuration.jobs = {
        #    test = {
        #      
        #    };
        #  };
        #};
        #systemd
        #sql
        #smartctl
        #script
        #nginx
        #nginxlog
        #minio
        #influxdb
        #wireguard
        
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


    tempo = {
      enable = true;
      settings = {
        server = {
          http_listen_port = 3200;
          grpc_listen_port = 9096;
        };

        distributor = {
          receivers = {
            otlp = {
              protocols = {
                http.endpoint = "0.0.0.0:4318"; # default
                grpc.endpoint = "0.0.0.0:4317"; # default
              };
            };
          };
        };

        #ingester = {
        #  trace_idle_period = "1s";  # the length of time after a trace has not received spans to consider it complete and flush it
        #  max_block_bytes = 1000000; # cut the head block when it hits this size or ...
        #  max_block_duration = "5m"; # this much time passes
        #};

        #compactor = {
        #  compaction = {
        #    compaction_window = "1h";              # blocks in this time window will be compacted together
        #    max_block_bytes = 100000000;       # maximum size of compacted blocks
        #    block_retention = "1h";
        #    compacted_block_retention = "10m";
        #  };
        #};

        metrics_generator = {
          registry = {
            external_labels = {
              source = "tempo";
            };
          };
          storage = {
            path = "/var/lib/tempo/generator/wal";
            remote_write = [
              {
                url = "http://localhost:${toString config.services.prometheus.port}/api/v1/write";
                send_exemplars = true;
              }
            ];
          };
        };

        storage = {
          trace = {
            backend = "local";                     # backend configuration to use
            #block = {
            #  bloom_filter_false_positive = 0.05; # bloom filter false positive rate.  lower values create larger filters but fewer false positives
            #  index_downsample_bytes = 1000;     # number of bytes per index record
            #  encoding = "zstd";                   # block encoding/compression.  options: none, gzip, lz4-64k, lz4-256k, lz4-1M, lz4, snappy, zstd, s2
            #};
            wal = {
              path = "/var/lib/tempo/wal";             # where to store the the wal locally
              #encoding = "snappy";                 # wal encoding/compression.  options: none, gzip, lz4-64k, lz4-256k, lz4-1M, lz4, snappy, zstd, s2
            };  
            local = {
              path = "/var/lib/tempo/blocks";
            };
            #pool = {
            #  max_workers = 100;                 # worker pool determines the number of parallel requests to the object store backend
            #  queue_depth = 10000;
            #};
          };
        };

        overrides = {
          metrics_generator_processors = [ "service-graphs" "span-metrics"];
        };
      };
    };

    grafana = {
      enable = true;

      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000; # default
          domain = "observability.cachou.org";
          rootUrl = "https://observability.cachou.org/grafana/";
        };
        smtp.enable = true;
        "auth.anonymous" = {
            enabled = true;
            org_role = "Admin";
        };
        "auth.basic".enabled = false;
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            uid = "metrics";
            name = "Metrics";
            type = "prometheus";
            url = "http://localhost:${toString config.services.prometheus.port}";
            isDefault = true;
          }
          {
            uid = "logs";
            name = "Logs";
            type = "loki";
            url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
          }
          {
            uid = "traces";
            name = "Traces";
            type = "tempo";
            url = "http://localhost:${toString config.services.tempo.settings.server.http_listen_port}";
            jsonData = {
              tracesToLogs.datasourceUid = "logs";
              tracesToMetrics.datasourceUid = "metrics";
              serviceMap.datasourceUid = "metrics";
              nodeGraph.enabled = true;
              lokiSearch.datasourceUid = "logs";
            };
          }
        ];
      };
    };
  };

  sops.secrets."web-observability.cachou.org" = {
    sopsFile = ../../secrets/nixos-nas.yaml;
    mode = "0440";
    owner = "nginx";
    group = "nginx";
    restartUnits = [ "nginx.service" ];
  };

  services.nginx.virtualHosts."observability.cachou.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/grafana/" = {
        basicAuthFile = config.sops.secrets."web-observability.cachou.org".path;
        proxyPass = "http://localhost:${toString config.services.grafana.settings.server.http_port}/";
        proxyWebsockets = true;
        #extraConfig = ''
        #  proxy_set_header Host $host;
        #'';
    };
  };


}


