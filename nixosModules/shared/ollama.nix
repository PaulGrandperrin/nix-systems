{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.paulg.ollama;
in {
  options.paulg.ollama = {
    enable = mkEnableOption "ollama";
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = "vulkan";
    };

    services.nextjs-ollama-llm-ui = {
      enable = true;
      hostname = "${config.networking.hostName}.wg";
    };
  };
}


